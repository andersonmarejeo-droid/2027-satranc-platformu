import 'safety_preferences.dart';

abstract interface class SafetyPreferencesRepository {
  Future<SafetyPreferences> load();
  Future<void> save(SafetyPreferences preferences);
}
