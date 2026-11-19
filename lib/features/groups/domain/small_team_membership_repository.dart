class SmallTeamPolicy {
  static const maxMembers = 20;
  // Bounds the security-rule document lookups in one atomic membership change.
  static const maxChangesPerTransaction = 6;
}

class TeamCapacityFailure implements Exception {
  const TeamCapacityFailure(this.scope, this.communityId);
  final String scope, communityId;
  String get message =>
      '${scope == 'classroom' ? 'Bu sınıf' : 'Bu grup'} ${SmallTeamPolicy.maxMembers} üyeyle dolu. Başka bir takım seç veya bir yer açılmasını bekle.';
}

abstract interface class SmallTeamMembershipRepository {
  Future<void> saveAccount(String uid, Map<String, dynamic> account);
  Future<int> memberCount(String scope, String communityId);
  Future<void> leaveAll(String uid);
}
