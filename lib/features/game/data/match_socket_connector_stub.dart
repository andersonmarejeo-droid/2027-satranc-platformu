import 'match_socket.dart';

MatchSocketConnector createMatchSocketConnector() =>
    const _UnsupportedMatchSocketConnector();

class _UnsupportedMatchSocketConnector implements MatchSocketConnector {
  const _UnsupportedMatchSocketConnector();

  @override
  Future<MatchSocket> connect(Uri uri) =>
      Future<MatchSocket>.error(UnsupportedError('WebSocket is unavailable.'));
}
