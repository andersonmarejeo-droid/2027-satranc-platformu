import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ComfortController extends ChangeNotifier {
  ComfortController(this.preferences);
  final SharedPreferencesAsync preferences;
  bool reducedMotion = false, lightBoard = false;
  Future<void> load() async {
    reducedMotion = await preferences.getBool('comfort.reduceMotion') ?? false;
    lightBoard = await preferences.getBool('comfort.lightBoard') ?? false;
  }

  Future<void> setReducedMotion(bool value) async {
    await preferences.setBool('comfort.reduceMotion', value);
    reducedMotion = value;
    notifyListeners();
  }

  Future<void> setLightBoard(bool value) async {
    await preferences.setBool('comfort.lightBoard', value);
    lightBoard = value;
    notifyListeners();
  }
}
