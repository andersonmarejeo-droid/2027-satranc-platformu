enum RankingScope { country, city, school, classroom, group }

extension RankingScopeLabel on RankingScope {
  String get label => switch (this) {
    RankingScope.country => 'Ülke',
    RankingScope.city => 'Şehirler',
    RankingScope.school => 'Okullar',
    RankingScope.classroom => 'Sınıflar',
    RankingScope.group => 'Gruplar',
  };
  String get location => switch (this) {
    RankingScope.country => 'Türkiye',
    RankingScope.city => 'Giresun',
    RankingScope.school => 'Giresun Fen Lisesi',
    RankingScope.classroom => '9/A',
    RankingScope.group => 'Arkadaş Masası',
  };
}

class RankingEntry {
  const RankingEntry(
    this.name,
    this.rating,
    this.games, {
    this.playerId,
    this.countryId = 'tr',
    this.cityId,
    this.schoolId,
    this.classId,
    this.groupIds = const [],
  });
  final String name;
  final String? playerId;
  final int rating, games;
  final String countryId;
  final String? cityId, schoolId, classId;
  final List<String> groupIds;
}

abstract interface class LeaderboardRepository {
  bool get isDemo;

  /// The signed-in identity from the ranking source, never a display-name match.
  String? get currentPlayerId;
  List<RankingEntry> entries(RankingScope scope, {String? id});
}
