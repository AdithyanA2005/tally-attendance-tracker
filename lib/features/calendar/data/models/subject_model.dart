import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'subject_model.g.dart';

@HiveType(typeId: 0)
class Subject extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double minimumAttendancePercentage;

  @HiveField(3)
  final int weeklyHours;

  @HiveField(4)
  final int colorTag; // Storing int value of Color

  Subject({
    required this.id,
    required this.name,
    this.minimumAttendancePercentage = 75.0,
    required this.weeklyHours,
    required this.colorTag,
  });

  Color get color => Color(colorTag);

  Subject copyWith({
    String? id,
    String? name,
    double? minimumAttendancePercentage,
    int? weeklyHours,
    int? colorTag,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      minimumAttendancePercentage:
          minimumAttendancePercentage ?? this.minimumAttendancePercentage,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      colorTag: colorTag ?? this.colorTag,
    );
  }
}
