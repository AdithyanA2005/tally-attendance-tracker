import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tally/core/data/repositories/profile_repository.dart';

import '../../../../core/data/models/semester_model.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/data/local_storage_service.dart';
import '../../../../core/data/repositories/cache_repository.dart';

part 'semester_repository.g.dart';

class SemesterRepository extends CacheRepository<Semester> {
  final LocalStorageService _localStorage;
  final ProfileRepository _profileRepository;

  SemesterRepository(
    LocalStorageService localStorage,
    SupabaseClient supabase,
    ProfileRepository profileRepository,
  ) : _localStorage = localStorage,
      _profileRepository = profileRepository,
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

  // READs

  Stream<List<Semester>> watchAllSemesters() {
    return stream.map((box) {
      final list = box.values.toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate)); // Newest first
      return list;
    });
  }

  Stream<Semester?> watchActiveSemester() {
    // Watch profile changes (where activeSemesterId lives)
    return _profileRepository.watchProfile().map((profile) {
      final id = profile?.activeSemesterId;

      if (id != null && box.containsKey(id)) {
        return box.get(id);
      }

      // Fallback: Return most recent semester if any exist
      if (box.isNotEmpty) {
        final list = box.values.toList();
        list.sort((a, b) => b.startDate.compareTo(a.startDate));
        return list.first;
      }
      return null;
    });
  }

  Future<String?> getActiveSemesterId() async {
    final active = getActiveSemesterSync();
    return active?.id;
  }

  // WRITES

  Future<void> setActiveSemesterId(String id) async {
    await _profileRepository.updateActiveSemester(id);
  }

  Future<void> addSemester(Semester semester) async {
    // 1. Optimistic
    await saveLocal(semester);

    // 2. Remote
    final json = semester.toJson();
    json['user_id'] = supabase.auth.currentUser!.id;
    await supabase.from('semesters').upsert(json);

    // Auto-set as active if it's the first one
    if (box.length == 1) {
      await setActiveSemesterId(semester.id);
    }
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
    // 1. Manual Local Cascade of Children

    // Subjects
    final subjectBox = _localStorage.subjectBox;
    final subjectKeys = subjectBox.values
        .where((s) => s.semesterId == id)
        .map((s) => s.id)
        .toList();
    if (subjectKeys.isNotEmpty) await subjectBox.deleteAll(subjectKeys);

    // Sessions
    final sessionBox = _localStorage.sessionBox;
    final sessionKeys = sessionBox.values
        .where((s) => s.semesterId == id)
        .map((s) => s.id)
        .toList();
    if (sessionKeys.isNotEmpty) await sessionBox.deleteAll(sessionKeys);

    // Timetables
    final timetableBox = _localStorage.timetableBox;
    final timetableKeys = timetableBox.values
        .where((t) => t.semesterId == id)
        .map((t) => t.id)
        .toList();
    if (timetableKeys.isNotEmpty) await timetableBox.deleteAll(timetableKeys);

    // 2. Optimistic Delete of Semester
    await deleteLocal(id);

    // 3. Remote Delete
    await supabase.from('semesters').delete().eq('id', id);

    // Update active semester if we deleted the active one
    final activeId = _profileRepository.getProfileSync()?.activeSemesterId;
    if (activeId == id) {
      // Clear it or set to next available?
      // For now, let fallback logic handle "next available"
      // but we should probably clear the dangling reference in profile.
      await _profileRepository.updateActiveSemester(''); // or null if nullable
    }
  }

  // Helper for one-off reads
  Semester? getActiveSemesterSync() {
    final profile = _profileRepository.getProfileSync();
    final id = profile?.activeSemesterId;

    if (id != null && box.containsKey(id)) {
      return box.get(id);
    }

    // Fallback logic
    if (box.isNotEmpty) {
      final list = box.values.toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list.first;
    }
    return null;
  }
}

@riverpod
SemesterRepository semesterRepository(SemesterRepositoryRef ref) {
  return SemesterRepository(
    ref.watch(localStorageServiceProvider),
    SupabaseService().client,
    ref.watch(profileRepositoryProvider),
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
