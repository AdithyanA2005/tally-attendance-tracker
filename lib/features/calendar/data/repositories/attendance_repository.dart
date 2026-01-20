import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import 'package:tally/core/services/supabase_service.dart';
import 'package:tally/core/data/local_storage_service.dart';
import 'package:tally/core/data/repositories/cache_repository.dart';

import 'package:tally/features/settings/data/repositories/semester_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final supabase = SupabaseService().client;
  final semesterRepository = ref.watch(semesterRepositoryProvider);
  final localStorage = ref.watch(localStorageServiceProvider);
  return AttendanceRepository(supabase, semesterRepository, localStorage);
});

class _SubjectCache extends CacheRepository<Subject> {
  _SubjectCache(LocalStorageService localStorage, SupabaseClient supabase)
    : super(
        box: localStorage.subjectBox,
        supabase: supabase,
        tableName: 'subjects',
        fromJson: Subject.fromJson,
      ) {
    initSync();
  }
  @override
  String getId(Subject item) => item.id;
}

class _SessionCache extends CacheRepository<ClassSession> {
  _SessionCache(LocalStorageService localStorage, SupabaseClient supabase)
    : super(
        box: localStorage.sessionBox,
        supabase: supabase,
        tableName: 'attendance_logs',
        fromJson: ClassSession.fromJson,
      ) {
    initSync();
  }
  @override
  String getId(ClassSession item) => item.id;
}

class _TimetableCache extends CacheRepository<TimetableEntry> {
  _TimetableCache(LocalStorageService localStorage, SupabaseClient supabase)
    : super(
        box: localStorage.timetableBox,
        supabase: supabase,
        tableName: 'timetables',
        fromJson: TimetableEntry.fromJson,
      ) {
    initSync();
  }
  @override
  String getId(TimetableEntry item) => item.id;
}

class AttendanceRepository {
  final SupabaseClient _supabase;
  final SemesterRepository _semesterRepository;
  final LocalStorageService _localStorage;

  late final _SubjectCache _subjects;
  late final _SessionCache _sessions;
  late final _TimetableCache _timetable;

  AttendanceRepository(
    this._supabase,
    this._semesterRepository,
    this._localStorage,
  ) {
    _subjects = _SubjectCache(_localStorage, _supabase);
    _sessions = _SessionCache(_localStorage, _supabase);
    _timetable = _TimetableCache(_localStorage, _supabase);
  }

  String? get _activeSemesterId =>
      _semesterRepository.getActiveSemesterSync()?.id;

  // Subjects

  Stream<List<Subject>> watchSubjects({String? semesterId}) {
    return _subjects.stream.map((box) {
      final targetSemesterId = semesterId ?? _activeSemesterId;
      if (targetSemesterId == null) return [];
      return box.values.where((s) => s.semesterId == targetSemesterId).toList();
    });
  }

  Future<List<Subject>> getSubjects({String? semesterId}) async {
    final targetSemesterId = semesterId ?? _activeSemesterId;
    if (targetSemesterId == null) return [];

    // Prefer Local
    return _subjects.box.values
        .where((s) => s.semesterId == targetSemesterId)
        .toList();
  }

  Future<void> addSubject({
    required String name,
    required double minAttendance,
    required int weeklyHours,
    required Color color,
  }) async {
    final semesterId = _activeSemesterId;
    if (semesterId == null) throw Exception('No active semester');

    final id = const Uuid().v4();
    final subject = Subject(
      id: id,
      semesterId: semesterId,
      name: name,
      minimumAttendancePercentage: minAttendance,
      weeklyHours: weeklyHours,
      colorTag: color.value,
      hasPendingSync: false,
      lastUpdated: DateTime.now(),
    );

    // Optimistic
    await _subjects.saveLocal(subject);

    final json = subject.toJson();
    json['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('subjects').upsert(json);
  }

  Future<void> updateSubject(Subject subject) async {
    final updated = subject.copyWith(
      hasPendingSync: false,
      lastUpdated: DateTime.now(),
    );

    // Optimistic
    await _subjects.saveLocal(updated);

    final json = updated.toJson();
    json['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('subjects').upsert(json);
  }

  Future<void> deleteSubject(String id) async {
    // 1. Cleanup Local Orphans (Hive doesn't cascade)
    final sessionsToDelete = _sessions.box.values
        .where((s) => s.subjectId == id)
        .map((s) => s.id);
    await _sessions.box.deleteAll(sessionsToDelete);

    final timetableToDelete = _timetable.box.values
        .where((t) => t.subjectId == id)
        .map((t) => t.id);
    await _timetable.box.deleteAll(timetableToDelete);

    // 2. Delete Subject Locally
    await _subjects.deleteLocal(id);

    // 3. Delete Subject Remotely (Postgres ON DELETE CASCADE handles children)
    await _supabase.from('subjects').delete().eq('id', id);
  }

  // Sessions

  Stream<List<ClassSession>> watchAllSessions({String? semesterId}) {
    return _sessions.stream.map((box) {
      final targetSemesterId = semesterId ?? _activeSemesterId;
      if (targetSemesterId == null) return [];
      return box.values.where((s) => s.semesterId == targetSemesterId).toList();
    });
  }

  Future<List<ClassSession>> getSessions(
    String subjectId, {
    String? semesterId,
  }) async {
    final targetSemesterId = semesterId ?? _activeSemesterId;
    if (targetSemesterId == null) return [];

    // Prefer Local
    return _sessions.box.values
        .where(
          (s) => s.semesterId == targetSemesterId && s.subjectId == subjectId,
        )
        .toList();
  }

  Future<void> logSession(ClassSession session) async {
    final updated = session.copyWith(
      hasPendingSync: false,
      lastUpdated: DateTime.now(),
    );

    // Optimistic
    await _sessions.saveLocal(updated);

    final json = updated.toJson();
    json['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('attendance_logs').upsert(json);
  }

  Future<void> updateSession(ClassSession session) async {
    await logSession(session);
  }

  Future<void> deleteSession(String id) async {
    // Optimistic
    await _sessions.deleteLocal(id);
    await _supabase.from('attendance_logs').delete().eq('id', id);
  }

  Future<void> deleteDuplicateSessions({required DateTime date}) async {
    // Skipping to match V1 Pivot scope
  }

  Future<List<ClassSession>> getAllSessions({String? semesterId}) async {
    final targetSemesterId = semesterId ?? _activeSemesterId;
    if (targetSemesterId == null) return [];

    // Prefer Local
    return _sessions.box.values
        .where((s) => s.semesterId == targetSemesterId)
        .toList();
  }

  // Timetable

  Stream<List<TimetableEntry>> watchTimetable({
    int? dayOfWeek,
    String? semesterId,
  }) {
    return _timetable.stream.map((box) {
      final targetSemesterId = semesterId ?? _activeSemesterId;
      if (targetSemesterId == null) return [];

      var query = box.values.where((e) => e.semesterId == targetSemesterId);

      if (dayOfWeek != null) {
        query = query.where((e) => e.dayOfWeek == dayOfWeek);
      }
      return query.toList();
    });
  }

  Future<List<TimetableEntry>> getTimetable({
    int? dayOfWeek,
    String? semesterId,
  }) async {
    final targetSemesterId = semesterId ?? _activeSemesterId;
    if (targetSemesterId == null) return [];

    var query = _timetable.box.values.where(
      (e) => e.semesterId == targetSemesterId,
    );

    if (dayOfWeek != null) {
      query = query.where((e) => e.dayOfWeek == dayOfWeek);
    }
    return query.toList();
  }

  Future<void> addTimetableEntry({
    required String subjectId,
    required int dayOfWeek,
    required String startTime,
    required double durationInHours,
  }) async {
    final semesterId = _activeSemesterId;
    if (semesterId == null) throw Exception('No active semester');

    final id = const Uuid().v4();
    final entry = TimetableEntry(
      id: id,
      subjectId: subjectId,
      semesterId: semesterId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      durationInHours: durationInHours,
      hasPendingSync: false,
      lastUpdated: DateTime.now(),
    );

    // Optimistic
    await _timetable.saveLocal(entry);

    final json = entry.toJson();
    json['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('timetables').upsert(json);
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    final updated = entry.copyWith(
      hasPendingSync: false,
      lastUpdated: DateTime.now(),
    );

    // Optimistic
    await _timetable.saveLocal(updated);

    final json = updated.toJson();
    json['user_id'] = _supabase.auth.currentUser!.id;
    await _supabase.from('timetables').upsert(json);
  }

  Future<void> deleteTimetableEntry(String id) async {
    // Optimistic
    await _timetable.deleteLocal(id);
    await _supabase.from('timetables').delete().eq('id', id);
  }
}
