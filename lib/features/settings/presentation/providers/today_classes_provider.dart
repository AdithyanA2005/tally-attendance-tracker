import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../calendar/data/repositories/attendance_repository.dart';
import '../../../calendar/presentation/providers/attendance_provider.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';

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
  if (timetableAsync.hasError) {
    return AsyncValue.error(timetableAsync.error!, timetableAsync.stackTrace!);
  }
  if (sessionsAsync.hasError) {
    return AsyncValue.error(sessionsAsync.error!, sessionsAsync.stackTrace!);
  }
  if (subjectsAsync.hasError) {
    return AsyncValue.error(subjectsAsync.error!, subjectsAsync.stackTrace!);
  }

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
  final items = <TodayClassItem>[];

  // 1. Add timetable-based classes
  for (var entry in timetable) {
    final subject = subjectMap[entry.subjectId];
    if (subject == null) continue;

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
        durationMinutes: (subjectMap[entry.subjectId]!.weeklyHours / 5 * 60)
            .round(),
        // This is a placeholder default; ideally we'd use timetable duration
        // but converting hours to int minutes safely is needed.
      ),
    );

    final displaySubject =
        existingSession.id.isNotEmpty &&
            subjectMap.containsKey(existingSession.subjectId)
        ? subjectMap[existingSession.subjectId]!
        : subject;

    items.add(
      TodayClassItem(
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
      ),
    );
  }

  // 2. Add extra classes (not from timetable)
  final todayExtraClasses = sessions.where((s) {
    return s.isExtraClass &&
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day;
  });

  for (var session in todayExtraClasses) {
    final subject = subjectMap[session.subjectId];
    if (subject == null) continue;

    // Create a virtual timetable entry for the extra class
    final timeStr =
        '${session.date.hour.toString().padLeft(2, '0')}:${session.date.minute.toString().padLeft(2, '0')}';

    items.add(
      TodayClassItem(
        entry: TimetableEntry(
          id: session.id,
          dayOfWeek: session.date.weekday,
          subjectId: session.subjectId,
          startTime: timeStr,
          durationInHours: 1.0, // Default duration for extra classes
        ),
        subject: subject,
        originalSubject: subject,
        currentStatus: session.status,
        existingSessionId: session.id,
        existingSession: session,
        scheduledTime: session.date,
      ),
    );
  }

  // Sort by time
  items.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

  return items;
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
