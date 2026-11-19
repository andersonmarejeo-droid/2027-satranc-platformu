import '../domain/community_preview.dart';

abstract final class DemoCommunityCatalog {
  static const schools = <CommunityPreview>[
    CommunityPreview(
      id: 'sample-school-one',
      section: SocialSection.schools,
      title: 'Örnek Anadolu Lisesi',
      subtitle: 'Okul topluluğu · örnek kayıt',
      description: 'Okul takımı, sınıflar arası maçlar ve öğretmen rehberliğindeki etkinlikler bu alanda listelenir. Bu kart yalnızca tasarım örneğidir; gerçek bir okula veya üyeliğe bağlı değildir.',
      icon: CommunityIcon.school,
    ),
    CommunityPreview(
      id: 'sample-class-one',
      section: SocialSection.schools,
      title: 'Örnek 9/A sınıfı',
      subtitle: 'Sınıf alanı · okul doğrulaması gerekir',
      description: 'Sınıf listeleri ve öğrenci davetleri yalnızca doğrulanmış okul ve öğretmen rolleriyle açılır. Bu örnek sınıfa katılma veya öğrenci bilgisi içermez.',
      icon: CommunityIcon.classroom,
    ),
  ];

  static const groups = <CommunityPreview>[
    CommunityPreview(
      id: 'sample-group-open',
      section: SocialSection.groups,
      title: 'Hafta Sonu Satranç Kulübü',
      subtitle: 'Açık grup tasarım örneği',
      description: 'Grup alanında çalışma planı, dostluk maçları ve moderatör bilgileri bulunur. Üyelik, sohbet ve maç daveti bu sürümde etkin değildir.',
      icon: CommunityIcon.group,
    ),
    CommunityPreview(
      id: 'sample-group-private',
      section: SocialSection.groups,
      title: 'Okul Takımı',
      subtitle: 'Özel grup tasarım örneği',
      description: 'Özel gruplar doğrulanmış davet ve görünürlük izinleriyle çalışmalıdır. Bu kart bir grup oluşturmaz ve herhangi bir kişiyi davet etmez.',
      icon: CommunityIcon.lockedGroup,
    ),
  ];
}
