import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/calendar/data/repositories/attendance_repository.dart';
import 'package:tally/core/data/models/timetable_entry_model.dart';
import '../../data/repositories/semester_repository.dart';

final timetableProvider = StreamProvider.family<List<TimetableEntry>, int?>((
  ref,
  dayOfWeek,
) {
  final activeSemester = ref.watch(activeSemesterProvider);
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchTimetable(
    dayOfWeek: dayOfWeek,
    semesterId: activeSemester.value?.id,
  );
});
