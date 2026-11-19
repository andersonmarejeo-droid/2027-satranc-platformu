import 'package:flutter/foundation.dart';

import '../domain/safety_preferences.dart';
import '../domain/safety_preferences_repository.dart';

class SafetyPreferencesController extends ChangeNotifier {
  SafetyPreferencesController(this.repository);

  final SafetyPreferencesRepository repository;
  SafetyPreferences value = const SafetyPreferences();
  bool isSaving = false;
  String? errorMessage;

  Future<void> load() async {
    value = await repository.load();
    notifyListeners();
  }

  Future<void> update(SafetyPreferences next) async {
    if (isSaving) return;
    isSaving = true;
    errorMessage = null;
    notifyListeners();
    try {
      await repository.save(next);
      value = next;
    } catch (_) {
      errorMessage = 'Tercih kaydedilemedi. Biraz sonra yeniden dene.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
