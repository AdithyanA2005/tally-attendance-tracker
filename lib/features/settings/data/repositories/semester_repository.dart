import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/data/models/semester_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/data/local_storage_service.dart';
import '../../../../core/data/repositories/cache_repository.dart';

part 'semester_repository.g.dart';

class SemesterRepository extends CacheRepository<Semester> {
  final LocalStorageService _localStorage;

  SemesterRepository(LocalStorageService localStorage, SupabaseClient supabase)
    : _localStorage = localStorage,
      super(
        box: localStorage.semesterBox,
        supabase: supabase,
        tableName: 'semesters',
        fromJson: Semester.fromJson,
      ) {
    initSync();
  }

  @override
  String getId(Semester item) => item.id;

  // READs - Now from Hive

  Stream<List<Semester>> watchAllSemesters() {
    return stream.map((box) {
      final list = box.values.toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
      return list;
    });
  }

  Stream<Semester?> watchActiveSemester() {
    return stream.map((box) {
      final list = box.values.toList();
      try {
        return list.firstWhere((s) => s.isActive);
      } catch (_) {
        if (list.isEmpty) return null;
        list.sort((a, b) => b.startDate.compareTo(a.startDate));
        return list.first;
      }
    });
  }

  Future<String?> getActiveSemesterId() async {
    final active = getActiveSemesterSync();
    return active?.id;
  }

  // WRITES - Optimistic + Remote

  Future<void> setActiveSemesterId(String id) async {
    final userId = supabase.auth.currentUser!.id;

    // 1. Optimistic Update (Local)
    // 1. Optimistic Update (Local)
    final all = box.values.toList();

    // First, deactivate others to avoid dual-active state
    for (var s in all) {
      if (s.id != id && s.isActive) {
        await saveLocal(s.copyWith(isActive: false));
      }
    }

    // Then, activate target
    for (var s in all) {
      if (s.id == id && !s.isActive) {
        await saveLocal(s.copyWith(isActive: true));
      }
    }

    // 2. Remote Update
    // We do this carefully to avoid race conditions but Supabase is the source of truth eventually.
    // The Stream listener in CacheRepository will reconcile eventually.

    // Mark target as active
    await supabase.from('semesters').update({'is_active': true}).eq('id', id);

    // Mark others as inactive
    await supabase
        .from('semesters')
        .update({'is_active': false})
        .eq('user_id', userId)
        .neq('id', id);
  }

  Future<void> addSemester(Semester semester) async {
    // 1. Optimistic
    await saveLocal(semester);

    // 2. Remote
    final json = semester.toJson();
    json['user_id'] = supabase.auth.currentUser!.id;
    await supabase.from('semesters').upsert(json);
  }

  Future<void> updateSemester(Semester semester) async {
    // 1. Optimistic
    await saveLocal(semester);

    // 2. Remote
    final json = semester.toJson();
    json['user_id'] = supabase.auth.currentUser!.id;
    await supabase.from('semesters').upsert(json);
  }

  Future<void> deleteSemester(String id) async {
    // 1. Manual Local Cascade (Big Nuke for this Semester)
    // We must manually locate and delete all child records from Hive
    // because Hive doesn't support cascades, and waiting for Supabase sync
    // leaves "orphaned" data visible in the UI for seconds/minutes.

    // Scan & Delete Subjects
    final subjectBox = _localStorage.subjectBox;
    final subjectKeys = subjectBox.values
        .where((s) => s.semesterId == id)
        .map(
          (s) => s.id,
        ) // CacheRepo uses ID as key usually, but check getKey implementation?
        // CacheRepository implementation uses `put(getId(item), item)`. So key IS id.
        .toList();
    if (subjectKeys.isNotEmpty) await subjectBox.deleteAll(subjectKeys);

    // Scan & Delete Sessions
    final sessionBox = _localStorage.sessionBox;
    final sessionKeys = sessionBox.values
        .where((s) => s.semesterId == id)
        .map((s) => s.id)
        .toList();
    if (sessionKeys.isNotEmpty) await sessionBox.deleteAll(sessionKeys);

    // Scan & Delete Timetables
    final timetableBox = _localStorage.timetableBox;
    final timetableKeys = timetableBox.values
        .where((t) => t.semesterId == id)
        .map((t) => t.id)
        .toList();
    if (timetableKeys.isNotEmpty) await timetableBox.deleteAll(timetableKeys);

    // 2. Optimistic Delete of Semester
    await deleteLocal(id);

    // 3. Remote Delete
    // DB Constraints (ON DELETE CASCADE) now handle cleanup of children (subjects, logs, timetables)
    await supabase.from('semesters').delete().eq('id', id);
  }

  // Helper for one-off reads if needed (prefer streams in UI)
  Semester? getActiveSemesterSync() {
    try {
      return box.values.firstWhere((s) => s.isActive);
    } catch (_) {
      if (box.isNotEmpty) return box.values.last; // Fallback
      return null;
    }
  }
}

@riverpod
SemesterRepository semesterRepository(SemesterRepositoryRef ref) {
  return SemesterRepository(
    ref.watch(localStorageServiceProvider),
    SupabaseService().client,
  );
}

@riverpod
Stream<List<Semester>> watchSemesters(WatchSemestersRef ref) {
  return ref.watch(semesterRepositoryProvider).watchAllSemesters();
}

@riverpod
Stream<Semester?> activeSemester(ActiveSemesterRef ref) {
  return ref.watch(semesterRepositoryProvider).watchActiveSemester();
}
