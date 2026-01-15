import 'package:hive/hive.dart';

part 'timetable_entry_model.g.dart';

@HiveType(typeId: 1)
class TimetableEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final int dayOfWeek; // 1 = Monday, 7 = Sunday

  @HiveField(3)
  final String startTime; // "HH:mm" format (24h)

  @HiveField(4)
  final double durationInHours;

  @HiveField(5)
  final bool isRecurring;

  TimetableEntry({
    required this.id,
    required this.subjectId,
    required this.dayOfWeek,
    required this.startTime,
    required this.durationInHours,
    this.isRecurring = true,
  });
}
