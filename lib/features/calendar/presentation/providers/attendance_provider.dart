import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attendance_repository.dart';
import 'package:tally/core/data/models/subject_model.dart';
import 'package:tally/core/data/models/session_model.dart';
import '../../domain/attendance_calculator.dart';
import '../../domain/entities/subject_stats.dart';

// Stream of all subjects
final subjectsStreamProvider = StreamProvider<List<Subject>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchSubjects();
});

// Stream of all sessions (Reactive)
final allSessionsStreamProvider = StreamProvider<List<ClassSession>>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchAllSessions();
});

// Stream of stats for all subjects (Reactive)
final subjectStatsListProvider = Provider<AsyncValue<List<SubjectStats>>>((
  ref,
) {
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  final sessionsAsync = ref.watch(allSessionsStreamProvider);

  if (subjectsAsync.isLoading || sessionsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (subjectsAsync.hasError) {
    return AsyncValue.error(subjectsAsync.error!, subjectsAsync.stackTrace!);
  }

  if (sessionsAsync.hasError) {
    return AsyncValue.error(sessionsAsync.error!, sessionsAsync.stackTrace!);
  }

  final subjects = subjectsAsync.value ?? [];
  final allSessions = sessionsAsync.value ?? [];

  return AsyncValue.data(
    subjects.map((subject) {
      // Filter sessions for this subject in-memory (Reactive)
      final sessions = allSessions
          .where((s) => s.subjectId == subject.id)
          .toList();

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
      final prediction = AttendanceCalculator.predictAttendanceIfAttended(
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
    }).toList(),
  );
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
