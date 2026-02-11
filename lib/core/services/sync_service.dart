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

import 'package:tally/features/calendar/data/repositories/day_note_repository.dart';
import 'package:tally/features/calendar/data/models/day_note_model.dart';

// part 'sync_service.g.dart';

class SyncService {
  final LocalStorageService _localStorage;
  final SettingsRepository _settings;
  final DayNoteRepository _dayNotes;
  final SupabaseClient _supabase;
  final Ref? _ref; // Optional ref to invalidate providers

  SyncService(
    this._localStorage,
    this._settings,
    this._supabase,
    this._dayNotes, [
    this._ref,
  ]);

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

    // Day Notes
    final notesToPush = _dayNotes.getAllNotes().where((n) => n.hasPendingSync);
    for (var note in notesToPush) {
      try {
        final json = note.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase
            .from('day_notes')
            .upsert(json, onConflict: 'user_id, date_iso');

        await _dayNotes.saveNoteInternal(note.copyWith(hasPendingSync: false));
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push day note ${note.dateIso}: $e');
      }
    }

    // Semesters
    final semestersToPush = _localStorage.semesterBox.values.where(
      (s) => s.hasPendingSync,
    );
    for (var semester in semestersToPush) {
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
    final subjectsToPush = _localStorage.subjectBox.values.where(
      (s) => s.hasPendingSync,
    );
    for (var subject in subjectsToPush) {
      // AUTO-FIX: Orphaned Subjects
      var subjectToPush = subject;
      if (subject.semesterId.isEmpty && defaultSemesterId != null) {
        subjectToPush = subject.copyWith(semesterId: defaultSemesterId);
      }

      try {
        final json = subjectToPush.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('subjects').upsert(json);
        await _localStorage.subjectBox.put(
          subjectToPush.id,
          subjectToPush.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push subject ${subjectToPush.id}: $e');
      }
    }

    // Sessions
    final sessionsToPush = _localStorage.sessionBox.values.where(
      (e) => e.hasPendingSync && !e.id.startsWith('virtual_'),
    );

    for (var session in sessionsToPush) {
      // AUTO-FIX: Orphaned Sessions
      var sessionToPush = session;
      if (session.semesterId.isEmpty && defaultSemesterId != null) {
        sessionToPush = session.copyWith(semesterId: defaultSemesterId);
      }

      try {
        final json = sessionToPush.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('attendance_logs').upsert(json);

        await _localStorage.sessionBox.put(
          sessionToPush.id,
          sessionToPush.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push session ${sessionToPush.id}: $e');
      }
    }

    // Timetable
    final entriesToPush = _localStorage.timetableBox.values.where(
      (e) => e.hasPendingSync && !e.id.startsWith('virtual_'),
    );

    for (var entry in entriesToPush) {
      // AUTO-FIX: Orphaned Timetable
      var entryToPush = entry;
      if (entry.semesterId.isEmpty && defaultSemesterId != null) {
        entryToPush = entry.copyWith(semesterId: defaultSemesterId);
      }

      try {
        final json = entryToPush.toJson();
        json['user_id'] = _supabase.auth.currentUser!.id;
        await _supabase.from('timetables').upsert(json);

        await _localStorage.timetableBox.put(
          entryToPush.id,
          entryToPush.copyWith(hasPendingSync: false),
        );
        pushed++;
      } catch (e) {
        failed++;
        lastError = e.toString();
        debugPrint('Failed to push timetable entry ${entryToPush.id}: $e');
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

    // We don't use lastSyncTime anymore for Pull (Reconciliation Strategy)
    // final prefs = await SharedPreferences.getInstance();

    // -------------------------------------------------------------------------
    // 1. Semesters (Reconciliation)
    // -------------------------------------------------------------------------
    try {
      final remoteMeta = await _supabase
          .from('semesters')
          .select('id, updated_at');
      final remoteMap = {
        for (var item in remoteMeta)
          item['id'] as String: DateTime.parse(item['updated_at']),
      };

      // Identify deletions
      final localSemesters = _localStorage.semesterBox.values.toList();
      for (var local in localSemesters) {
        if (!local.hasPendingSync) {
          if (!remoteMap.containsKey(local.id)) {
            await _localStorage.semesterBox.delete(local.id);
          }
        }
      }

      // Identify updates
      final List<String> toFetch = [];
      for (var entry in remoteMap.entries) {
        final local = _localStorage.semesterBox.get(entry.key);
        if (local == null || entry.value.isAfter(local.lastUpdated)) {
          toFetch.add(entry.key);
        }
      }

      if (toFetch.isNotEmpty) {
        final freshData = await _supabase
            .from('semesters')
            .select()
            .filter('id', 'in', toFetch);
        for (var json in freshData) {
          final s = Semester.fromJson(json);
          await _localStorage.semesterBox.put(s.id, s);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error reconciling semesters: $e');
    }

    // -------------------------------------------------------------------------
    // 2. Profile (Check Single Row)
    // -------------------------------------------------------------------------
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

    // -------------------------------------------------------------------------
    // 3. Subjects (Reconciliation)
    // -------------------------------------------------------------------------
    try {
      final remoteMeta = await _supabase
          .from('subjects')
          .select('id, updated_at');
      final remoteMap = {
        for (var item in remoteMeta)
          item['id'] as String: DateTime.parse(item['updated_at']),
      };

      final localSubjects = _localStorage.subjectBox.values.toList();
      for (var local in localSubjects) {
        if (!local.hasPendingSync) {
          if (!remoteMap.containsKey(local.id)) {
            await _localStorage.subjectBox.delete(local.id);
          }
        }
      }

      final List<String> toFetch = [];
      for (var entry in remoteMap.entries) {
        final local = _localStorage.subjectBox.get(entry.key);
        if (local == null || entry.value.isAfter(local.lastUpdated)) {
          toFetch.add(entry.key);
        }
      }

      if (toFetch.isNotEmpty) {
        final freshData = await _supabase
            .from('subjects')
            .select()
            .filter('id', 'in', toFetch);
        for (var json in freshData) {
          final s = Subject.fromJson(json);
          await _localStorage.subjectBox.put(s.id, s);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error reconciling subjects: $e');
    }

    // -------------------------------------------------------------------------
    // 4. Sessions / Attendance Logs (Reconciliation)
    // -------------------------------------------------------------------------
    try {
      final remoteMeta = await _supabase
          .from('attendance_logs')
          .select('id, updated_at');
      final remoteMap = {
        for (var item in remoteMeta)
          item['id'] as String: DateTime.parse(item['updated_at']),
      };

      final localSessions = _localStorage.sessionBox.values.toList();
      for (var local in localSessions) {
        // Ignore virtual sessions
        if (local.id.startsWith('virtual_')) continue;

        if (!local.hasPendingSync) {
          if (!remoteMap.containsKey(local.id)) {
            await _localStorage.sessionBox.delete(local.id);
          }
        }
      }

      final List<String> toFetch = [];
      for (var entry in remoteMap.entries) {
        final local = _localStorage.sessionBox.get(entry.key);
        if (local == null || entry.value.isAfter(local.lastUpdated)) {
          toFetch.add(entry.key);
        }
      }

      // Batch in chunks of 50 to avoid URL length limits if many updates
      for (var i = 0; i < toFetch.length; i += 50) {
        final end = (i + 50 < toFetch.length) ? i + 50 : toFetch.length;
        final batch = toFetch.sublist(i, end);
        if (batch.isNotEmpty) {
          final freshData = await _supabase
              .from('attendance_logs')
              .select()
              .filter('id', 'in', batch);
          for (var json in freshData) {
            final s = ClassSession.fromJson(json);
            await _localStorage.sessionBox.put(s.id, s);
            pulled++;
          }
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error reconciling sessions: $e');
    }

    // -------------------------------------------------------------------------
    // 5. Timetables (Reconciliation)
    // -------------------------------------------------------------------------
    try {
      final remoteMeta = await _supabase
          .from('timetables')
          .select('id, updated_at');
      final remoteMap = {
        for (var item in remoteMeta)
          item['id'] as String: DateTime.parse(item['updated_at']),
      };

      final localEntries = _localStorage.timetableBox.values.toList();
      for (var local in localEntries) {
        if (!local.hasPendingSync) {
          if (!remoteMap.containsKey(local.id)) {
            await _localStorage.timetableBox.delete(local.id);
          }
        }
      }

      final List<String> toFetch = [];
      for (var entry in remoteMap.entries) {
        final local = _localStorage.timetableBox.get(entry.key);
        if (local == null || entry.value.isAfter(local.lastUpdated)) {
          toFetch.add(entry.key);
        }
      }

      if (toFetch.isNotEmpty) {
        final freshData = await _supabase
            .from('timetables')
            .select()
            .filter('id', 'in', toFetch);
        for (var json in freshData) {
          final t = TimetableEntry.fromJson(json);
          await _localStorage.timetableBox.put(t.id, t);
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error reconciling timetables: $e');
    }

    // -------------------------------------------------------------------------
    // 6. Day Notes (Reconciliation)
    // -------------------------------------------------------------------------
    try {
      final remoteMeta = await _supabase
          .from('day_notes')
          .select('date_iso, updated_at');

      final remoteMap = {
        for (var item in remoteMeta)
          item['date_iso'] as String: DateTime.parse(item['updated_at']),
      };

      final localNotes = _dayNotes.getAllNotes();
      for (var localNote in localNotes) {
        if (!localNote.hasPendingSync) {
          if (!remoteMap.containsKey(localNote.dateIso)) {
            await _dayNotes.deleteNoteLocally(localNote.dateIso);
          }
        }
      }

      final List<String> toFetch = [];
      for (var entry in remoteMap.entries) {
        final key = entry.key;
        final remoteTime = entry.value;
        final localNote = _dayNotes.getNoteByDateKey(key);

        if (localNote == null || remoteTime.isAfter(localNote.updatedAt)) {
          toFetch.add(key);
        }
      }

      if (toFetch.isNotEmpty) {
        final freshData = await _supabase
            .from('day_notes')
            .select()
            .filter('date_iso', 'in', toFetch);

        for (var json in freshData) {
          await _dayNotes.saveNoteInternal(DayNote.fromJson(json));
          pulled++;
        }
      }
    } catch (e) {
      failed++;
      debugPrint('Error reconciling day notes: $e');
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

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    ref.watch(localStorageServiceProvider),
    ref.watch(settingsRepositoryProvider),
    SupabaseService().client,
    ref.watch(dayNoteRepositoryProvider),
    ref,
  );
});
