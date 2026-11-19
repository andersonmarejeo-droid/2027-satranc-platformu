import 'api_transport.dart';

ApiTransport createApiTransport() => const _UnsupportedApiTransport();

class _UnsupportedApiTransport implements ApiTransport {
  const _UnsupportedApiTransport();

  @override
  Future<ApiTransportResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    String? body,
  }) => Future.error(UnsupportedError('Bu platformda HTTP taşıması yok.'));

  @override
  void close() {}
}
