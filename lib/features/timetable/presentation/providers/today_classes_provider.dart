import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../attendance/data/repositories/attendance_repository.dart';
import '../../data/models/timetable_entry_model.dart';
import '../../../attendance/data/models/session_model.dart';
import '../../../attendance/data/models/subject_model.dart';

final todayClassesProvider = StreamProvider<List<TodayClassItem>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  final weekday = DateTime.now().weekday; // 1 = Mon, 7 = Sun

  // Combine streams: Timetable, Sessions, Subjects
  return repository.watchTimetable(dayOfWeek: weekday).asyncMap((
    entries,
  ) async {
    final sessions = await repository.watchAllSessions().first;
    final subjects = repository.getSubjects();
    final subjectMap = {for (var s in subjects) s.id: s};

    final today = DateTime.now();

    return entries
        .map((entry) {
          final subject = subjectMap[entry.subjectId];
          if (subject == null) return null;

          // Calculate expected start time for this entry
          final parts = entry.startTime.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          final expectedTime = DateTime(
            today.year,
            today.month,
            today.day,
            hour,
            minute,
          );

          // Search for session matching this time slot (approximate match to handle seconds/ms differences)
          // We allow a small window (e.g., matching hour/minute) because Hive might round trips or manual tweaks
          // But ideally we save exact time.
          final existingSession = sessions.firstWhere(
            (s) {
              // Check if same minute (robust enough for timetable slots)
              return s.date.year == expectedTime.year &&
                  s.date.month == expectedTime.month &&
                  s.date.day == expectedTime.day &&
                  s.date.hour == expectedTime.hour &&
                  s.date.minute == expectedTime.minute;
            },
            orElse: () => ClassSession(
              id: '',
              subjectId: '',
              date: DateTime(0),
              status: AttendanceStatus.unmarked,
            ),
          );

          // If session exists, use its subject (might be swapped).
          // If not, use timetable entry subject.
          final displaySubject =
              existingSession.id.isNotEmpty &&
                  subjectMap.containsKey(existingSession.subjectId)
              ? subjectMap[existingSession.subjectId]!
              : subject; // Default to timetable subject

          return TodayClassItem(
            entry: entry,
            subject:
                displaySubject, // Use the actual session subject if swapped
            originalSubject: subject, // Keep track of scheduled subject
            currentStatus: existingSession.id.isEmpty
                ? AttendanceStatus.unmarked
                : existingSession.status,
            existingSessionId: existingSession.id.isEmpty
                ? null
                : existingSession.id,
            existingSession: existingSession.id.isEmpty
                ? null
                : existingSession,
            scheduledTime: expectedTime,
          );
        })
        .whereType<TodayClassItem>()
        .toList()
      ..sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
  });
});

class TodayClassItem {
  final TimetableEntry entry;
  final Subject subject; // The one effectively taken (or scheduled if unmarked)
  final Subject originalSubject; // The one in timetable
  final AttendanceStatus currentStatus;
  final String? existingSessionId;
  final ClassSession? existingSession;
  final DateTime scheduledTime;

  TodayClassItem({
    required this.entry,
    required this.subject,
    required this.originalSubject,
    required this.currentStatus,
    this.existingSessionId,
    this.existingSession,
    required this.scheduledTime,
  });
}
