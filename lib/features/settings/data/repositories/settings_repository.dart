import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsRepository {
  static const String boxName = 'settings_box';
  static const String keySemesterStartDate = 'semester_start_date';
  static const String keyLastUpdated = 'updated_at';
  static const String keyHasPendingSync = 'has_pending_sync';

  static const String keyThemeMode = 'theme_mode';

  final Box _box;

  SettingsRepository(this._box);

  static Future<SettingsRepository> init() async {
    final box = await Hive.openBox(boxName);
    return SettingsRepository(box);
  }

  DateTime getSemesterStartDate() {
    final dateStr = _box.get(keySemesterStartDate) as String?;
    if (dateStr == null) {
      final now = DateTime.now();
      return DateTime(now.year, 1, 1);
    }
    return DateTime.parse(dateStr);
  }

  DateTime getLastUpdated() {
    final dateStr = _box.get(keyLastUpdated) as String?;
    if (dateStr == null) return DateTime(2000);
    return DateTime.parse(dateStr);
  }

  bool hasPendingSync() {
    return _box.get(keyHasPendingSync, defaultValue: false) as bool;
  }

  ThemeMode getThemeMode() {
    final index = _box.get(keyThemeMode) as int?;
    if (index == null) return ThemeMode.system;
    return ThemeMode.values[index];
  }

  Future<void> setSemesterStartDate(DateTime date) async {
    await _box.put(keySemesterStartDate, date.toIso8601String());
    await _markDirty();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put(keyThemeMode, mode.index);
    // Theme is a local preference, no need to sync currently, but if we wanted to sync preferences we could mark dirty.
    // For now, let's keep it local or if we want to sync it, we can add it to user profile.
    // The requirement didn't specify syncing, so local is fine.
  }

  Future<void> _markDirty() async {
    await _box.put(keyLastUpdated, DateTime.now().toIso8601String());
    await _box.put(keyHasPendingSync, true);
  }

  Future<void> markSynced() async {
    await _box.put(keyHasPendingSync, false);
  }

  Future<void> updateFromRemote({required DateTime lastUpdated}) async {
    // We no longer sync semesterStartDate from profiles
    await _box.put(keyLastUpdated, lastUpdated.toIso8601String());
    await _box.put(keyHasPendingSync, false);
  }

  Future<void> clearAllSettings() async {
    await _box.clear();
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError(
    'Initialize settingsRepositoryProvider in main.dart',
  );
});
