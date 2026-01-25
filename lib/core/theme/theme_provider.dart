import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/repositories/settings_repository.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settingsHelper;

  ThemeNotifier(this._settingsHelper) : super(_settingsHelper.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _settingsHelper.setThemeMode(mode);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return ThemeNotifier(settingsRepo);
});
