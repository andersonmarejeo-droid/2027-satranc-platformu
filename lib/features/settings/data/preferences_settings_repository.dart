import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

class PreferencesSettingsRepository implements SettingsRepository {
  PreferencesSettingsRepository(this.preferences);
  final SharedPreferencesAsync preferences;
  @override
  Future<String?> readTheme() => preferences.getString('appearance.theme');
  @override
  Future<void> saveTheme(String value) =>
      preferences.setString('appearance.theme', value);
  @override
  Future<String?> readColorTheme() =>
      preferences.getString('appearance.colorTheme.v1');
  @override
  Future<void> saveColorTheme(String value) =>
      preferences.setString('appearance.colorTheme.v1', value);
}
