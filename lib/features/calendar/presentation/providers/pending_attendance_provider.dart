import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'attendance_provider.dart';
import '../../data/repositories/attendance_repository.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../../../settings/data/repositories/semester_repository.dart';

class PendingClassItem {
  final Subject subject;
  final DateTime dateTime;
  final double durationInHours;

  PendingClassItem({
    required this.subject,
    required this.dateTime,
    required this.durationInHours,
  });
}

final pendingAttendanceProvider = Provider<AsyncValue<List<PendingClassItem>>>((
  ref,
) {
  // We need to watch all sessions to know what IS marked
  final sessionsAsync = ref.watch(sessionsStreamProvider);
  // We need subjects to map IDs to names/colors
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  // We need the full timetable to know what WAS scheduled
  final timetableAsync = ref.watch(fullTimetableStreamProvider);

  if (sessionsAsync.isLoading ||
      subjectsAsync.isLoading ||
      timetableAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (sessionsAsync.hasError ||
      subjectsAsync.hasError ||
      timetableAsync.hasError) {
    return const AsyncValue.error('Error loading data', StackTrace.empty);
  }

  final sessions = sessionsAsync.value ?? [];
  final subjects = subjectsAsync.value ?? [];
  final timetable = timetableAsync.value ?? [];
  final subjectMap = {for (var s in subjects) s.id: s};

  final List<PendingClassItem> pendingItems = [];
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);

  // Get Semester Start Date
  final activeSemester = ref.watch(activeSemesterProvider);
  final semesterStartDate =
      activeSemester.value?.startDate ?? DateTime(2023, 1, 1);

  // Look back 7 days, EXCLUDING today (today is handled by Today's Schedule)
  for (int i = 1; i <= 7; i++) {
    final dateToCheck = todayStart.subtract(Duration(days: i));

    // STOP if we go before the semester start date
    if (dateToCheck.isBefore(semesterStartDate)) {
      break;
    }

    final weekday = dateToCheck.weekday; // 1 = Mon, 7 = Sun

    // Get entries for this weekday
    final dailyEntries = timetable.where((e) => e.dayOfWeek == weekday);

    for (var entry in dailyEntries) {
      if (!subjectMap.containsKey(entry.subjectId)) continue;

      // Construct the expected DateTime for this class
      final timeParts = entry.startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final classDateTime = DateTime(
        dateToCheck.year,
        dateToCheck.month,
        dateToCheck.day,
        hour,
        minute,
      );

      // Check if a session exists for this subject around this time
      // We accept a window of matching (e.g., exact match or within reason,
      // but usually the logic uses the exact scheduled time).
      // Let's look for any session for this subject on this DATE.
      // Actually, if there are multiple classes for the same subject on the same day,
      // we need to be careful.
      // Ideally, we match strictly by time or check if *enough* sessions exist.

      // Check if ANY session exists for this time slot
      ClassSession? matchingSession;
      try {
        matchingSession = sessions.firstWhere((s) {
          return s.date.year == classDateTime.year &&
              s.date.month == classDateTime.month &&
              s.date.day == classDateTime.day &&
              s.date.hour == classDateTime.hour &&
              s.date.minute == classDateTime.minute;
        });
      } catch (_) {
        matchingSession = null;
      }

      // If no session exists, OR it exists but is marked as "unmarked", add to pending
      if (matchingSession == null ||
          matchingSession.status == AttendanceStatus.scheduled) {
        pendingItems.add(
          PendingClassItem(
            subject: subjectMap[entry.subjectId]!,
            dateTime: classDateTime,
            durationInHours: entry.durationInHours,
          ),
        );
      }
    }
  }

  // Sort: Oldest first? Or Newest first?
  // User probably wants to fix yesterday first.
  pendingItems.sort((a, b) => b.dateTime.compareTo(a.dateTime));

  return AsyncValue.data(pendingItems);
});

// Helper provider for full timetable
final fullTimetableStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchTimetable(); // No day filter = all days
});

// Helper provider for all sessions
final sessionsStreamProvider = StreamProvider((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchAllSessions();
});
