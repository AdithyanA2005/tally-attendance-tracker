import 'package:hive/hive.dart';

part 'session_model.g.dart';

@HiveType(typeId: 3)
enum AttendanceStatus {
  @HiveField(0)
  present,
  @HiveField(1)
  absent,
  @HiveField(2)
  cancelled,
  @HiveField(3)
  scheduled,
}

@HiveType(typeId: 2)
class ClassSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String subjectId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  AttendanceStatus status;

  @HiveField(4)
  final bool isExtraClass;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  final int durationMinutes;

  @HiveField(7)
  final DateTime lastUpdated;

  @HiveField(8, defaultValue: false)
  final bool hasPendingSync;

  @HiveField(9, defaultValue: '')
  final String semesterId;

  ClassSession({
    required this.id,
    required this.subjectId,
    required this.semesterId,
    required this.date,
    this.status = AttendanceStatus.scheduled,
    this.isExtraClass = false,
    this.notes,
    required this.durationMinutes,
    DateTime? lastUpdated,
    this.hasPendingSync = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory ClassSession.fromJson(Map<String, dynamic> json) {
    return ClassSession(
      id: json['id'],
      subjectId: json['subject_id'],
      semesterId: json['semester_id'] ?? '',
      date: DateTime.parse(json['date']),
      status: AttendanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AttendanceStatus.scheduled,
      ),
      isExtraClass: json['is_extra_class'] ?? false,
      notes: json['notes'],
      durationMinutes: json['duration_minutes'] ?? 0,
      lastUpdated: DateTime.parse(json['updated_at']),
      hasPendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'semester_id': semesterId,
      'date': date.toIso8601String(),
      'status': status.name,
      'is_extra_class': isExtraClass,
      'notes': notes,
      'duration_minutes': durationMinutes,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  ClassSession copyWith({
    String? id,
    String? subjectId,
    String? semesterId,
    DateTime? date,
    AttendanceStatus? status,
    bool? isExtraClass,
    String? notes,
    int? durationMinutes,
    DateTime? lastUpdated,
    bool? hasPendingSync,
  }) {
    return ClassSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      semesterId: semesterId ?? this.semesterId,
      date: date ?? this.date,
      status: status ?? this.status,
      isExtraClass: isExtraClass ?? this.isExtraClass,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
    );
  }
}
