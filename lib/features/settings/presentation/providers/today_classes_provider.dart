import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../calendar/data/repositories/attendance_repository.dart';
import '../../../calendar/presentation/providers/attendance_provider.dart';
import '../../data/models/timetable_entry_model.dart';
import '../../../calendar/data/models/session_model.dart';
import '../../../calendar/data/models/subject_model.dart';

// 1. Define the stream provider separately to ensure stability
final dailyTimetableProvider = StreamProvider.family<List<TimetableEntry>, int>(
  (ref, dayOfWeek) {
    final repository = ref.watch(attendanceRepositoryProvider);
    return repository.watchTimetable(dayOfWeek: dayOfWeek);
  },
);

final todayClassesProvider = Provider<AsyncValue<List<TodayClassItem>>>((ref) {
  final weekday = DateTime.now().weekday;

  // 2. Watch the stable family provider
  final timetableAsync = ref.watch(dailyTimetableProvider(weekday));
  final sessionsAsync = ref.watch(allSessionsStreamProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);

  // 3. Handle loading states gracefully
  // If ANY are loading, we return loading.
  // Note: StreamProviders with "startWith" might still be async for one frame.
  if (timetableAsync.isLoading ||
      sessionsAsync.isLoading ||
      subjectsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // 4. Handle errors
  if (timetableAsync.hasError)
    return AsyncValue.error(timetableAsync.error!, timetableAsync.stackTrace!);
  if (sessionsAsync.hasError)
    return AsyncValue.error(sessionsAsync.error!, sessionsAsync.stackTrace!);
  if (subjectsAsync.hasError)
    return AsyncValue.error(subjectsAsync.error!, subjectsAsync.stackTrace!);

  // 5. Combine data
  return AsyncValue.data(
    _combineData(
      timetable: timetableAsync.value ?? [],
      sessions: sessionsAsync.value ?? [],
      subjects: subjectsAsync.value ?? [],
    ),
  );
});

List<TodayClassItem> _combineData({
  required List<TimetableEntry> timetable,
  required List<ClassSession> sessions,
  required List<Subject> subjects,
}) {
  final subjectMap = {for (var s in subjects) s.id: s};
  final today = DateTime.now();

  return timetable
      .map((entry) {
        final subject = subjectMap[entry.subjectId];
        if (subject == null) return null;

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

        final existingSession = sessions.firstWhere(
          (s) {
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

        final displaySubject =
            existingSession.id.isNotEmpty &&
                subjectMap.containsKey(existingSession.subjectId)
            ? subjectMap[existingSession.subjectId]!
            : subject;

        return TodayClassItem(
          entry: entry,
          subject: displaySubject,
          originalSubject: subject,
          currentStatus: existingSession.id.isEmpty
              ? AttendanceStatus.unmarked
              : existingSession.status,
          existingSessionId: existingSession.id.isEmpty
              ? null
              : existingSession.id,
          existingSession: existingSession.id.isEmpty ? null : existingSession,
          scheduledTime: expectedTime,
        );
      })
      .whereType<TodayClassItem>()
      .toList()
    ..sort((a, b) => a.entry.startTime.compareTo(b.entry.startTime));
}

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
