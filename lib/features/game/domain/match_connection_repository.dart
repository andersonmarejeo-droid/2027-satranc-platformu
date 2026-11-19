class MatchConnection {
  const MatchConnection({required this.connected, this.opponentSeenAt});
  final bool connected;
  final DateTime? opponentSeenAt;
}

abstract interface class MatchConnectionRepository {
  Stream<MatchConnection> watchConnection(String matchId);
}
