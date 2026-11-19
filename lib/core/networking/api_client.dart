import 'dart:async';
import 'dart:convert';

import 'api_transport.dart';
import 'api_transport_factory.dart';

typedef AccessTokenProvider = Future<String?> Function();

abstract interface class ApiClient {
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String>? queryParameters,
  });

  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? headers,
  });

  Future<Map<String, Object?>> put(String path, Map<String, Object?> body);

  Future<Map<String, Object?>> delete(String path);
}

enum ApiFailureKind {
  configuration,
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  gone,
  rateLimited,
  server,
  http,
  invalidResponse,
}

class ApiFailure implements Exception {
  const ApiFailure(
    this.message, {
    required this.kind,
    this.statusCode,
    this.code,
    this.retryable = false,
  });

  final String message;
  final ApiFailureKind kind;
  final int? statusCode;
  final String? code;
  final bool retryable;

  @override
  String toString() => 'ApiFailure($kind, $statusCode, $code): $message';
}

/// JSON REST client shared by Android, iOS, desktop and web.
///
/// It does not log request bodies or credentials. Authentication remains
/// optional until an auth provider supplies an access token.
class RestApiClient implements ApiClient {
  RestApiClient({
    required String baseUrl,
    ApiTransport? transport,
    this.accessTokenProvider,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _baseUri = _parseBaseUri(baseUrl),
       _transport = transport ?? createPlatformApiTransport();

  final Uri _baseUri;
  final ApiTransport _transport;
  final AccessTokenProvider? accessTokenProvider;
  final Duration requestTimeout;

  @override
  Future<Map<String, Object?>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) => _request('GET', path, queryParameters: queryParameters);

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body, {
    Map<String, String>? headers,
  }) => _request('POST', path, body: body, extraHeaders: headers);

  @override
  Future<Map<String, Object?>> put(String path, Map<String, Object?> body) =>
      _request('PUT', path, body: body);

  @override
  Future<Map<String, Object?>> delete(String path) => _request('DELETE', path);

  void close() => _transport.close();

  Future<Map<String, Object?>> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Map<String, Object?>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = _resolve(path, queryParameters);
    final headers = <String, String>{'Accept': 'application/json'};
    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
      encodedBody = jsonEncode(body);
    }
    for (final entry
        in extraHeaders?.entries ?? const <MapEntry<String, String>>[]) {
      final name = entry.key;
      final value = entry.value;
      if (!RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$").hasMatch(name) ||
          value.contains('\r') ||
          value.contains('\n') ||
          const {
            'accept',
            'authorization',
            'content-type',
          }.contains(name.toLowerCase())) {
        throw const ApiFailure(
          'İstek başlığı geçersiz.',
          kind: ApiFailureKind.configuration,
        );
      }
      headers[name] = value;
    }

    String? token;
    try {
      token = await accessTokenProvider?.call();
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(
        'Oturum doğrulanamadı. Yeniden giriş yapın.',
        kind: ApiFailureKind.unauthorized,
      );
    }
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }

    late final ApiTransportResponse response;
    try {
      response = await _transport
          .send(method: method, uri: uri, headers: headers, body: encodedBody)
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiFailure(
        'Sunucu yanıt vermedi. Bağlantınızı kontrol edip yeniden deneyin.',
        kind: ApiFailureKind.timeout,
        retryable: true,
      );
    } on ApiFailure {
      rethrow;
    } catch (_) {
      throw const ApiFailure(
        'Sunucuya ulaşılamadı. Bağlantınızı kontrol edip yeniden deneyin.',
        kind: ApiFailureKind.network,
        retryable: true,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failureFor(response);
    }
    if (response.body.trim().isEmpty) return const <String, Object?>{};

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return _normalizeMap(decoded);
      throw const FormatException('Expected a JSON object.');
    } on FormatException {
      throw const ApiFailure(
        'Sunucu geçersiz bir yanıt verdi.',
        kind: ApiFailureKind.invalidResponse,
      );
    }
  }

  Uri _resolve(String path, Map<String, String>? queryParameters) {
    final relative = Uri.parse(path);
    if (relative.hasScheme || relative.hasAuthority || relative.path.isEmpty) {
      throw const ApiFailure(
        'API yolu geçersiz.',
        kind: ApiFailureKind.configuration,
      );
    }
    final relativePath = relative.path.replaceFirst(RegExp(r'^/+'), '');
    final uri = _baseUri.resolve(relativePath);
    final query = <String, String>{
      ...relative.queryParameters,
      ...?queryParameters,
    };
    return uri.replace(queryParameters: query.isEmpty ? null : query);
  }

  ApiFailure _failureFor(ApiTransportResponse response) {
    final body = _tryDecodeMap(response.body);
    final nestedError = body?['error'];
    final error = nestedError is Map ? nestedError : body;
    final code = error?['code']?.toString();
    final serverMessage = error?['message']?.toString();
    final status = response.statusCode;
    final kind = switch (status) {
      401 => ApiFailureKind.unauthorized,
      403 => ApiFailureKind.forbidden,
      404 => ApiFailureKind.notFound,
      410 => ApiFailureKind.gone,
      429 => ApiFailureKind.rateLimited,
      >= 500 => ApiFailureKind.server,
      _ => ApiFailureKind.http,
    };
    final fallback = switch (kind) {
      ApiFailureKind.unauthorized => 'Oturum açmanız gerekiyor.',
      ApiFailureKind.forbidden => 'Bu işlem için izniniz yok.',
      ApiFailureKind.notFound => 'İstenen kayıt bulunamadı.',
      ApiFailureKind.gone =>
        'Davetin süresi dolmuş veya daha önce kullanılmış.',
      ApiFailureKind.rateLimited =>
        'Çok sık deneme yaptınız. Biraz sonra yeniden deneyin.',
      ApiFailureKind.server => 'Sunucuda geçici bir sorun oluştu.',
      _ => 'İstek tamamlanamadı.',
    };
    return ApiFailure(
      serverMessage == null || serverMessage.isEmpty ? fallback : serverMessage,
      kind: kind,
      statusCode: status,
      code: code,
      retryable: status == 408 || status == 429 || status >= 500,
    );
  }

  static Uri _parseBaseUri(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const ApiFailure(
        'API_BASE_URL geçerli bir HTTP(S) adresi olmalı.',
        kind: ApiFailureKind.configuration,
      );
    }
    const loopbackHosts = {'localhost', '127.0.0.1', '::1'};
    final host = uri.host.toLowerCase();
    final isLocalDevelopmentHost =
        loopbackHosts.contains(host) || host == '10.0.2.2';
    final allowsLocalHttp =
        !const bool.fromEnvironment('dart.vm.product') &&
        uri.scheme == 'http' &&
        isLocalDevelopmentHost;
    if (uri.scheme != 'https' && !allowsLocalHttp) {
      throw const ApiFailure(
        'Üretim API adresi HTTPS kullanmalı.',
        kind: ApiFailureKind.configuration,
      );
    }
    return uri.replace(
      path: uri.path.endsWith('/') ? uri.path : '${uri.path}/',
    );
  }

  static Map<String, Object?>? _tryDecodeMap(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? _normalizeMap(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  static Map<String, Object?> _normalizeMap(Map<dynamic, dynamic> value) => {
    for (final entry in value.entries)
      entry.key.toString(): _normalizeJson(entry.value),
  };

  static Object? _normalizeJson(Object? value) {
    if (value is Map) return _normalizeMap(value);
    if (value is List) {
      return value.map<Object?>(_normalizeJson).toList(growable: false);
    }
    return value;
  }
}
