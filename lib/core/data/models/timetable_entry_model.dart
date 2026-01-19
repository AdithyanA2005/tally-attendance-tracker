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

  @HiveField(5, defaultValue: true)
  final bool isRecurring;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7, defaultValue: false)
  final bool hasPendingSync;

  @HiveField(8, defaultValue: '')
  final String semesterId;

  TimetableEntry({
    required this.id,
    required this.subjectId,
    required this.semesterId,
    required this.dayOfWeek,
    required this.startTime,
    required this.durationInHours,
    this.isRecurring = true,
    DateTime? lastUpdated,
    this.hasPendingSync = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    return TimetableEntry(
      id: json['id'],
      subjectId: json['subject_id'],
      semesterId: json['semester_id'] ?? '',
      dayOfWeek: json['day_of_week'],
      startTime: json['start_time'],
      durationInHours: (json['duration_hours'] as num).toDouble(),
      isRecurring: json['is_recurring'] ?? true,
      lastUpdated: DateTime.parse(json['updated_at']),
      hasPendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'semester_id': semesterId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'duration_hours': durationInHours,
      'is_recurring': isRecurring,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  TimetableEntry copyWith({
    String? id,
    String? subjectId,
    String? semesterId,
    int? dayOfWeek,
    String? startTime,
    double? durationInHours,
    bool? isRecurring,
    DateTime? lastUpdated,
    bool? hasPendingSync,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      durationInHours: durationInHours ?? this.durationInHours,
      isRecurring: isRecurring ?? this.isRecurring,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
    );
  }
}
