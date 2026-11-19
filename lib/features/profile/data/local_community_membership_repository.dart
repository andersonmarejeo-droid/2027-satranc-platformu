import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/community_membership.dart';

class LocalCommunityMembershipRepository
    implements CommunityMembershipRepository {
  LocalCommunityMembershipRepository({required this.read, required this.write});
  factory LocalCommunityMembershipRepository.preferences(
    SharedPreferencesAsync preferences,
  ) => LocalCommunityMembershipRepository(
    read: () => preferences.getString('profile.community.v1'),
    write: (value) async {
      await preferences.setString('profile.community.v1', value);
    },
  );
  final Future<String?> Function() read;
  final Future<void> Function(String) write;
  @override
  Future<CommunityMembership> load() async {
    final stored = await read();
    if (stored == null) return CommunityMembership();
    try {
      return CommunityMembership.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } on FormatException {
      return CommunityMembership();
    } on TypeError {
      return CommunityMembership();
    }
  }

  @override
  Future<void> save(CommunityMembership membership) async {
    CommunityMembership.fromJson(membership.toJson());
    await write(jsonEncode(membership.toJson()));
  }
}
