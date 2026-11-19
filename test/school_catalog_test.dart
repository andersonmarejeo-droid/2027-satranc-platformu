import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/app/chess_app.dart';
import 'package:chess_platform/features/schools/data/school_catalog_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';
import 'package:chess_platform/features/profile/data/local_community_membership_repository.dart';

import 'widget_test.dart' show services;

void main() {
  setUpAll(() {
    final catalogue = parseSchoolCatalog(
      File('assets/data/schools/turkiye-schools.json').readAsStringSync(),
    );
    final privateCatalogue = parseSchoolCatalog(
      File('assets/data/schools/private-schools.json').readAsStringSync(),
    );
    CommunityDirectory.installSchoolCatalog(
      [...catalogue.nodes, ...privateCatalogue.nodes],
      catalogue.capturedAt,
      privateDate: privateCatalogue.capturedAt,
    );
  });
  test('all 81 provinces have unique coded institutions and legacy schools survive', () {
    final cities = CommunityDirectory.children(CommunityKind.city, 'tr');
    final schools = CommunityDirectory.nodes
        .where((node) => node.kind == CommunityKind.school)
        .toList();
    expect(cities.length, 81);
    expect(schools.length, 67761);
    expect(
      schools.map((n) => n.institutionCode).whereType<String>().toSet().length,
      55117,
    );
    expect(
      cities.every(
        (c) =>
            CommunityDirectory.children(CommunityKind.school, c.id).isNotEmpty,
      ),
      isTrue,
    );
    expect(
      CommunityDirectory.children(CommunityKind.school, 'giresun').length,
      393,
    );
    expect(CommunityDirectory.find('gfl')!.institutionCode, '962238');
    expect(CommunityDirectory.find('gl')!.institutionCode, '150926');
    expect(schools.any((n) => n.name.contains('Örnek Okulu')), isFalse);
    expect(CommunityDirectory.capturedAt, '2026-08-31');
  });
  test('official private-school pages cover all provinces without inventing institution codes', () {
    final json = jsonDecode(
      File('assets/data/schools/private-schools.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    expect((json['source']['pages'] as List).length, 81);
    expect(CommunityDirectory.privateSchoolCount, 12619);
    final schools = CommunityDirectory.children(
      CommunityKind.school,
      'giresun',
    ).where((n) => n.id.startsWith('private-')).toList();
    expect(schools.length, 19);
    expect(schools.every((n) => n.institutionCode == null), isTrue);
    final selected = CommunityMembership()
        .select(CommunityKind.country, 'tr')
        .select(CommunityKind.city, 'giresun')
        .select(CommunityKind.school, schools.first.id)
        .select(
          CommunityKind.classroom,
          CommunityDirectory.classroomFor(schools.first.id, 9, 'A').id,
        );
    expect(
      CommunityMembership.fromJson(selected.toJson()).classId,
      selected.classId,
    );
    expect(selected.path, contains(schools.first.name));
  });
  test('Turkish school and district search also accepts an ASCII keyboard', () {
    expect(CommunityDirectory.searchKey('İSTANBUL'), 'istanbul');
    final giresun = CommunityDirectory.children(
      CommunityKind.school,
      'giresun',
    );
    expect(
      giresun
          .where((n) => CommunityDirectory.matches(n, 'giresun fen'))
          .map((n) => n.id),
      contains('gfl'),
    );
    expect(
      giresun
          .where((n) => CommunityDirectory.matches(n, 'gorele'))
          .every((n) => n.district == 'Görele'),
      isTrue,
    );
    expect(
      giresun.where((n) => CommunityDirectory.matches(n, 'gorele')),
      isNotEmpty,
    );
  });
  test('school picker options group by district and hide preschool and primary schools', () {
    final schools = CommunityDirectory.schoolOptions('giresun');
    expect(schools, isNotEmpty);
    expect(
      schools.every((school) {
        final text = CommunityDirectory.searchKey(
          '${school.schoolType ?? ''} ${school.name}',
        );
        return !text.contains('anaokulu') &&
            !text.contains('okul oncesi') &&
            !text.contains('ilkokul') &&
            !text.contains('ilkogretim') &&
            !text.contains('i kademe');
      }),
      isTrue,
    );
    final districts = schools
        .map((school) => school.district ?? 'İlçesi belirtilmemiş')
        .toList();
    expect(
      List.generate(
        districts.length - 1,
        (index) =>
            CommunityDirectory.searchKey(districts[index])
                .compareTo(CommunityDirectory.searchKey(districts[index + 1])),
      ).every((comparison) => comparison <= 0),
      isTrue,
    );
    for (var index = 1; index < schools.length; index++) {
      if (schools[index - 1].district == schools[index].district) {
        expect(
          CommunityDirectory.searchKey(schools[index - 1].name)
              .compareTo(CommunityDirectory.searchKey(schools[index].name)),
          lessThanOrEqualTo(0),
        );
      }
    }
  });
  test('declared classes persist offline and cannot cross schools with the same class name', () async {
    final schools = CommunityDirectory.children(CommunityKind.school, 'tr-01');
    final first = CommunityDirectory.classroomFor(schools[0].id, 9, 'A');
    final second = CommunityDirectory.classroomFor(schools[1].id, 9, 'A');
    expect(first.id, isNot(second.id));
    final selection = CommunityMembership()
        .select(CommunityKind.country, 'tr')
        .select(CommunityKind.city, 'tr-01')
        .select(CommunityKind.school, schools[0].id)
        .select(CommunityKind.classroom, first.id);
    String? stored;
    final repo = LocalCommunityMembershipRepository(
      read: () async => stored,
      write: (text) async => stored = text,
    );
    await repo.save(selection);
    expect((await repo.load()).classId, first.id);
    expect(
      () => selection.select(CommunityKind.classroom, second.id),
      throwsFormatException,
    );
    expect(CommunityDirectory.find('class:${schools[0].id}:13:A'), isNull);
    expect(CommunityDirectory.find('class:missing:9:A'), isNull);
    final changed = selection.select(CommunityKind.city, 'giresun');
    expect(changed.schoolId, isNull);
    expect(changed.classId, isNull);
    expect(jsonDecode(stored!)['classId'], first.id);
  });
  testWidgets(
    'search to school and class saves on a small phone without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final dependencies = services();
      await tester.pumpWidget(
        ChessApp(services: dependencies, initialLocation: '/profile'),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        final target = find.byKey(ValueKey(key));
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('edit-membership');
      expect(find.text('Türkiye'), findsWidgets);
      await tap('join-city-tr-null');
      await tester.enterText(
        find.byKey(const ValueKey('community-search')),
        'giresun',
      );
      await tester.pumpAndSettle();
      await tap('community-option-giresun');
      await tester.enterText(
        find.byKey(const ValueKey('community-search')),
        'giresun fen',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('community-option-gfl')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('community-option-gl')), findsNothing);
      await tap('community-option-gfl');
      await tap('classroom-grade');
      await tester.tap(find.text('9. sınıf').last);
      await tester.pumpAndSettle();
      await tap('classroom-section');
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      await tap('classroom-confirm');
      await tap('save-membership');
      expect(dependencies.membership.value.schoolId, 'gfl');
      expect(dependencies.membership.value.classId, 'gfl-9a');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'nationwide school rankings render a bounded list and can find a distant school',
    (tester) async {
      await tester.pumpWidget(
        ChessApp(services: services(), initialLocation: '/leaderboard'),
      );
      await tester.pumpAndSettle();
      final scope = find.byKey(const ValueKey('ranking-school'));
      await tester.ensureVisible(scope);
      await tester.tap(scope);
      await tester.pumpAndSettle();
      expect(find.byType(ListTile).evaluate().length, lessThan(55));
      final search = find.byKey(const ValueKey('ranking-community-search'));
      await tester.ensureVisible(search);
      await tester.enterText(search, 'giresun fen');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('ranking-community-gfl')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
