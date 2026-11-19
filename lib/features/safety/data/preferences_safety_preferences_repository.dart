import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/safety_preferences.dart';
import '../domain/safety_preferences_repository.dart';

class PreferencesSafetyPreferencesRepository
    implements SafetyPreferencesRepository {
  PreferencesSafetyPreferencesRepository(this._preferences);

  static const _key = 'safety.localPreferences.v1';
  final SharedPreferencesAsync _preferences;

  @override
  Future<SafetyPreferences> load() async {
    final raw = await _preferences.getString(_key);
    if (raw == null) return const SafetyPreferences();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const SafetyPreferences();
      final visibilityName = decoded['profileVisibility'];
      return SafetyPreferences(
        profileVisibility: ProfileVisibility.values.firstWhere(
          (value) => value.name == visibilityName,
          orElse: () => ProfileVisibility.onlyMe,
        ),
        showInLeaderboards: decoded['showInLeaderboards'] == true,
        allowChallengeInvites: decoded['allowChallengeInvites'] == true,
      );
    } on FormatException {
      return const SafetyPreferences();
    }
  }

  @override
  Future<void> save(SafetyPreferences value) => _preferences.setString(
    _key,
    jsonEncode({
      'profileVisibility': value.profileVisibility.name,
      'showInLeaderboards': value.showInLeaderboards,
      'allowChallengeInvites': value.allowChallengeInvites,
    }),
  );
}
