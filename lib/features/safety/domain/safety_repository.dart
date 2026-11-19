abstract interface class SafetyRepository {
  Future<void> blockPlayer(String playerId);
  Future<void> reportPlayer({
    required String playerId,
    required String reason,
    String? matchId,
  });
}
