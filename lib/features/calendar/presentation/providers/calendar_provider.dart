import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tally/core/data/models/session_model.dart';
import 'package:tally/core/data/models/subject_model.dart';

import 'attendance_provider.dart';

final calendarEventsProvider =
    Provider<AsyncValue<Map<DateTime, List<ClassSession>>>>((ref) {
      final sessionsAsync = ref.watch(allSessionsStreamProvider);

      return sessionsAsync.whenData((sessions) {
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

        // Sort each day's sessions by time
        for (var dayEvents in events.values) {
          dayEvents.sort((a, b) => a.date.compareTo(b.date));
        }

        return events;
      });
    });

// Helper to get subjects map synchronously/easily (Reactive)
final allSubjectsMapProvider = Provider<Map<String, Subject>>((ref) {
  final subjectsAsync = ref.watch(subjectsStreamProvider);
  // Default to empty map if loading/error, or handle better?
  // Screens using this usually expect a Map.
  // If we return Map<String, Subject>, we must handle async state.
  // But previously it was non-reactive getSubjects().

  // Safe approach: return existing value or empty.
  return subjectsAsync.maybeWhen(
    data: (subjects) => {for (var s in subjects) s.id: s},
    orElse: () => {},
  );
});
