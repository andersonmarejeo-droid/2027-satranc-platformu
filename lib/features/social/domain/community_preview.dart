enum SocialSection { friends, schools, groups, tournaments }

enum CommunityIcon { school, classroom, group, lockedGroup }

extension SocialSectionDetails on SocialSection {
  String get label => switch (this) {
    SocialSection.friends => 'Arkadaşlar',
    SocialSection.schools => 'Okullar',
    SocialSection.groups => 'Gruplar',
    SocialSection.tournaments => 'Turnuvalar',
  };

  String get heading => switch (this) {
    SocialSection.friends => 'Arkadaşların',
    SocialSection.schools => 'Okul ve sınıf toplulukları',
    SocialSection.groups => 'Satranç grupları',
    SocialSection.tournaments => 'Turnuva takvimi',
  };

  String get emptyTitle => switch (this) {
    SocialSection.friends => 'Arkadaş listen henüz bağlı değil.',
    SocialSection.schools => 'Okul topluluğu bulunamadı.',
    SocialSection.groups => 'Henüz grup görünmüyor.',
    SocialSection.tournaments => 'Turnuva takvimi henüz hazır değil.',
  };
}

class CommunityPreview {
  const CommunityPreview({
    required this.id,
    required this.section,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
  });

  final String id;
  final SocialSection section;
  final String title;
  final String subtitle;
  final String description;
  final CommunityIcon icon;
}
