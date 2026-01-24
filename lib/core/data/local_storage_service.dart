import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import 'package:tally/core/data/models/semester_model.dart';
import 'package:tally/core/data/models/user_profile_model.dart';

/// Service responsible for initializing and accessing Hive local storage boxes.
///
/// This handles TypeAdapters registration and opening specific boxes for
/// Subjects, Sessions, and Timetable entries.
class LocalStorageService {
  static const String subjectBoxName = 'subjects';
  static const String sessionBoxName = 'sessions';
  static const String timetableBoxName = 'timetable';
  static const String semesterBoxName = 'semesters';
  static const String profileBoxName = 'profiles';

  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TimetableEntryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ClassSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AttendanceStatusAdapter());
    }
    if (Hive.isAdapterRegistered(4) == false) {
      Hive.registerAdapter(SemesterAdapter());
    }
    if (Hive.isAdapterRegistered(5) == false) {
      Hive.registerAdapter(UserProfileAdapter());
    }

    await Hive.openBox<Subject>(subjectBoxName);
    await Hive.openBox<ClassSession>(sessionBoxName);
    await Hive.openBox<TimetableEntry>(timetableBoxName);
    await Hive.openBox<Semester>(semesterBoxName);
    await Hive.openBox<UserProfile>(profileBoxName);
  }

  Box<Subject> get subjectBox => Hive.box<Subject>(subjectBoxName);
  Box<ClassSession> get sessionBox => Hive.box<ClassSession>(sessionBoxName);
  Box<TimetableEntry> get timetableBox =>
      Hive.box<TimetableEntry>(timetableBoxName);
  Box<Semester> get semesterBox => Hive.box<Semester>(semesterBoxName);
  Box<UserProfile> get profileBox => Hive.box<UserProfile>(profileBoxName);
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});
