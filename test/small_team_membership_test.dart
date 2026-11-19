import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_platform/features/groups/domain/small_team_membership_repository.dart';
import 'package:chess_platform/features/profile/data/local_community_membership_repository.dart';
import 'package:chess_platform/features/profile/domain/community_membership.dart';
import 'package:chess_platform/features/profile/presentation/community_membership_controller.dart';

void main() {
  test(
    'full remote team preserves previous selection and persisted membership',
    () async {
      String? stored;
      final repository = LocalCommunityMembershipRepository(
        read: () async => stored,
        write: (value) async => stored = value,
      );
      final controller = CommunityMembershipController(repository);
      addTearDown(controller.dispose);
      final old = CommunityMembership().select(CommunityKind.country, 'tr');
      await controller.save(old);
      final before = stored;
      controller.beforeSave = (_) async =>
          throw const TeamCapacityFailure('group', 'friends');
      await expectLater(
        controller.save(old.select(CommunityKind.group, 'friends')),
        throwsA(isA<TeamCapacityFailure>()),
      );
      expect(controller.value.groupIds, isEmpty);
      expect(stored, before);
      expect(controller.saving, isFalse);
      // A newly available place can be saved without a stuck loading state.
      controller.beforeSave = (_) async {};
      await controller.save(old.select(CommunityKind.group, 'friends'));
      expect(controller.value.groupIds, {'friends'});
      expect(jsonDecode(stored!)['groupIds'], ['friends']);
    },
  );

  test(
    'server reservation finishes before local membership becomes visible',
    () async {
      var reserved = false;
      final controller = CommunityMembershipController(
        LocalCommunityMembershipRepository(
          read: () async => null,
          write: (_) async => expect(reserved, isTrue),
        ),
      );
      addTearDown(controller.dispose);
      controller.beforeSave = (next) async {
        expect(controller.saving, isTrue);
        expect(controller.value.groupIds, isEmpty);
        expect(next.groupIds, {'friends'});
        reserved = true;
      };
      await controller.save(
        CommunityMembership().select(CommunityKind.group, 'friends'),
      );
      expect(controller.value.groupIds, {'friends'});
    },
  );
}
