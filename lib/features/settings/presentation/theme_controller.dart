import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/settings_repository.dart';

class ThemeController extends ChangeNotifier {
  ThemeController(this.repository);
  final SettingsRepository repository;
  ThemeMode mode = ThemeMode.light;
  AppColorTheme colorTheme = AppColorTheme.fresh;
  Future<void> load() async {
    final stored = await repository.readTheme();
    mode = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.light,
    );
    final storedColorTheme = await repository.readColorTheme();
    colorTheme = AppColorTheme.values.firstWhere(
      (value) => value.name == storedColorTheme,
      orElse: () => AppColorTheme.fresh,
    );
  }

  Future<void> setMode(ThemeMode value) async {
    await repository.saveTheme(value.name);
    mode = value;
    notifyListeners();
  }

  Future<void> setColorTheme(AppColorTheme value) async {
    await repository.saveColorTheme(value.name);
    colorTheme = value;
    notifyListeners();
  }
}
