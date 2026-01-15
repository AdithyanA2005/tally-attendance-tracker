import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../features/calendar/data/repositories/attendance_repository.dart';
import '../../features/calendar/data/models/subject_model.dart';
import '../../features/calendar/data/models/session_model.dart';
import '../../features/settings/data/models/timetable_entry_model.dart';
import '../../features/settings/data/repositories/settings_repository.dart';
import '../data/local_storage_service.dart';

class BackupService {
  final LocalStorageService _localStorage;
  final SettingsRepository _settingsRepo;

  BackupService(this._localStorage, this._settingsRepo);

  Future<String> _generateBackupJson() async {
    // 1. Gather all data
    final subjects = _localStorage.subjectBox.values.toList();
    final sessions = _localStorage.sessionBox.values.toList();
    final timetable = _localStorage.timetableBox.values.toList();
    final semesterStartDate = _settingsRepo.getSemesterStartDate();

    // 2. Serialize
    final data = {
      'meta': {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'attendance_intelligence',
      },
      'settings': {'semesterStartDate': semesterStartDate.toIso8601String()},
      'subjects': subjects
          .map(
            (s) => {
              'id': s.id,
              'name': s.name,
              'minimumAttendancePercentage': s.minimumAttendancePercentage,
              'weeklyHours': s.weeklyHours,
              'colorTag': s.colorTag,
            },
          )
          .toList(),
      'sessions': sessions
          .map(
            (s) => {
              'id': s.id,
              'subjectId': s.subjectId,
              'date': s.date.toIso8601String(),
              'status': s.status.index,
              'isExtraClass': s.isExtraClass,
              'notes': s.notes,
            },
          )
          .toList(),
      'timetable': timetable
          .map(
            (t) => {
              'id': t.id,
              'subjectId': t.subjectId,
              'dayOfWeek': t.dayOfWeek,
              'startTime': t.startTime,
              'durationInHours': t.durationInHours,
            },
          )
          .toList(),
    };

    return jsonEncode(data);
  }

  Future<void> saveBackupToDevice() async {
    final jsonString = await _generateBackupJson();
    final fileName =
        'attendance_backup_${DateTime.now().millisecondsSinceEpoch}';

    await FileSaver.instance.saveAs(
      name: fileName,
      bytes: Uint8List.fromList(utf8.encode(jsonString)),
      ext: 'json',
      mimeType: MimeType.json,
    );
  }

  Future<void> exportData() async {
    final jsonString = await _generateBackupJson();
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'attendance_backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonString);
    await Share.shareXFiles([XFile(file.path)], text: 'My Attendance Backup');
  }

  Future<void> importData() async {
    // 1. Pick file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final jsonString = await file.readAsString();

    try {
      final data = jsonDecode(jsonString);

      // 2. Validate
      if (data['meta'] == null || data['subjects'] == null) {
        throw Exception('Invalid backup file format');
      }

      // 3. Clear existing data
      await _localStorage.subjectBox.clear();
      await _localStorage.sessionBox.clear();
      await _localStorage.timetableBox.clear();

      // 4. Restore Settings
      final settings = data['settings'];
      if (settings != null && settings['semesterStartDate'] != null) {
        await _settingsRepo.setSemesterStartDate(
          DateTime.parse(settings['semesterStartDate']),
        );
      }

      // 5. Restore Subjects
      final subjectsList = data['subjects'] as List;
      for (var s in subjectsList) {
        final subject = Subject(
          id: s['id'],
          name: s['name'],
          minimumAttendancePercentage: (s['minimumAttendancePercentage'] as num)
              .toDouble(),
          weeklyHours: s['weeklyHours'],
          colorTag: s['colorTag'],
        );
        await _localStorage.subjectBox.put(subject.id, subject);
      }

      // 6. Restore Sessions
      final sessionsList = data['sessions'] as List;
      for (var s in sessionsList) {
        final session = ClassSession(
          id: s['id'],
          subjectId: s['subjectId'],
          date: DateTime.parse(s['date']),
          status: AttendanceStatus.values[s['status']],
          isExtraClass: s['isExtraClass'] ?? false,
          notes: s['notes'],
        );
        await _localStorage.sessionBox.put(session.id, session);
      }

      // 7. Restore Timetable
      final timetableList = data['timetable'] as List;
      for (var t in timetableList) {
        final entry = TimetableEntry(
          id: t['id'],
          subjectId: t['subjectId'],
          dayOfWeek: t['dayOfWeek'],
          startTime: t['startTime'],
          durationInHours: (t['durationInHours'] as num).toDouble(),
        );
        await _localStorage.timetableBox.put(entry.id, entry);
      }
    } catch (e) {
      debugPrint('Import Error: $e');
      rethrow;
    }
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return BackupService(localStorage, settingsRepo);
});
