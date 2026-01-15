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
  unmarked,
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

  ClassSession({
    required this.id,
    required this.subjectId,
    required this.date,
    this.status = AttendanceStatus.unmarked,
    this.isExtraClass = false,
    this.notes,
  });

  ClassSession copyWith({
    String? id,
    String? subjectId,
    DateTime? date,
    AttendanceStatus? status,
    bool? isExtraClass,
    String? notes,
  }) {
    return ClassSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      status: status ?? this.status,
      isExtraClass: isExtraClass ?? this.isExtraClass,
      notes: notes ?? this.notes,
    );
  }
}
