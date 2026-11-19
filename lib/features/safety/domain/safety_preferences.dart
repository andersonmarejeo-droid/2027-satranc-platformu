enum ProfileVisibility { onlyMe, friends, everyone }

class SafetyPreferences {
  const SafetyPreferences({
    this.profileVisibility = ProfileVisibility.onlyMe,
    this.showInLeaderboards = false,
    this.allowChallengeInvites = false,
  });

  final ProfileVisibility profileVisibility;
  final bool showInLeaderboards;
  final bool allowChallengeInvites;

  SafetyPreferences copyWith({
    ProfileVisibility? profileVisibility,
    bool? showInLeaderboards,
    bool? allowChallengeInvites,
  }) => SafetyPreferences(
    profileVisibility: profileVisibility ?? this.profileVisibility,
    showInLeaderboards: showInLeaderboards ?? this.showInLeaderboards,
    allowChallengeInvites: allowChallengeInvites ?? this.allowChallengeInvites,
  );
}
