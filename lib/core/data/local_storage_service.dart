import 'package:hive_flutter/hive_flutter.dart';
import '../../features/attendance/data/models/subject_model.dart';
import '../../features/attendance/data/models/session_model.dart';
import '../../features/timetable/data/models/timetable_entry_model.dart';

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
