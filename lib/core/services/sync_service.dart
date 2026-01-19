import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local_storage_service.dart';
import '../data/models/subject_model.dart';
import '../data/models/session_model.dart';
import '../data/models/timetable_entry_model.dart';
import '../data/models/semester_model.dart';
import '../services/supabase_service.dart';
import '../../features/settings/data/repositories/settings_repository.dart';

// part 'sync_service.g.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final SettingsRepository _settings;
  final SupabaseClient _supabase;
  final Ref? _ref; // Optional ref to invalidate providers

  SyncService(this._localStorage, this._settings, this._supabase, [this._ref]);

  static const String _kLastSyncTimeKey = 'last_sync_time';

  Future<String> sync() async {
    // 1. Check Auth
    if (_supabase.auth.currentUser == null) {
      debugPrint('Sync skipped: No user');
      return 'Skipped: Not logged in';
    }

    try {
      debugPrint('Sync Started...');
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTimeStr = prefs.getString(_kLastSyncTimeKey);

      // Schema Versioning Check
      const int currentSchemaVersion = 2; // V2: Multi-Semester Support
      final lastSchemaVersion = prefs.getInt('schema_version') ?? 0;

      if (lastSyncTimeStr == null) {
        // First Run ever
        await _performFirstRunMigration();
        await prefs.setInt('schema_version', currentSchemaVersion);
      } else if (lastSchemaVersion < currentSchemaVersion) {
        // Upgrade detected: Mark everything as dirty to ensure new fields (semester_id) sync
        debugPrint(
          'Schema upgrade detected ($lastSchemaVersion -> $currentSchemaVersion). Forcing full resync.',
        );
        await _performFirstRunMigration(); // Re-use this to mark all dirty
        await prefs.setInt('schema_version', currentSchemaVersion);
      }

      final pushResult = await _pushChanges();

      // We pull changes and check if any table failed
      final (pullResult, hasErrors) = await _pullChanges();

      final now = DateTime.now();

      // ONLY update the sync marker if pulling actually succeeded.
      // Otherwise, we might skip over data that we failed to fetch this time.
      if (!hasErrors) {
        await prefs.setString(_kLastSyncTimeKey, now.toIso8601String());
        debugPrint('Sync marker updated to $now');
      } else {
        debugPrint('Sync marker NOT updated due to pull errors');
      }

      //       if (_ref != null) {
      //         _ref.invalidate(lastSyncTimeProvider);
      //       }

      return 'Success: $pushResult pushed, $pullResult pulled';
    } catch (e, stack) {
      debugPrint('Sync failed: $e');
      debugPrint(stack.toString());
      return 'Failed: ${e.toString().split('\n').first}';
    }
  }

  Future<String> _pushChanges() async {
    int pushed = 0;
    int failed = 0;
    String lastError = '';

    // 0. Get Active/Default Semester ID for backfilling orphans
    // We try to find the one marked active, or fallback to the first one available.
    String? defaultSemesterId;
    try {
      defaultSemesterId = _localStorage.semesterBox.values
          .firstWhere((s) => s.isActive)
          .id;
    } catch (_) {
      if (_localStorage.semesterBox.isNotEmpty) {
        defaultSemesterId = _localStorage.semesterBox.values.first.id;
      }
    }

    // Semesters
    final allSemesters = _localStorage.semesterBox.values;
    debugPrint('MIGRATION: Pushing ${allSemesters.length} semesters...');
    for (var semester in allSemesters) {
      try {
        final json = semester.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('semesters').upsert(json);
        await _localStorage.semesterBox.put(
          semester.id,
          semester.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push semester ${semester.id}: $e');
      }
    }

    // Profile (Settings)
    // Always push profile during migration
    if (_supabase.auth.currentUser != null) {
      try {
        final json = {
          'id': _supabase.auth.currentUser!.id,
          'updated_at': _settings.getLastUpdated().toIso8601String(),
        };
        await _supabase.from('profiles').upsert(json);
        await _settings.markSynced();
        pushed++;
        debugPrint('Pushed profile settings');
      } catch (e) {
        debugPrint('Failed to push profile: $e');
      }
    }

    // Subjects
    final allSubjects = _localStorage.subjectBox.values;
    debugPrint('MIGRATION: Pushing ${allSubjects.length} subjects...');
    for (var subject in allSubjects) {
      // AUTO-FIX: Orphaned Subjects
      if (subject.semesterId.isEmpty && defaultSemesterId != null) {
        debugPrint(
          'Auto-fixing subject ${subject.id} with semester $defaultSemesterId',
        );
        final fixed = subject.copyWith(semesterId: defaultSemesterId);
        await _localStorage.subjectBox.put(fixed.id, fixed);
        subject = fixed;
      }

      try {
        final json = subject.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('subjects').upsert(json);
        await _localStorage.subjectBox.put(
          subject.id,
          subject.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push subject ${subject.id}: $e');
      }
    }

    // Sessions
    final allSessions = _localStorage.sessionBox.values;
    // We push ALL sessions, not just dirty ones (except virtual)
    final sessionsToPush = allSessions.where(
      (e) => !e.id.startsWith('virtual_'),
    );

    debugPrint(
      'MIGRATION: Pushing ${sessionsToPush.length} sessions (Total: ${allSessions.length})...',
    );

    for (var session in sessionsToPush) {
      // AUTO-FIX: Orphaned Sessions
      if (session.semesterId.isEmpty && defaultSemesterId != null) {
        debugPrint(
          'Auto-fixing session ${session.id} with semester $defaultSemesterId',
        );
        final fixed = session.copyWith(semesterId: defaultSemesterId);
        await _localStorage.sessionBox.put(fixed.id, fixed);
        session = fixed;
      }

      try {
        final json = session.toJson();
        // debugPrint('SYNC DEBUG: Pushing Session JSON: $json');

        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('attendance_logs').upsert(json);

        await _localStorage.sessionBox.put(
          session.id,
          session.copyWith(hasPendingSync: false),
        );
        pushed++;
        // debugPrint('SYNC DEBUG: Session ${session.id} pushed successfully.');
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push session ${session.id}: $e');
      }
    }

    // Timetable
    final allEntries = _localStorage.timetableBox.values;
    final entriesToPush = allEntries.where((e) => !e.id.startsWith('virtual_'));
    debugPrint(
      'MIGRATION: Pushing ${entriesToPush.length} timetable entries...',
    );

    for (var entry in entriesToPush) {
      // AUTO-FIX: Orphaned Timetable
      if (entry.semesterId.isEmpty && defaultSemesterId != null) {
        debugPrint(
          'Auto-fixing timetable ${entry.id} with semester $defaultSemesterId',
        );
        final fixed = entry.copyWith(semesterId: defaultSemesterId);
        await _localStorage.timetableBox.put(fixed.id, fixed);
        entry = fixed;
      }

      try {
        final json = entry.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('timetables').upsert(json);

        await _localStorage.timetableBox.put(
          entry.id,
          entry.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push timetable entry ${entry.id}: $e');
      }
    }

    if (failed > 0) {
      return '$pushed (Errors: $failed - ${lastError.split('\n').first})';
    }
    return '$pushed';
  }

  /// Returns a tuple of (ResultMessage, HasErrors)
  Future<(String, bool)> _pullChanges() async {
    int pulled = 0;
    int failed = 0;

    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_kLastSyncTimeKey);
    final lastSyncTime = lastSyncStr != null
        ? DateTime.parse(lastSyncStr)
        : DateTime(2000);

    // Semesters (Pull FIRST)
    try {
      final semestersData = await _supabase
          .from('semesters')
          .select()
          .gt('updated_at', lastSyncTime.toIso8601String());

      for (var json in semestersData) {
        final remoteSemester = Semester.fromJson(json);
        final localSemester = _localStorage.semesterBox.get(remoteSemester.id);

        if (localSemester == null ||
            remoteSemester.lastUpdated.isAfter(localSemester.lastUpdated)) {
          await _localStorage.semesterBox.put(
            remoteSemester.id,
            remoteSemester,
          );
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error pulling semesters: $e');
    }

    // Profile
    try {
      final profileData = await _supabase
          .from('profiles')
          .select()
          .maybeSingle();

      if (profileData != null) {
        final remoteUpdated = DateTime.parse(profileData['updated_at']);
        if (remoteUpdated.isAfter(_settings.getLastUpdated())) {
          await _settings.updateFromRemote(lastUpdated: remoteUpdated);
          pulled++;
          debugPrint('Pulled profile settings');
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error pulling profile: $e');
    }

    // subjects
    try {
      final subjectsData = await _supabase
          .from('subjects')
          .select()
          .gt('updated_at', lastSyncTime.toIso8601String());

      for (var json in subjectsData) {
        final remoteSubject = Subject.fromJson(json);
        final localSubject = _localStorage.subjectBox.get(remoteSubject.id);

        if (localSubject == null ||
            remoteSubject.lastUpdated.isAfter(localSubject.lastUpdated)) {
          await _localStorage.subjectBox.put(remoteSubject.id, remoteSubject);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error pulling subjects: $e');
    }

    // sessions (attendance_logs)
    try {
      final sessionsData = await _supabase
          .from('attendance_logs')
          .select()
          .gt('updated_at', lastSyncTime.toIso8601String());

      for (var json in sessionsData) {
        final remoteSession = ClassSession.fromJson(json);
        final localSession = _localStorage.sessionBox.get(remoteSession.id);

        if (localSession == null ||
            remoteSession.lastUpdated.isAfter(localSession.lastUpdated)) {
          await _localStorage.sessionBox.put(remoteSession.id, remoteSession);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error pulling sessions: $e');
    }

    // timetables
    try {
      final timetableData = await _supabase
          .from('timetables')
          .select()
          .gt('updated_at', lastSyncTime.toIso8601String());

      for (var json in timetableData) {
        final remoteEntry = TimetableEntry.fromJson(json);
        final localEntry = _localStorage.timetableBox.get(remoteEntry.id);

        if (localEntry == null ||
            remoteEntry.lastUpdated.isAfter(localEntry.lastUpdated)) {
          await _localStorage.timetableBox.put(remoteEntry.id, remoteEntry);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error pulling timetable: $e');
    }

    if (failed > 0) return ('$pulled (Failed: $failed)', true);
    return ('$pulled', false);
  }

  Future<void> _performFirstRunMigration() async {
    debugPrint('Marking local data as pending sync');

    // Semesters
    for (var semester in _localStorage.semesterBox.values) {
      await _localStorage.semesterBox.put(
        semester.id,
        semester.copyWith(hasPendingSync: true),
      );
    }

    // Profile
    // Legacy: await _settings.setSemesterStartDate(_settings.getSemesterStartDate());

    for (var subject in _localStorage.subjectBox.values) {
      await _localStorage.subjectBox.put(
        subject.id,
        subject.copyWith(hasPendingSync: true),
      );
    }
    for (var session in _localStorage.sessionBox.values) {
      await _localStorage.sessionBox.put(
        session.id,
        session.copyWith(hasPendingSync: true),
      );
    }
    for (var entry in _localStorage.timetableBox.values) {
      await _localStorage.timetableBox.put(
        entry.id,
        entry.copyWith(hasPendingSync: true),
      );
    }
  }

  /// NEW: Deletes ALL data for the current user from Supabase.
  Future<void> nukeRemoteData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('Nuking remote data for user $userId...');
      // Order matters if there are FK constraints
      await _supabase.from('attendance_logs').delete().eq('user_id', userId);
      await _supabase.from('timetables').delete().eq('user_id', userId);
      await _supabase.from('subjects').delete().eq('user_id', userId);
      await _supabase.from('semesters').delete().eq('user_id', userId);
      await _supabase.from('profiles').delete().eq('id', userId);
      debugPrint('Remote nuke complete.');
    } catch (e) {
      debugPrint('Remote nuke failed: $e');
      rethrow;
    }
  }

  /// NEW: Deletes only attendance logs from Supabase.
  Future<void> clearRemoteAttendanceLogs() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      debugPrint('Clearing remote attendance logs for user $userId...');
      await _supabase.from('attendance_logs').delete().eq('user_id', userId);
      debugPrint('Remote logs cleared.');
    } catch (e) {
      debugPrint('Remote log clear failed: $e');
      rethrow;
    }
  }
}

// @riverpod
// SyncService syncService(SyncServiceRef ref) {
//   return SyncService(
//     ref.watch(localStorageServiceProvider),
//     ref.watch(settingsRepositoryProvider),
//     SupabaseService().client,
//     ref,
//   );
// }

// @riverpod
// class SyncController extends _$SyncController {
//   @override
//   AsyncValue<void> build() => const AsyncValue.data(null);

//   Future<String> sync() async {
//     state = const AsyncValue.loading();
//     String result = 'Unknown';
//     state = await AsyncValue.guard(() async {
//       result = await ref.read(syncServiceProvider).sync();
//     });
//     return result;
//   }
// }

// @riverpod
// Future<DateTime?> lastSyncTime(LastSyncTimeRef ref) async {
//   final prefs = await SharedPreferences.getInstance();
//   final val = prefs.getString('last_sync_time');
//   return val == null ? null : DateTime.parse(val);
// }
