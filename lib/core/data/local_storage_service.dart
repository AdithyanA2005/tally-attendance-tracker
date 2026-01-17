import 'package:hive_flutter/hive_flutter.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';

/// Service responsible for initializing and accessing Hive local storage boxes.
///
/// This handles TypeAdapters registration and opening specific boxes for
/// Subjects, Sessions, and Timetable entries.
class LocalStorageService {
  static const String subjectBoxName = 'subjects';
  static const String sessionBoxName = 'sessions';
  static const String timetableBoxName = 'timetable';

  Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(SubjectAdapter());
    Hive.registerAdapter(TimetableEntryAdapter());
    Hive.registerAdapter(ClassSessionAdapter());
    Hive.registerAdapter(AttendanceStatusAdapter());

    await Hive.openBox<Subject>(subjectBoxName);
    await Hive.openBox<ClassSession>(sessionBoxName);
    await Hive.openBox<TimetableEntry>(timetableBoxName);
  }

  Box<Subject> get subjectBox => Hive.box<Subject>(subjectBoxName);
  Box<ClassSession> get sessionBox => Hive.box<ClassSession>(sessionBoxName);
  Box<TimetableEntry> get timetableBox =>
      Hive.box<TimetableEntry>(timetableBoxName);
}
