import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/attendance/data/repositories/attendance_repository.dart';
import '../../data/models/timetable_entry_model.dart';

final timetableProvider = StreamProvider.family<List<TimetableEntry>, int?>((
  ref,
  dayOfWeek,
) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.watchTimetable(dayOfWeek: dayOfWeek);
});
