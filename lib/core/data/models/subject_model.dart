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

  @HiveField(5)
  final DateTime lastUpdated;

  @HiveField(6, defaultValue: false)
  final bool hasPendingSync;

  @HiveField(7, defaultValue: '')
  final String semesterId;

  Subject({
    required this.id,
    required this.name,
    required this.minimumAttendancePercentage,
    required this.weeklyHours,
    required this.colorTag,
    required this.semesterId,
    DateTime? lastUpdated,
    this.hasPendingSync = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      minimumAttendancePercentage:
          (json['minimum_attendance_percentage'] as num).toDouble(),
      weeklyHours: json['weekly_hours'],
      colorTag: json['color_tag'],
      semesterId: json['semester_id'] ?? '',
      lastUpdated: DateTime.parse(json['updated_at']),
      hasPendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'semester_id': semesterId,
      'name': name,
      'minimum_attendance_percentage': minimumAttendancePercentage,
      'weekly_hours': weeklyHours,
      'color_tag': colorTag,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  Color get color => Color(colorTag);

  Subject copyWith({
    String? id,
    String? name,
    double? minimumAttendancePercentage,
    int? weeklyHours,
    int? colorTag,
    DateTime? lastUpdated,
    bool? hasPendingSync,
    String? semesterId,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      minimumAttendancePercentage:
          minimumAttendancePercentage ?? this.minimumAttendancePercentage,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      colorTag: colorTag ?? this.colorTag,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      semesterId: semesterId ?? this.semesterId,
    );
  }
}
