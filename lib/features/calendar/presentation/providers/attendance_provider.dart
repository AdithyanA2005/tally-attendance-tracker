import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/session_model.dart';
import '../../domain/attendance_calculator.dart';
import '../../domain/entities/subject_stats.dart';

// Stream of all subjects
final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchSubjects();
});

// Stream of stats for all subjects
final subjectStatsListProvider = Provider<AsyncValue<List<SubjectStats>>>((
  ref,
) {
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final repository = ref.watch(attendanceRepositoryProvider);

  return subjectsAsync.whenData((subjects) {
    return subjects.map((subject) {
      final sessions = repository.getSessions(subject.id);

      int present = 0;
      int absent = 0;
      int conducted = 0;

      for (var session in sessions) {
        if (session.status == AttendanceStatus.present) {
          present++;
          conducted++;
        } else if (session.status == AttendanceStatus.absent) {
          absent++;
          conducted++;
        }
        // Cancelled/Unmarked don't count towards conducted/present math in this specific model
        // Prompt says: Conducted = Present + Absent. Cancelled DO NOT count.
      }

      final percentage = AttendanceCalculator.calculatePercentage(
        present,
        conducted,
      );
      final needed = AttendanceCalculator.calculateClassesNeededToReachTarget(
        present,
        conducted,
        subject.minimumAttendancePercentage,
      );
      final skippable = AttendanceCalculator.calculateMaxSkippableClasses(
        present,
        conducted,
        subject.minimumAttendancePercentage,
      );
      final prediction = AttendanceCalculator.predictAttendanceIfSkipped(
        present,
        conducted,
      );

      return SubjectStats(
        subject: subject,
        conducted: conducted,
        present: present,
        absent: absent,
        percentage: percentage,
        classesNeededFor75: needed,
        classesSkippable: skippable,
        isSafe: percentage >= subject.minimumAttendancePercentage,
        predictionNextClass: prediction,
        history: sessions,
      );
    }).toList();
  });
});

final subjectStatsFamily = Provider.family<AsyncValue<SubjectStats?>, String>((
  ref,
  subjectId,
) {
  final statsList = ref.watch(subjectStatsListProvider);
  return statsList.whenData((stats) {
    try {
      return stats.firstWhere((s) => s.subject.id == subjectId);
    } catch (_) {
      return null;
    }
  });
});
