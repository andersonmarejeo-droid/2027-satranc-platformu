import 'dart:io';

import 'match_socket.dart';

MatchSocketConnector createMatchSocketConnector() =>
    const _IoMatchSocketConnector();

class _IoMatchSocketConnector implements MatchSocketConnector {
  const _IoMatchSocketConnector();

  @override
  Future<MatchSocket> connect(Uri uri) async =>
      _IoMatchSocket(await WebSocket.connect(uri.toString()));
}

class _IoMatchSocket implements MatchSocket {
  const _IoMatchSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<Object?> get messages => _socket.map<Object?>((message) => message);

  @override
  void sendText(String value) => _socket.add(value);

  @override
  Future<void> close() async {
    await _socket.close();
  }
}
