abstract interface class MatchSocket {
  Stream<Object?> get messages;
  void sendText(String value);
  Future<void> close();
}

abstract interface class MatchSocketConnector {
  Future<MatchSocket> connect(Uri uri);
}
