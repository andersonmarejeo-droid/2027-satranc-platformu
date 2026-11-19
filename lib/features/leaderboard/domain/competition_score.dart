import 'package:flutter/foundation.dart';

import 'leaderboard_repository.dart';

class CompetitionStandings {
  const CompetitionStandings(this.players, this.own, this.rank, this.hasMore);
  final List<CompetitionScore> players;
  final CompetitionScore? own;
  final int? rank;
  final bool hasMore;
}

abstract interface class CommunityStandingsRepository
    implements LeaderboardRepository {
  Future<CompetitionStandings> load(
    RankingScope scope,
    String id,
    String period,
  );
}

class CompetitionScore {
  const CompetitionScore({
    required this.uid,
    required this.alias,
    required this.points,
    required this.games,
    required this.wins,
    required this.draws,
    required this.losses,
  });
  final String uid, alias;
  final int points, games, wins, draws, losses;
  factory CompetitionScore.fromJson(Map<String, dynamic> v) => CompetitionScore(
    uid: v['uid'] as String,
    alias: v['alias'] as String,
    points: v['points'] as int,
    games: v['games'] as int,
    wins: v['wins'] as int,
    draws: v['draws'] as int,
    losses: v['losses'] as int,
  );
}

String competitionWeek(DateTime time) =>
    'w${(time.toUtc().millisecondsSinceEpoch + 3 * 86400000 + 10800000) ~/ 604800000}';
String competitionMonth(DateTime time) {
  final local = time.toUtc().add(const Duration(hours: 3));
  return 'm${local.year * 100 + local.month}';
}

int competitionPoints(String outcome, bool white) => outcome == 'draw'
    ? 1
    : outcome == (white ? 'white' : 'black')
    ? 3
    : 0;

abstract class CompetitionRepository extends ChangeNotifier {
  String? get playerId;
  String? status(String matchId);
  Future<void> record(String matchId);
}
