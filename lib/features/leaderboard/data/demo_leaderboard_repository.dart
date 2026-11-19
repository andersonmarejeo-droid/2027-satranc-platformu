import '../domain/leaderboard_repository.dart';

class DemoLeaderboardRepository implements LeaderboardRepository {
  const DemoLeaderboardRepository();
  @override
  bool get isDemo => true;
  @override
  String? get currentPlayerId => null;
  static const players = [
    RankingEntry(
      'Deniz K.',
      1920,
      42,
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9a',
      groupIds: ['friends'],
    ),
    RankingEntry(
      'Ece A.',
      1845,
      38,
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9b',
      groupIds: ['junior'],
    ),
    RankingEntry(
      'Arda T.',
      1780,
      51,
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-9a',
      groupIds: ['friends', 'weekend'],
    ),
    RankingEntry(
      'Duru S.',
      1724,
      29,
      cityId: 'giresun',
      schoolId: 'gfl',
      classId: 'gfl-10a',
      groupIds: ['junior'],
    ),
    RankingEntry(
      'Mert Y.',
      1680,
      34,
      cityId: 'giresun',
      schoolId: 'gl',
      classId: 'gl-9a',
      groupIds: ['friends'],
    ),
    RankingEntry(
      'Ada D.',
      1610,
      26,
      cityId: 'giresun',
      schoolId: 'gl',
      classId: 'gl-10b',
      groupIds: ['weekend'],
    ),
    RankingEntry(
      'Selin E.',
      1980,
      56,
      cityId: 'istanbul',
      schoolId: 'istanbul-demo',
      classId: 'istanbul-9a',
      groupIds: ['junior'],
    ),
    RankingEntry(
      'Can B.',
      1750,
      41,
      cityId: 'istanbul',
      schoolId: 'istanbul-demo',
      classId: 'istanbul-10a',
      groupIds: ['weekend'],
    ),
    RankingEntry(
      'Asya M.',
      1890,
      46,
      cityId: 'ankara',
      schoolId: 'ankara-demo',
      classId: 'ankara-9a',
      groupIds: ['friends'],
    ),
    RankingEntry(
      'Emir L.',
      1790,
      33,
      countryId: 'de',
      cityId: 'berlin',
      schoolId: 'berlin-demo',
      classId: 'berlin-9a',
      groupIds: ['weekend'],
    ),
  ];
  @override
  List<RankingEntry> entries(RankingScope scope, {String? id}) {
    final selected =
        id ??
        switch (scope) {
          RankingScope.country => 'tr',
          RankingScope.city => 'giresun',
          RankingScope.school => 'gfl',
          RankingScope.classroom => 'gfl-9a',
          RankingScope.group => 'friends',
        };
    return players
        .where(
          (player) => switch (scope) {
            RankingScope.country => player.countryId == selected,
            RankingScope.city => player.cityId == selected,
            RankingScope.school => player.schoolId == selected,
            RankingScope.classroom => player.classId == selected,
            RankingScope.group => player.groupIds.contains(selected),
          },
        )
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }
}
