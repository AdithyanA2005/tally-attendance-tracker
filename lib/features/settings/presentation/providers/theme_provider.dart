import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/settings_repository.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return ThemeModeNotifier(settingsRepo);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsRepository _settingsRepository;

  ThemeModeNotifier(this._settingsRepository)
    : super(_settingsRepository.getThemeMode());

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsRepository.setThemeMode(mode);
    state = mode;
  }
}
