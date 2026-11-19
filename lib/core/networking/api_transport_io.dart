import 'dart:convert';
import 'dart:io';

import 'api_transport.dart';

ApiTransport createApiTransport() => IoApiTransport();

class IoApiTransport implements ApiTransport {
  IoApiTransport({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  Future<ApiTransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final request = await _client.openUrl(method, uri);
    headers.forEach(request.headers.set);
    if (body != null) request.add(utf8.encode(body));

    final response = await request.close();
    final responseBody = await utf8.decoder.bind(response).join();
    return ApiTransportResponse(
      statusCode: response.statusCode,
      body: responseBody,
    );
  }

  @override
  void close() => _client.close(force: true);
}
