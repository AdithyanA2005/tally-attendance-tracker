import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/domain/entities/subject_stats.dart';

class InsightStats {
  final double overallPercentage;
  final SubjectStats? mostRiskySubject;
  final SubjectStats? safestSubject;
  final int totalClassesSkippable;
  final int totalClassesNeeded;
  final List<SubjectStats> subjectStats;

  InsightStats({
    required this.overallPercentage,
    this.mostRiskySubject,
    this.safestSubject,
    required this.totalClassesSkippable,
    required this.totalClassesNeeded,
    required this.subjectStats,
  });
}

final insightsProvider = Provider<AsyncValue<InsightStats>>((ref) {
  final statsAsync = ref.watch(subjectStatsListProvider);

  return statsAsync.whenData((stats) {
    if (stats.isEmpty) {
      return InsightStats(
        overallPercentage: 100,
        totalClassesSkippable: 0,
        totalClassesNeeded: 0,
        subjectStats: [],
      );
    }

    int totalPresent = 0;
    int totalConducted = 0;
    int totalSkippable = 0;
    int totalNeeded = 0;

    SubjectStats? risky;
    SubjectStats? safe;

    for (var s in stats) {
      totalPresent += s.present;
      totalConducted += s.conducted;
      totalSkippable += s.classesSkippable;
      totalNeeded += s.classesNeededFor75;

      // Determine risky (lowest percentage)
      if (risky == null || s.percentage < risky.percentage) {
        risky = s;
      }
      // Determine safe (highest percentage)
      if (safe == null || s.percentage > safe.percentage) {
        safe = s;
      }
    }

    final overall = totalConducted == 0
        ? 100.0
        : (totalPresent / totalConducted) * 100;

    return InsightStats(
      overallPercentage: overall,
      mostRiskySubject: risky,
      safestSubject: safe,
      totalClassesSkippable: totalSkippable,
      totalClassesNeeded: totalNeeded,
      subjectStats: stats,
    );
  });
});
