import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/calendar/data/repositories/attendance_repository.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../../../../features/calendar/domain/entities/subject_stats.dart';
import '../../../calendar/presentation/providers/attendance_provider.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';

class SubjectImpact {
  final Subject subject;
  final double currentPercentage;
  final double percentageIfPresent;
  final double percentageIfAbsent;

  SubjectImpact({
    required this.subject,
    required this.currentPercentage,
    required this.percentageIfPresent,
    required this.percentageIfAbsent,
  });

  double get gain => percentageIfPresent - currentPercentage;
  double get loss => currentPercentage - percentageIfAbsent;
}

class FutureImpactSummary {
  final DateTime date;
  final List<SubjectImpact> impacts;

  FutureImpactSummary({required this.date, required this.impacts});
}

final fullTimetableProvider = StreamProvider<List<TimetableEntry>>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.watchTimetable(dayOfWeek: null);
});

final futureImpactProvider = Provider<AsyncValue<FutureImpactSummary?>>((ref) {
  final fullTimetableAsync = ref.watch(fullTimetableProvider);
  final allStatsAsync = ref.watch(subjectStatsListProvider);
  final sessionsAsync = ref.watch(allSessionsStreamProvider);

  if (fullTimetableAsync.isLoading ||
      allStatsAsync.isLoading ||
      sessionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (fullTimetableAsync.hasError) {
    return AsyncValue.error(
      fullTimetableAsync.error!,
      fullTimetableAsync.stackTrace!,
    );
  }

  final timetable = fullTimetableAsync.value ?? [];
  final stats = allStatsAsync.value ?? [];
  final sessions = sessionsAsync.value ?? [];

  if (timetable.isEmpty || stats.isEmpty) {
    return const AsyncValue.data(null);
  }

  return AsyncValue.data(_calculateNextImpact(timetable, stats, sessions));
});

FutureImpactSummary? _calculateNextImpact(
  List<TimetableEntry> timetable,
  List<SubjectStats> stats,
  List<ClassSession> sessions,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Group timetable by weekday
  final timetableByDay = <int, List<TimetableEntry>>{};
  for (var entry in timetable) {
    timetableByDay.putIfAbsent(entry.dayOfWeek, () => []).add(entry);
  }

  // Find next working day
  DateTime? nextWorkingDay;
  List<TimetableEntry>? dayEntries;

  // Search next 14 days
  for (int i = 1; i <= 14; i++) {
    final date = today.add(Duration(days: i));
    final weekday = date.weekday;

    final entries = <TimetableEntry>[];

    // 1. Add Timetable Classes (if not cancelled)
    if (timetableByDay.containsKey(weekday)) {
      for (var entry in timetableByDay[weekday]!) {
        if (!_isSessionCancelled(entry, date, sessions)) {
          entries.add(entry);
        }
      }
    }

    // 2. Add Extra Classes from Sessions
    final extraSessions = sessions.where(
      (s) =>
          s.isExtraClass &&
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day &&
          s.status != AttendanceStatus.cancelled,
    );

    for (var session in extraSessions) {
      entries.add(
        TimetableEntry(
          id: session.id,
          subjectId: session.subjectId,
          dayOfWeek: weekday,
          startTime:
              '${session.date.hour.toString().padLeft(2, '0')}:${session.date.minute.toString().padLeft(2, '0')}',
          durationInHours: 1.0,
        ),
      );
    }

    if (entries.isNotEmpty) {
      nextWorkingDay = date;
      dayEntries = entries;
      break;
    }
  }

  if (nextWorkingDay == null || dayEntries == null) {
    return null;
  }

  // Calculate impact for each subject on that day
  final impacts = <SubjectImpact>[];
  final statsMap = {for (var s in stats) s.subject.id: s};
  final subjectCounts = <String, int>{};

  for (var entry in dayEntries) {
    subjectCounts[entry.subjectId] = (subjectCounts[entry.subjectId] ?? 0) + 1;
  }

  for (var entry in subjectCounts.entries) {
    final subjectId = entry.key;
    final count = entry.value;
    final stat = statsMap[subjectId];

    if (stat == null) continue;

    final currentConducted = stat.conducted;
    final currentPresent = stat.present;

    // Calculate percentages
    // If Present: conducted + count, present + count
    final presentPerc =
        ((currentPresent + count) / (currentConducted + count)) * 100;

    // If Absent: conducted + count, present (unchanged)
    final absentPerc = (currentPresent / (currentConducted + count)) * 100;

    impacts.add(
      SubjectImpact(
        subject: stat.subject,
        currentPercentage: stat.percentage,
        percentageIfPresent: presentPerc,
        percentageIfAbsent: absentPerc,
      ),
    );
  }

  if (impacts.isEmpty) return null;

  return FutureImpactSummary(date: nextWorkingDay, impacts: impacts);
}

bool _isSessionCancelled(
  TimetableEntry entry,
  DateTime date,
  List<ClassSession> sessions,
) {
  final parts = entry.startTime.split(':');
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final sessionTime = DateTime(date.year, date.month, date.day, hour, minute);

  final cancelledSession = sessions.firstWhere(
    (s) =>
        s.subjectId == entry.subjectId &&
        s.date.year == sessionTime.year &&
        s.date.month == sessionTime.month &&
        s.date.day == sessionTime.day &&
        s.date.hour == sessionTime.hour &&
        s.date.minute == sessionTime.minute &&
        s.status == AttendanceStatus.cancelled,
    orElse: () => ClassSession(
      id: '',
      subjectId: '',
      date: DateTime(0),
      status: AttendanceStatus.unmarked,
    ),
  );

  return cancelledSession.id.isNotEmpty;
}
