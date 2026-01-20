import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:tally/core/data/local_storage_service.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import 'package:tally/core/data/models/semester_model.dart';

/// Service handling data import/export functionality.
///
/// Supports generating a JSON backup of all app data (Subjects, Sessions, Timetable)
/// and restoring it. Uses `file_saver` for downloads and `file_picker` for uploads.
class BackupService {
  final LocalStorageService _localStorage;
  BackupService(this._localStorage);

  Future<String> _generateBackupJson() async {
    final subjects = _localStorage.subjectBox.values.toList();
    final sessions = _localStorage.sessionBox.values.toList();
    final timetable = _localStorage.timetableBox.values.toList();
    final semesters = _localStorage.semesterBox.values.toList();

    final data = {
      'meta': {
        'version': 2, // Bumped version
        'timestamp': DateTime.now().toIso8601String(),
        'platform': 'tally',
      },
      'semesters': semesters.map((s) => s.toJson()).toList(),
      'subjects': subjects.map((s) => {...s.toJson()}).toList(),
      'sessions': sessions.map((s) => {...s.toJson()}).toList(),
      'timetable': timetable.map((t) => {...t.toJson()}).toList(),
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
      fileExtension: 'json',
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
    await SharePlus.instance.share(
      ShareParams(text: 'My Attendance Backup', files: [XFile(file.path)]),
    );
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

      // Clear existing data
      await _localStorage.subjectBox.clear();
      await _localStorage.sessionBox.clear();
      await _localStorage.timetableBox.clear();
      await _localStorage.semesterBox.clear();

      final version = data['meta']['version'] as int? ?? 1;

      // 4. Restore Semesters
      String defaultSemesterId = '';
      if (version >= 2 && data['semesters'] != null) {
        final semestersList = data['semesters'] as List;
        for (var s in semestersList) {
          final semester = Semester.fromJson(s);
          await _localStorage.semesterBox.put(semester.id, semester);
          if (semester.isActive) defaultSemesterId = semester.id;
        }
      }

      // If no active semester found or V1, create a default one
      if (defaultSemesterId.isEmpty) {
        final semester = Semester(
          id: 'default_semester',
          name: 'Imported Semester',
          startDate: version == 1 && data['settings'] != null
              ? DateTime.parse(data['settings']['semesterStartDate'])
              : DateTime.now(),
          isActive: true,
        );
        await _localStorage.semesterBox.put(semester.id, semester);
        defaultSemesterId = semester.id;
      }

      // 5. Restore Subjects
      final subjectsList = data['subjects'] as List;
      for (var s in subjectsList) {
        final subject = Subject(
          id: s['id'],
          semesterId: s['semester_id'] ?? defaultSemesterId,
          name: s['name'],
          minimumAttendancePercentage:
              (s['minimum_attendance_percentage'] ??
                      s['minimumAttendancePercentage'] as num)
                  .toDouble(),
          weeklyHours: s['weekly_hours'] ?? s['weeklyHours'],
          colorTag: s['color_tag'] ?? s['colorTag'],
        );
        await _localStorage.subjectBox.put(subject.id, subject);
      }

      // 6. Restore Sessions
      final sessionsList = data['sessions'] as List;
      for (var s in sessionsList) {
        final session = ClassSession(
          id: s['id'],
          semesterId: s['semester_id'] ?? defaultSemesterId,
          subjectId: s['subjectId'] ?? s['subject_id'],
          date: DateTime.parse(s['date']),
          status: s['status'] is int
              ? AttendanceStatus.values[s['status']]
              : AttendanceStatus.values.firstWhere(
                  (e) => e.name == s['status'],
                ),
          isExtraClass: s['isExtraClass'] ?? s['is_extra_class'] ?? false,
          notes: s['notes'],
          durationMinutes: s['durationMinutes'] ?? s['duration_minutes'] ?? 60,
        );
        await _localStorage.sessionBox.put(session.id, session);
      }

      // 7. Restore Timetable
      final timetableList = data['timetable'] as List;
      for (var t in timetableList) {
        final entry = TimetableEntry(
          id: t['id'],
          semesterId: t['semester_id'] ?? defaultSemesterId,
          subjectId: t['subjectId'] ?? t['subject_id'],
          dayOfWeek: t['dayOfWeek'] ?? t['day_of_week'],
          startTime: t['startTime'] ?? t['start_time'],
          durationMinutes:
              (t['durationMinutes'] ??
                      t['duration_minutes'] ??
                      ((t['durationInHours'] ?? t['duration_hours'] ?? 1.0) *
                          60))
                  .toInt(),
        );
        await _localStorage.timetableBox.put(entry.id, entry);
      }
    } catch (e) {
      debugPrint('Import Error: $e');
      rethrow;
    }
  }
}

// final backupServiceProvider = Provider<BackupService>((ref) {
//   final localStorage = ref.watch(localStorageServiceProvider);
//   return BackupService(localStorage);
// });
