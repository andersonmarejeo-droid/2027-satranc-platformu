// Flutter Web's browser request adapter. The API boundary keeps browser APIs
// isolated so the rest of the app stays platform-free.
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'api_transport.dart';

ApiTransport createApiTransport() => const WebApiTransport();

class WebApiTransport implements ApiTransport {
  const WebApiTransport();

  @override
  Future<ApiTransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) async {
    final requestHeaders = web.Headers();
    for (final header in headers.entries) {
      requestHeaders.set(header.key, header.value);
    }
    final response = await web.window
        .fetch(
          uri.toString().toJS,
          web.RequestInit(
            method: method,
            headers: requestHeaders,
            body: body?.toJS,
          ),
        )
        .toDart;
    final responseText = await response.text().toDart;
    return ApiTransportResponse(
      statusCode: response.status,
      body: responseText.toDart,
    );
  }

  @override
  void close() {}
}
