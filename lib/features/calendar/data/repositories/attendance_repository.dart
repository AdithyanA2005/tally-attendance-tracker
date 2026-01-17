import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:tally/core/data/local_storage_service.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return AttendanceRepository(localStorage);
});

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

class AttendanceRepository {
  final LocalStorageService _localStorage;

  AttendanceRepository(this._localStorage);

  // Subjects
  Stream<List<Subject>> watchSubjects() {
    return _localStorage.subjectBox
        .watch()
        .map((event) {
          return _localStorage.subjectBox.values.toList();
        })
        .startWith(_localStorage.subjectBox.values.toList());
  }

  List<Subject> getSubjects() {
    return _localStorage.subjectBox.values.toList();
  }

  Future<void> addSubject({
    required String name,
    required double minAttendance,
    required int weeklyHours,
    required Color color,
  }) async {
    final id = const Uuid().v4();
    final subject = Subject(
      id: id,
      name: name,
      minimumAttendancePercentage: minAttendance,
      weeklyHours: weeklyHours,
      colorTag: color.value, // ignore: deprecated_member_use
    );
    await _localStorage.subjectBox.put(id, subject);
  }

  Future<void> updateSubject(Subject subject) async {
    await _localStorage.subjectBox.put(subject.id, subject);
  }

  Future<void> deleteSubject(String id) async {
    await _localStorage.subjectBox.delete(id);
  }

  // Sessions
  List<ClassSession> getSessions(String subjectId) {
    return _localStorage.sessionBox.values
        .where((s) => s.subjectId == subjectId)
        .toList();
  }

  Future<void> logSession(ClassSession session) async {
    await _localStorage.sessionBox.put(session.id, session);
  }

  Future<void> updateSession(ClassSession session) async {
    await _localStorage.sessionBox.put(session.id, session);
  }

  Future<void> deleteSession(String id) async {
    await _localStorage.sessionBox.delete(id);
  }

  Future<void> deleteDuplicateSessions({required DateTime date}) async {
    // Determine keys to delete
    final keysToDelete = _localStorage.sessionBox.values
        .where((s) {
          return s.date.year == date.year &&
              s.date.month == date.month &&
              s.date.day == date.day &&
              s.date.hour == date.hour &&
              s.date.minute == date.minute;
        })
        .map((s) => s.id)
        .toList();

    await _localStorage.sessionBox.deleteAll(keysToDelete);
  }

  Future<void> clearAllSessions() async {
    await _localStorage.sessionBox.clear();
  }

  Future<void> factoryReset() async {
    await _localStorage.sessionBox.clear();
    await _localStorage.timetableBox.clear();
    await _localStorage.subjectBox.clear();
  }

  Stream<List<ClassSession>> watchAllSessions() {
    return _localStorage.sessionBox
        .watch()
        .map((event) {
          return _localStorage.sessionBox.values.toList();
        })
        .startWith(_localStorage.sessionBox.values.toList());
  }

  // Timetable
  Stream<List<TimetableEntry>> watchTimetable({int? dayOfWeek}) {
    return _localStorage.timetableBox
        .watch()
        .map((event) {
          final all = _localStorage.timetableBox.values.toList();
          if (dayOfWeek != null) {
            return all.where((e) => e.dayOfWeek == dayOfWeek).toList();
          }
          return all;
        })
        .startWith(
          _localStorage.timetableBox.values.where((e) {
            if (dayOfWeek != null) return e.dayOfWeek == dayOfWeek;
            return true;
          }).toList(),
        );
  }

  Future<void> addTimetableEntry({
    required String subjectId,
    required int dayOfWeek,
    required String startTime,
    required double durationInHours,
  }) async {
    final id = const Uuid().v4();
    final entry = TimetableEntry(
      id: id,
      subjectId: subjectId,
      dayOfWeek: dayOfWeek,
      startTime: startTime,
      durationInHours: durationInHours,
    );
    await _localStorage.timetableBox.put(id, entry);
  }

  Future<void> updateTimetableEntry(TimetableEntry entry) async {
    await _localStorage.timetableBox.put(entry.id, entry);
  }

  Future<void> deleteTimetableEntry(String id) async {
    await _localStorage.timetableBox.delete(id);
  }
}

extension StreamStartWith<T> on Stream<T> {
  Stream<T> startWith(T value) {
    return Stream.value(value).concatWith([this]);
  }
}

extension StreamConcatWith<T> on Stream<T> {
  Stream<T> concatWith(Iterable<Stream<T>> other) async* {
    yield* this;
    for (final stream in other) {
      yield* stream;
    }
  }
}
