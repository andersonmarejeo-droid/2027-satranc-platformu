import 'package:flutter/foundation.dart';

import '../domain/guest_profile.dart';
import '../domain/guest_profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this.repository, {GuestProfile? initialProfile})
    : profile = initialProfile;

  final GuestProfileRepository repository;
  GuestProfile? profile;
  bool isSaving = false;

  Future<void> load() async {
    profile = await repository.loadOrCreate();
    notifyListeners();
  }

  Future<void> saveDisplayName(String value) async {
    final error = GuestProfile.displayNameError(value);
    if (error != null) throw ProfileValidationException(error);
    final current = profile;
    if (current == null) throw StateError('Guest profile is not loaded.');

    isSaving = true;
    notifyListeners();
    try {
      final displayName = value.trim();
      await repository.saveDisplayName(displayName);
      profile = current.copyWith(displayName: displayName);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
