import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsRepository {
  static const String boxName = 'settings_box';
  static const String keySemesterStartDate = 'semester_start_date';
  // static const String keySemesterName = 'semester_name';

  final Box _box;

  SettingsRepository(this._box);

  static Future<SettingsRepository> init() async {
    final box = await Hive.openBox(boxName);
    return SettingsRepository(box);
  }

  // Get start date (default to 60 days ago if not set, just to be safe,
  // or maybe default to *today* if fresh install to avoid backlog?)
  // For a fresh install, "today" makes sense.
  DateTime getSemesterStartDate() {
    final dateStr = _box.get(keySemesterStartDate) as String?;
    if (dateStr == null) {
      // Default: The beginning of time? No, let's say 30 days ago?
      // Actually, if it's null, the user hasn't set it.
      // Pending logic should probably fallback to a reasonable default
      // or prompt the user.
      // Let's return a date far in the past OR null and handle it.
      // But for simplicity, let's default to 1 Jan of current year?
      final now = DateTime.now();
      return DateTime(now.year, 1, 1);
    }
    return DateTime.parse(dateStr);
  }

  Future<void> setSemesterStartDate(DateTime date) async {
    await _box.put(keySemesterStartDate, date.toIso8601String());
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
