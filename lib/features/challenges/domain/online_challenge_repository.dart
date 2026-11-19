import '../../game/domain/match_snapshot.dart';
import '../../game/domain/time_control.dart';
import 'challenge_repository.dart';

class OnlineMatchSummary {
  const OnlineMatchSummary({
    required this.id,
    required this.timeControl,
    required this.status,
    required this.playerColor,
    required this.isMyTurn,
    required this.ply,
    required this.updatedAt,
    required this.statusLabel,
  });

  final String id;
  final TimeControl timeControl;
  final MatchStatus status;
  final MatchColor playerColor;
  final bool isMyTurn;
  final int ply;
  final DateTime updatedAt;
  final String statusLabel;
}

abstract interface class OnlineChallengeRepository
    implements ChallengeRepository {
  Future<String> accept(String inviteId);
  Stream<String?> watchMatch(String inviteId);
  Future<List<String>> recentMatches();
  Future<List<OnlineMatchSummary>> recentMatchSummaries();
  Future<void> deleteOnlineData();
}
