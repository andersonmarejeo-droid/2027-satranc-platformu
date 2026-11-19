import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/leaderboard_repository.dart';
import '../domain/competition_score.dart';

class FirebaseLeaderboardRepository implements CommunityStandingsRepository {
  const FirebaseLeaderboardRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;
  @override
  bool get isDemo => false;
  @override
  String? get currentPlayerId => auth.currentUser?.uid;
  @override
  List<RankingEntry> entries(RankingScope scope, {String? id}) => const [];
  @override
  Future<CompetitionStandings> load(
    RankingScope scope,
    String id,
    String period,
  ) async {
    final query = db
        .collection('communityScores')
        .where('published', isEqualTo: true)
        .where('scope', isEqualTo: scope.name)
        .where('communityId', isEqualTo: id)
        .where('period', isEqualTo: period);
    final docs = await query
        .orderBy('points', descending: true)
        .orderBy('uid')
        .limit(101)
        .get(const GetOptions(source: Source.server));
    final players = docs.docs
        .take(100)
        .map((d) => CompetitionScore.fromJson(d.data()))
        .toList();
    CompetitionScore? own;
    int? rank;
    final uid = currentPlayerId;
    if (uid != null) {
      final ownDoc = await db
          .collection('communityScores')
          .doc('${period}_${scope.name}_${id}_$uid')
          .get(const GetOptions(source: Source.server));
      if (ownDoc.exists) {
        own = CompetitionScore.fromJson(ownDoc.data()!);
        final higher = await query
            .where('points', isGreaterThan: own.points)
            .count()
            .get();
        final tied = await query
            .where('points', isEqualTo: own.points)
            .where('uid', isLessThan: uid)
            .count()
            .get();
        rank = (higher.count ?? 0) + (tied.count ?? 0) + 1;
      }
    }
    return CompetitionStandings(players, own, rank, docs.docs.length > 100);
  }
}
