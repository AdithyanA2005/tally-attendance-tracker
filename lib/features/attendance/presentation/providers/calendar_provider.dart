import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/models/session_model.dart';
import '../../data/models/subject_model.dart';

final calendarEventsProvider =
    StreamProvider<Map<DateTime, List<ClassSession>>>((ref) {
      final repository = ref.watch(attendanceRepositoryProvider);

      return repository.watchAllSessions().map((sessions) {
        final Map<DateTime, List<ClassSession>> events = {};
        for (var session in sessions) {
          final dateKeys = DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          );
          if (events[dateKeys] == null) {
            events[dateKeys] = [];
          }
          events[dateKeys]!.add(session);
        }
        return events;
      });
    });

// Helper to get subjects map synchronously/easily
final allSubjectsMapProvider = Provider<Map<String, Subject>>((ref) {
  final subjects = ref.watch(attendanceRepositoryProvider).getSubjects();
  return {for (var s in subjects) s.id: s};
});
