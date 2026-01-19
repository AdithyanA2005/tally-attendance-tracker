import 'package:hive/hive.dart';

part 'semester_model.g.dart';

@HiveType(typeId: 4)
class Semester extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime startDate;

  @HiveField(3)
  final bool isActive;

  @HiveField(4)
  final DateTime lastUpdated;

  @HiveField(5, defaultValue: false)
  final bool hasPendingSync;

  Semester({
    required this.id,
    required this.name,
    required this.startDate,
    this.isActive = false,
    DateTime? lastUpdated,
    this.hasPendingSync = false,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory Semester.fromJson(Map<String, dynamic> json) {
    return Semester(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['start_date']),
      isActive: json['is_active'] ?? false,
      lastUpdated: DateTime.parse(json['updated_at']),
      hasPendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_date': startDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'updated_at': lastUpdated.toIso8601String(),
    };
  }

  Semester copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    bool? isActive,
    DateTime? lastUpdated,
    bool? hasPendingSync,
  }) {
    return Semester(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      isActive: isActive ?? this.isActive,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
    );
  }
}
