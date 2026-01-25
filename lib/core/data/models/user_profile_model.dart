import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 5)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? email;

  @HiveField(2)
  final String? activeSemesterId;

  @HiveField(3)
  final DateTime lastUpdated;

  @HiveField(4, defaultValue: false)
  final bool hasPendingSync;

  @HiveField(5)
  final String? name;

  @HiveField(6)
  final String? photoUrl;

  UserProfile({
    required this.id,
    this.email,
    this.activeSemesterId,
    DateTime? lastUpdated,
    this.hasPendingSync = false,
    this.name,
    this.photoUrl,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      activeSemesterId: json['active_semester_id'],
      lastUpdated: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      hasPendingSync: false,
      name: json['full_name'],
      photoUrl: json['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // 'email': email, // Email resides in auth.users, do not duplicate in profiles
      'active_semester_id': activeSemesterId,
      'updated_at': lastUpdated.toIso8601String(),
      'full_name': name,
      'avatar_url': photoUrl,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? activeSemesterId,
    DateTime? lastUpdated,
    bool? hasPendingSync,
    String? name,
    String? photoUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      activeSemesterId: activeSemesterId ?? this.activeSemesterId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasPendingSync: hasPendingSync ?? this.hasPendingSync,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
