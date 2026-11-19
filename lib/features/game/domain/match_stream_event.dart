class MatchStreamEvent {
  const MatchStreamEvent({
    required this.type,
    required this.matchId,
    required this.sequence,
    required this.serverTime,
    required this.payload,
  });

  final String type;
  final String matchId;
  final int sequence;
  final DateTime serverTime;
  final Map<String, Object?> payload;
}
