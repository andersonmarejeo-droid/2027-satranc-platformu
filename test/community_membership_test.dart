import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';
import 'package:chess_platform/features/profile/data/local_community_membership_repository.dart';
import 'package:chess_platform/features/profile/presentation/community_membership_controller.dart';
import 'package:chess_platform/features/leaderboard/data/demo_leaderboard_repository.dart';
import 'package:chess_platform/features/leaderboard/domain/leaderboard_repository.dart';

CommunityMembership schoolMembership() => CommunityMembership()
    .select(CommunityKind.country, 'tr')
    .select(CommunityKind.city, 'giresun')
    .select(CommunityKind.school, 'gfl')
    .select(CommunityKind.classroom, 'gfl-9a')
    .select(CommunityKind.group, 'friends');

void main() {
  test(
    'changing a parent clears descendants and preserves independent groups',
    () {
      final original = schoolMembership();
      final city = original.select(CommunityKind.city, 'istanbul');
      expect(city.schoolId, isNull);
      expect(city.classId, isNull);
      expect(city.groupIds, {'friends'});
      final country = original.select(CommunityKind.country, 'de');
      expect(country.cityId, isNull);
      expect(country.schoolId, isNull);
      expect(
        () => original.select(CommunityKind.classroom, 'gl-9a'),
        throwsFormatException,
      );
      expect(
        () => original.select(CommunityKind.school, 'ankara-demo'),
        throwsFormatException,
      );
    },
  );
  test(
    'same-named classes from separate schools never mix player rankings',
    () {
      const repository = DemoLeaderboardRepository();
      final fenClass = repository.entries(RankingScope.classroom, id: 'gfl-9a');
      final otherClass = repository.entries(
        RankingScope.classroom,
        id: 'gl-9a',
      );
      expect(fenClass.map((p) => p.name), ['Deniz K.', 'Arda T.']);
      expect(otherClass.map((p) => p.name), ['Mert Y.']);
      expect(
        repository
            .entries(RankingScope.group, id: 'friends')
            .any((p) => p.cityId == 'ankara'),
        isTrue,
      );
      expect(
        repository
            .entries(RankingScope.country, id: 'de')
            .every((p) => p.countryId == 'de'),
        isTrue,
      );
      expect(repository.entries(RankingScope.school, id: 'missing'), isEmpty);
    },
  );
  test(
    'membership survives reopening and failed writes retain the previous value',
    () async {
      String? stored;
      var fail = false;
      LocalCommunityMembershipRepository repo() =>
          LocalCommunityMembershipRepository(
            read: () async => stored,
            write: (value) async {
              if (fail) throw StateError('disk');
              stored = value;
            },
          );
      final controller = CommunityMembershipController(repo());
      await controller.save(schoolMembership());
      final reopened = CommunityMembershipController(repo());
      await reopened.load();
      expect(
        reopened.value.path,
        'Türkiye › Giresun › Giresun Fen Lisesi › 9-A',
      );
      expect(reopened.value.groupIds, {'friends'});
      fail = true;
      await expectLater(
        controller.save(controller.value.select(CommunityKind.country, 'de')),
        throwsStateError,
      );
      expect(controller.value.classId, 'gfl-9a');
      expect(controller.saving, isFalse);
      controller.dispose();
      reopened.dispose();
    },
  );
  test(
    'cross-school or corrupt persisted memberships fall back safely',
    () async {
      final invalid = schoolMembership().toJson()..['classId'] = 'gl-9a';
      for (final stored in [
        '{bad',
        '[]',
        '{"version":2}',
        jsonEncode(invalid),
      ]) {
        final repository = LocalCommunityMembershipRepository(
          read: () async => stored,
          write: (_) async {},
        );
        expect((await repository.load()).hasCountry, isFalse);
      }
    },
  );
}
