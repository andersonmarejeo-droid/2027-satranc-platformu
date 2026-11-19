import 'world_directory_data.dart';

enum CommunityKind { country, city, school, classroom, group }

class CommunityNode {
  const CommunityNode(
    this.id,
    this.name,
    this.kind, {
    this.parentId,
    this.district,
    this.schoolType,
    this.institutionCode,
  });
  final String id, name;
  final CommunityKind kind;
  final String? parentId;
  final String? district, schoolType, institutionCode;
  String get location => [
    if (kind == CommunityKind.school) CommunityDirectory.find(parentId)?.name,
    district,
  ].whereType<String>().join(' · ');
}

/// Indexed offline directory. Classes are scoped to a school, never global.
class CommunityDirectory {
  static final _worldNodes = [
    for (final country in worldCountries)
      CommunityNode(country.id, country.name, CommunityKind.country),
    for (final city in worldCities)
      CommunityNode(
        city.id,
        city.name,
        CommunityKind.city,
        parentId: city.countryId,
      ),
  ];

  static final _demoNodes = [
    ..._worldNodes,
    CommunityNode(
      'gfl',
      'Giresun Fen Lisesi',
      CommunityKind.school,
      parentId: 'giresun',
    ),
    CommunityNode(
      'gl',
      'Giresun Lisesi',
      CommunityKind.school,
      parentId: 'giresun',
    ),
    CommunityNode(
      'istanbul-demo',
      'İstanbul Örnek Okulu',
      CommunityKind.school,
      parentId: 'istanbul',
    ),
    CommunityNode(
      'ankara-demo',
      'Ankara Örnek Okulu',
      CommunityKind.school,
      parentId: 'ankara',
    ),
    CommunityNode(
      'berlin-demo',
      'Berlin Örnek Okulu',
      CommunityKind.school,
      parentId: 'berlin',
    ),
    // --- ULUSLARARASI OKULLAR & SATRANÇ AKADEMİLERİ ---
    // İngiltere (Londra)
    CommunityNode(
      'london-westminster',
      'Westminster School London',
      CommunityKind.school,
      parentId: 'gb-london',
    ),
    CommunityNode(
      'london-chess-academy',
      'London Junior Chess Academy',
      CommunityKind.school,
      parentId: 'gb-london',
    ),
    CommunityNode(
      'london-st-pauls',
      "St Paul's School London",
      CommunityKind.school,
      parentId: 'gb-london',
    ),
    // Amerika Birleşik Devletleri (New York & San Francisco)
    CommunityNode(
      'ny-stuyvesant',
      'Stuyvesant High School',
      CommunityKind.school,
      parentId: 'us-new-york',
    ),
    CommunityNode(
      'ny-trinity',
      'Trinity School NYC',
      CommunityKind.school,
      parentId: 'us-new-york',
    ),
    CommunityNode(
      'ny-chess-academy',
      'New York Masters Chess Academy',
      CommunityKind.school,
      parentId: 'us-new-york',
    ),
    CommunityNode(
      'sf-lowell',
      'Lowell High School',
      CommunityKind.school,
      parentId: 'us-san-francisco',
    ),
    CommunityNode(
      'sf-bay-chess',
      'Bay Area Chess Club',
      CommunityKind.school,
      parentId: 'us-san-francisco',
    ),
    // Almanya (Berlin & Münih)
    CommunityNode(
      'berlin-canisius',
      'Canisius-Kolleg Berlin',
      CommunityKind.school,
      parentId: 'berlin',
    ),
    CommunityNode(
      'berlin-chess-academy',
      'Berliner Schachakademie',
      CommunityKind.school,
      parentId: 'berlin',
    ),
    CommunityNode(
      'munich-max-planck',
      'Max-Planck-Gymnasium München',
      CommunityKind.school,
      parentId: 'de-munich',
    ),
    // Fransa (Paris)
    CommunityNode(
      'paris-louis-le-grand',
      'Lycée Louis-le-Grand Paris',
      CommunityKind.school,
      parentId: 'fr-paris',
    ),
    CommunityNode(
      'paris-chess-club',
      "Club d'Échecs de Paris",
      CommunityKind.school,
      parentId: 'fr-paris',
    ),
    // İspanya (Madrid & Barselona)
    CommunityNode(
      'madrid-chess-academy',
      'Real Club de Ajedrez Madrid',
      CommunityKind.school,
      parentId: 'es-madrid',
    ),
    CommunityNode(
      'barcelona-aula',
      'Aula Escola Europea Barcelona',
      CommunityKind.school,
      parentId: 'es-barcelona',
    ),
    // Birleşik Arap Emirlikleri (Dubai)
    CommunityNode(
      'dubai-chess-club',
      'Dubai Chess & Culture Club',
      CommunityKind.school,
      parentId: 'ae-dubai',
    ),
    CommunityNode(
      'dubai-college',
      'Dubai College',
      CommunityKind.school,
      parentId: 'ae-dubai',
    ),
    // Japonya (Tokyo)
    CommunityNode(
      'tokyo-kaisei',
      'Kaisei Academy Tokyo',
      CommunityKind.school,
      parentId: 'jp-tokyo',
    ),
    CommunityNode(
      'tokyo-chess-academy',
      'Tokyo Junior Chess Club',
      CommunityKind.school,
      parentId: 'jp-tokyo',
    ),
    // Azerbaycan (Bakü)
    CommunityNode(
      'baku-chess-school',
      'Bakı Respublika Şahmat Məktəbi',
      CommunityKind.school,
      parentId: 'az-baku',
    ),
    CommunityNode(
      'baku-oxford',
      'Baku Oxford School',
      CommunityKind.school,
      parentId: 'az-baku',
    ),
    // Rusya (Moskova)
    CommunityNode(
      'moscow-botvinnik',
      'Botvinnik Chess School Moskova',
      CommunityKind.school,
      parentId: 'ru-moscow',
    ),
    CommunityNode(
      'moscow-state-lyceum',
      'Moscow State Lyceum',
      CommunityKind.school,
      parentId: 'ru-moscow',
    ),
    // Hindistan (Chennai & Delhi)
    CommunityNode(
      'chennai-chess-academy',
      'Chennai Chess Academy',
      CommunityKind.school,
      parentId: 'in-chennai',
    ),
    CommunityNode(
      'delhi-public-school',
      'Delhi Public School R.K. Puram',
      CommunityKind.school,
      parentId: 'in-new-delhi',
    ),
    // --- ULUSLARARASI SINIFLAR & TAKIMLAR ---
    CommunityNode('lon-west-a', 'Varsity Chess', CommunityKind.classroom, parentId: 'london-westminster'),
    CommunityNode('lon-west-b', 'Team B', CommunityKind.classroom, parentId: 'london-westminster'),
    CommunityNode('lon-chess-u16', 'U-16 Masters', CommunityKind.classroom, parentId: 'london-chess-academy'),
    CommunityNode('ny-stuy-v', 'Varsity Team', CommunityKind.classroom, parentId: 'ny-stuyvesant'),
    CommunityNode('ny-chess-gm', 'Grandmaster Track', CommunityKind.classroom, parentId: 'ny-chess-academy'),
    CommunityNode('ber-acad-m', 'Meistergruppe', CommunityKind.classroom, parentId: 'berlin-chess-academy'),
    CommunityNode('par-chess-e', 'Équipe Élite', CommunityKind.classroom, parentId: 'paris-chess-club'),
    CommunityNode('mad-chess-j', 'Equipo Juvenil', CommunityKind.classroom, parentId: 'madrid-chess-academy'),
    CommunityNode('dub-chess-el', 'Elite Chess Squad', CommunityKind.classroom, parentId: 'dubai-chess-club'),
    CommunityNode('tok-chess-y', 'Youth Division', CommunityKind.classroom, parentId: 'tokyo-chess-academy'),
    CommunityNode('bak-chess-u', 'Usta Qrupu', CommunityKind.classroom, parentId: 'baku-chess-school'),
    CommunityNode('che-chess-p', 'Junior Prodigies', CommunityKind.classroom, parentId: 'chennai-chess-academy'),
    CommunityNode('gfl-9a', '9-A', CommunityKind.classroom, parentId: 'gfl'),
    CommunityNode('gfl-9b', '9-B', CommunityKind.classroom, parentId: 'gfl'),
    CommunityNode('gfl-10a', '10-A', CommunityKind.classroom, parentId: 'gfl'),
    CommunityNode('gl-9a', '9-A', CommunityKind.classroom, parentId: 'gl'),
    CommunityNode('gl-10b', '10-B', CommunityKind.classroom, parentId: 'gl'),
    CommunityNode(
      'istanbul-9a',
      '9-A',
      CommunityKind.classroom,
      parentId: 'istanbul-demo',
    ),
    CommunityNode(
      'istanbul-10a',
      '10-A',
      CommunityKind.classroom,
      parentId: 'istanbul-demo',
    ),
    CommunityNode(
      'ankara-9a',
      '9-A',
      CommunityKind.classroom,
      parentId: 'ankara-demo',
    ),
    CommunityNode(
      'berlin-9a',
      '9-A',
      CommunityKind.classroom,
      parentId: 'berlin-demo',
    ),
    CommunityNode('friends', 'Arkadaş Masası', CommunityKind.group),
    CommunityNode('junior', 'Küçük Ustalar', CommunityKind.group),
    CommunityNode('weekend', 'Hafta Sonu Satranç', CommunityKind.group),
  ];
  static List<CommunityNode> _nodes = _demoNodes;
  static Map<String, CommunityNode> _byId = {
    for (final n in _demoNodes) n.id: n,
  };
  static final _declaredClasses = <String, CommunityNode>{};
  static Map<String, List<CommunityNode>> _children = _indexChildren(_nodes);
  static List<CommunityNode> get nodes => _nodes;
  static bool get hasSchoolCatalog => capturedAt != null;
  static String? capturedAt;
  static String? privateSourceDate;
  static int schoolCount = 0;
  static int privateSchoolCount = 0;

  static Map<String, List<CommunityNode>> _indexChildren(
    List<CommunityNode> nodes,
  ) {
    final result = <String, List<CommunityNode>>{};
    for (final node in nodes) {
      (result['${node.kind.name}/${node.parentId}'] ??= []).add(node);
    }
    return result;
  }

  static void installSchoolCatalog(
    List<CommunityNode> catalogue,
    String date, {
    String? privateDate,
  }) {
    final catalogueIds = catalogue.map((n) => n.id).toSet();
    if (catalogueIds.length != catalogue.length) {
      throw const FormatException('Duplicate school catalogue ID');
    }
    final next = <CommunityNode>[
      for (final node in _demoNodes)
        if (!catalogueIds.contains(node.id) &&
            !(node.kind == CommunityKind.school && node.id.endsWith('-demo')))
          node,
      ...catalogue,
    ];
    final index = {for (final node in next) node.id: node};
    for (final node in catalogue) {
      final expected = node.kind == CommunityKind.city
          ? CommunityKind.country
          : CommunityKind.city;
      if (index[node.parentId]?.kind != expected) {
        throw const FormatException('Invalid school catalogue hierarchy');
      }
    }
    // Old saved example-school selections remain readable, but aren't offered
    // as real schools in the new catalogue.
    for (final node in _demoNodes) {
      index.putIfAbsent(node.id, () => node);
    }
    _nodes = List.unmodifiable(next);
    _byId = index;
    _children = _indexChildren(next);
    _declaredClasses.clear();
    capturedAt = date;
    privateSourceDate = privateDate;
    schoolCount = catalogue.where((n) => n.kind == CommunityKind.school).length;
    privateSchoolCount = catalogue
        .where((n) => n.id.startsWith('private-'))
        .length;
  }

  static CommunityNode? find(String? id) {
    if (id == null) return null;
    final known = _byId[id] ?? _declaredClasses[id];
    if (known != null) return known;
    final match = RegExp(r'^class:([a-z0-9-]+):([1-9]|1[0-2]):([A-ZÇĞİÖŞÜ])$')
        .firstMatch(id);
    if (match == null || _byId[match[1]]?.kind != CommunityKind.school) {
      return null;
    }
    final node = CommunityNode(
      id,
      '${match[2]}-${match[3]}',
      CommunityKind.classroom,
      parentId: match[1],
    );
    _declaredClasses[id] = node;
    return node;
  }

  static CommunityNode classroomFor(
    String schoolId,
    int grade,
    String section,
  ) {
    final existing = children(
      CommunityKind.classroom,
      schoolId,
    ).where((n) => n.name == '$grade-$section').firstOrNull;
    final result = existing ?? find('class:$schoolId:$grade:$section');
    if (result == null) {
      throw const FormatException('Invalid declared classroom');
    }
    return result;
  }

  static List<CommunityNode> children(CommunityKind kind, String? parent) => [
    ...?_children['${kind.name}/$parent'],
    if (kind == CommunityKind.classroom)
      ..._declaredClasses.values.where((n) => n.parentId == parent),
  ];

  /// Schools offered in the user-facing school selector.
  ///
  /// Early-childhood and primary-school entries stay in the source catalogue
  /// for history and licensing, but are intentionally omitted from account
  /// and ranking selection. Names are included in the check because private
  /// school records use labels such as "Okul Öncesi" and "I. Kademe" rather
  /// than the public catalogue's exact school type. District is the first
  /// sort key so a city is easy to scan one district at a time.
  static List<CommunityNode> schoolOptions(String? cityId) =>
      _nodes
          .where(
            (node) =>
                node.kind == CommunityKind.school &&
                (cityId == null || node.parentId == cityId) &&
                !_isEarlyChildhoodOrPrimary(node),
          )
          .toList()
        ..sort((a, b) {
          final district = searchKey(a.district ?? 'İlçesi belirtilmemiş')
              .compareTo(searchKey(b.district ?? 'İlçesi belirtilmemiş'));
          if (district != 0) return district;
          final name = searchKey(a.name).compareTo(searchKey(b.name));
          return name != 0 ? name : a.id.compareTo(b.id);
        });

  static bool _isEarlyChildhoodOrPrimary(CommunityNode node) {
    final text = searchKey('${node.schoolType ?? ''} ${node.name}');
    return text.contains('anaokulu') ||
        text.contains('okul oncesi') ||
        text.contains('ilkokul') ||
        text.contains('ilkogretim') ||
        text.contains('i kademe');
  }

  /// Turkish names also match searches typed without Turkish keyboard letters.
  static String searchKey(String value) => value
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('i\u0307', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  static bool matches(CommunityNode node, String query) {
    final text = searchKey('${node.name} ${node.location}');
    return searchKey(query).split(' ').every(text.contains);
  }

  static bool belongsTo(String? id, String? ancestor) {
    if (id == null || ancestor == null) return false;
    var current = find(id);
    while (current != null) {
      if (current.id == ancestor) return true;
      current = find(current.parentId);
    }
    return false;
  }
}

class CommunityMembership {
  CommunityMembership({
    this.countryId,
    this.cityId,
    this.schoolId,
    this.classId,
    Iterable<String> groupIds = const [],
  }) : groupIds = Set.unmodifiable(groupIds);
  final String? countryId, cityId, schoolId, classId;
  final Set<String> groupIds;
  bool get hasCountry => countryId != null;
  String get path => [countryId, cityId, schoolId, classId]
      .map(CommunityDirectory.find)
      .whereType<CommunityNode>()
      .map((n) => n.name)
      .join(' › ');

  CommunityMembership select(CommunityKind kind, String? id) {
    final node = CommunityDirectory.find(id);
    if (id != null && (node == null || node.kind != kind)) {
      throw const FormatException('Unknown community');
    }
    switch (kind) {
      case CommunityKind.country:
        if (id == countryId) return this;
        return CommunityMembership(countryId: id, groupIds: groupIds);
      case CommunityKind.city:
        if (id != null && node!.parentId != countryId) {
          throw const FormatException('Wrong country');
        }
        if (id == cityId) return this;
        return CommunityMembership(
          countryId: countryId,
          cityId: id,
          groupIds: groupIds,
        );
      case CommunityKind.school:
        if (id != null && node!.parentId != cityId) {
          throw const FormatException('Wrong city');
        }
        if (id == schoolId) return this;
        return CommunityMembership(
          countryId: countryId,
          cityId: cityId,
          schoolId: id,
          groupIds: groupIds,
        );
      case CommunityKind.classroom:
        if (id != null && node!.parentId != schoolId) {
          throw const FormatException('Wrong school');
        }
        return CommunityMembership(
          countryId: countryId,
          cityId: cityId,
          schoolId: schoolId,
          classId: id,
          groupIds: groupIds,
        );
      case CommunityKind.group:
        final next = {...groupIds};
        if (id != null && !next.remove(id)) next.add(id);
        return CommunityMembership(
          countryId: countryId,
          cityId: cityId,
          schoolId: schoolId,
          classId: classId,
          groupIds: next,
        );
    }
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'countryId': countryId,
    'cityId': cityId,
    'schoolId': schoolId,
    'classId': classId,
    'groupIds': groupIds.toList(),
  };
  factory CommunityMembership.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('Unknown membership version');
    }
    var value = CommunityMembership();
    for (final entry in {
      CommunityKind.country: 'countryId',
      CommunityKind.city: 'cityId',
      CommunityKind.school: 'schoolId',
      CommunityKind.classroom: 'classId',
    }.entries) {
      value = value.select(entry.key, json[entry.value] as String?);
    }
    for (final id in (json['groupIds'] as List? ?? []).cast<String>().toSet()) {
      value = value.select(CommunityKind.group, id);
    }
    return value;
  }
}

abstract interface class CommunityMembershipRepository {
  Future<CommunityMembership> load();
  Future<void> save(CommunityMembership membership);
}
