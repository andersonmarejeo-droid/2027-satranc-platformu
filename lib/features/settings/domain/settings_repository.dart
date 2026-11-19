abstract interface class SettingsRepository {
  Future<String?> readTheme();
  Future<void> saveTheme(String value);
  Future<String?> readColorTheme();
  Future<void> saveColorTheme(String value);
}
