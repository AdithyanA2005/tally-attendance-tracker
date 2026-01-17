import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';
import '../../../calendar/presentation/providers/attendance_provider.dart';
import '../../../calendar/domain/entities/subject_stats.dart';
import '../../data/models/attendance_anomaly.dart';

final attendanceAnomaliesProvider = Provider<List<SubjectAnomalySummary>>((
  ref,
) {
  final sessionsAsync = ref.watch(allSessionsStreamProvider);
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final statsAsync = ref.watch(subjectStatsListProvider);

  if (sessionsAsync.isLoading ||
      subjectsAsync.isLoading ||
      statsAsync.isLoading) {
    return [];
  }

  final sessions = sessionsAsync.value ?? [];
  final subjects = subjectsAsync.value ?? [];
  final stats = statsAsync.value ?? [];

  if (sessions.isEmpty || subjects.isEmpty) {
    return [];
  }

  return _detectAnomalies(sessions, subjects, stats);
});

List<SubjectAnomalySummary> _detectAnomalies(
  List<ClassSession> sessions,
  List<Subject> subjects,
  List<SubjectStats> allStats,
) {
  final subjectMap = {for (var s in subjects) s.id: s};
  final statsMap = {for (var s in allStats) s.subject.id: s};
  final anomaliesBySubject = <String, List<AttendanceAnomaly>>{};

  // Group sessions by date
  final sessionsByDate = <DateTime, List<ClassSession>>{};
  for (var session in sessions) {
    final dateKey = DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
    );
    sessionsByDate.putIfAbsent(dateKey, () => []).add(session);
  }

  // Detect anomalies for each date
  for (var entry in sessionsByDate.entries) {
    final date = entry.key;
    final daySessions = entry.value;

    // Need at least 2 classes to detect anomaly
    if (daySessions.length < 2) continue;

    final presentSessions = daySessions
        .where((s) => s.status == AttendanceStatus.present)
        .toList();
    final absentSessions = daySessions
        .where((s) => s.status == AttendanceStatus.absent)
        .toList();

    // Anomaly: some present AND some absent on same day
    if (presentSessions.isNotEmpty && absentSessions.isNotEmpty) {
      // Create anomaly for each absent subject
      for (var absentSession in absentSessions) {
        final subject = subjectMap[absentSession.subjectId];
        final stats = statsMap[absentSession.subjectId];

        if (subject == null || stats == null) continue;

        // Use stats for calculation consistency
        final currentPercentage = stats.percentage;
        final conducted = stats.conducted;

        // Potential: +1 present, same conducted (absent -> present)
        final potentialPresent = stats.present + 1;
        final potentialPercentage = conducted > 0
            ? (potentialPresent / conducted) * 100
            : 0.0;

        final impact = potentialPercentage - currentPercentage;

        final anomaly = AttendanceAnomaly(
          subject: subject,
          date: date,
          presentClasses: presentSessions,
          absentClasses: [absentSession],
          totalClasses: conducted,
          presentCount: stats.present,
          currentPercentage: currentPercentage,
          potentialPercentage: potentialPercentage,
          impactPercentage: impact,
        );

        anomaliesBySubject.putIfAbsent(subject.id, () => []).add(anomaly);
      }
    }
  }

  // Create summary for each subject with anomalies
  final summaries = <SubjectAnomalySummary>[];
  for (var entry in anomaliesBySubject.entries) {
    final subjectId = entry.key;
    final anomalies = entry.value;
    final subject = subjectMap[subjectId];
    final stats = statsMap[subjectId];

    if (subject == null || anomalies.isEmpty || stats == null) continue;

    final currentPercentage = stats.percentage;
    final conducted = stats.conducted;

    if (conducted == 0) continue;

    // Potential calculation:
    // If anomalies were errors, they should have been present instead of absent.
    // So numerator increases by anomalies.length.
    // Denominator (conducted) stays the same because absent -> present doesn't change total conducted.
    final potentialPresent = stats.present + anomalies.length;
    final potentialPercentage = (potentialPresent / conducted) * 100;

    final totalImpact = potentialPercentage - currentPercentage;

    summaries.add(
      SubjectAnomalySummary(
        subject: subject,
        anomalies: anomalies
          ..sort((a, b) => b.date.compareTo(a.date)), // Most recent first
        currentPercentage: currentPercentage,
        potentialPercentage: potentialPercentage,
        impactPercentage: totalImpact,
        totalAnomalies: anomalies.length,
      ),
    );
  }

  // Sort by impact (highest first)
  summaries.sort((a, b) => b.impactPercentage.compareTo(a.impactPercentage));

  return summaries;
}
