import 'match_interactions.dart';
import 'online_match_timing.dart';

enum MatchStatus { active, completed, abandoned }

enum MatchColor { white, black }

enum MatchResult { white, black, draw }

class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.displayName,
    required this.color,
  });

  final String id;
  final String displayName;
  final MatchColor color;
}

class MatchClocks {
  const MatchClocks({
    required this.whiteMilliseconds,
    required this.blackMilliseconds,
    required this.serverTime,
  });

  final int whiteMilliseconds;
  final int blackMilliseconds;
  final DateTime serverTime;
}

/// A validated match view. Firebase reconstructs the position on each client.
class MatchSnapshot {
  const MatchSnapshot({
    required this.id,
    required this.status,
    required this.fen,
    required this.ply,
    required this.whiteToMove,
    required this.players,
    required this.clocks,
    required this.updatedAt,
    this.lastMoveUci,
    this.sanHistory = const [],
    this.result,
    this.timeoutReason,
    this.turnRemainingMilliseconds,
    this.interactions = const MatchInteractions(),
  });

  final String id;
  final MatchStatus status;
  final String fen;
  final int ply;
  final bool whiteToMove;
  final List<MatchPlayer> players;
  final MatchClocks clocks;
  final DateTime updatedAt;
  final String? lastMoveUci;
  final List<String> sanHistory;
  final MatchResult? result;
  final MatchTimeoutReason? timeoutReason;
  final int? turnRemainingMilliseconds;
  final MatchInteractions interactions;

  MatchPlayer player(MatchColor color) =>
      players.firstWhere((player) => player.color == color);
}

class MatchStreamTicket {
  const MatchStreamTicket({required this.value, required this.expiresAt});

  /// Short-lived, single-use credential. Do not log or persist it.
  final String value;
  final DateTime expiresAt;
}
