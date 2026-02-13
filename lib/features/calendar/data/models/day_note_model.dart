import 'package:hive/hive.dart';
import '../../../../core/data/models/syncable_model.dart';

part 'day_note_model.g.dart';

@HiveType(typeId: 6)
class DayNote extends SyncableModel {
  @override
  String get id => dateIso;

  @override
  DateTime get lastUpdated => updatedAt;

  @HiveField(0)
  final String dateIso; // Key: yyyy-MM-dd

  @HiveField(1)
  final String content;

  @HiveField(2)
  final DateTime updatedAt;

  @override
  @HiveField(3, defaultValue: false)
  final bool hasPendingSync;

  DayNote({
    required this.dateIso,
    required this.content,
    required this.updatedAt,
    this.hasPendingSync = false,
  });

  DayNote copyWith({
    String? content,
    DateTime? updatedAt,
    bool? hasPendingSync,
  }) {
    return DayNote(
      dateIso: dateIso,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
    );
  }

  factory DayNote.fromJson(Map<String, dynamic> json) {
    return DayNote(
      dateIso: json['date_iso'],
      content: json['content'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
      hasPendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date_iso': dateIso,
      'content': content,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
