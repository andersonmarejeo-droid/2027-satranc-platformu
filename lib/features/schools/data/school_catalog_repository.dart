import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../profile/domain/community_membership.dart';

class SchoolCatalog {
  const SchoolCatalog(this.nodes, this.capturedAt);
  final List<CommunityNode> nodes;
  final String capturedAt;
}

SchoolCatalog parseSchoolCatalog(String text) {
  final json = jsonDecode(text) as Map<String, dynamic>;
  if (json['version'] != 1) {
    throw const FormatException('Unsupported school catalogue');
  }
  final nodes = <CommunityNode>[
    for (final city in json['cities'] as List? ?? const [])
      CommunityNode(
        city['id'] as String,
        city['name'] as String,
        CommunityKind.city,
        parentId: 'tr',
      ),
    for (final row in json['schools'] as List)
      CommunityNode(
        row[0] as String,
        row[2] as String,
        CommunityKind.school,
        parentId: row[1] as String,
        district: row[3] as String,
        schoolType: row[4] as String,
        institutionCode: row[5] as String?,
      ),
  ];
  return SchoolCatalog(nodes, json['source']['capturedAt'] as String);
}

class SchoolCatalogRepository {
  const SchoolCatalogRepository();
  static bool _licenseRegistered = false;
  Future<void> load({AssetBundle? bundle}) async {
    final text = await (bundle ?? rootBundle).loadString(
      'assets/data/schools/turkiye-schools.json',
    );
    final catalogue = await compute(parseSchoolCatalog, text);
    final privateText = await (bundle ?? rootBundle).loadString(
      'assets/data/schools/private-schools.json',
    );
    final privateCatalogue = await compute(parseSchoolCatalog, privateText);
    CommunityDirectory.installSchoolCatalog(
      [...catalogue.nodes, ...privateCatalogue.nodes],
      catalogue.capturedAt,
      privateDate: privateCatalogue.capturedAt,
    );
    if (!_licenseRegistered) {
      final license = await (bundle ?? rootBundle).loadString(
        'assets/data/schools/LICENSE.txt',
      );
      LicenseRegistry.addLicense(() async* {
        yield LicenseEntryWithLineBreaks([
          'MEB-okul-listesi (cemaldalgali)',
        ], license);
      });
      _licenseRegistered = true;
    }
  }
}
