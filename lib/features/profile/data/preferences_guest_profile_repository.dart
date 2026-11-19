import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/guest_profile.dart';
import '../domain/guest_profile_repository.dart';

class PreferencesGuestProfileRepository implements GuestProfileRepository {
  PreferencesGuestProfileRepository(this._preferences);

  static const _installIdKey = 'profile.guest.installId';
  static const _displayNameKey = 'profile.guest.displayName';

  final SharedPreferencesAsync _preferences;

  @override
  Future<GuestProfile> loadOrCreate() async {
    final storedId = await _preferences.getString(_installIdKey);
    final installId = storedId == null || storedId.isEmpty
        ? await _createInstallId()
        : storedId;
    final storedName = await _preferences.getString(_displayNameKey);
    final displayName =
        storedName == null || GuestProfile.displayNameError(storedName) != null
        ? 'Misafir oyuncu'
        : storedName.trim();

    await _preferences.setString(_installIdKey, installId);
    if (storedName == null || displayName != storedName) {
      await _preferences.setString(_displayNameKey, displayName);
    }
    return GuestProfile(installId: installId, displayName: displayName);
  }

  @override
  Future<void> saveDisplayName(String displayName) async {
    final error = GuestProfile.displayNameError(displayName);
    if (error != null) throw ProfileValidationException(error);
    await _preferences.setString(_displayNameKey, displayName.trim());
  }

  Future<String> _createInstallId() async {
    final random = Random.secure();
    final id = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await _preferences.setString(_installIdKey, id);
    return id;
  }
}
