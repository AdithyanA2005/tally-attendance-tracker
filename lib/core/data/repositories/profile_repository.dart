import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tally/core/data/local_storage_service.dart';
import 'package:tally/core/data/models/user_profile_model.dart';
import 'package:tally/core/data/repositories/cache_repository.dart';
import 'package:tally/core/services/supabase_service.dart';

class ProfileRepository extends CacheRepository<UserProfile> {
  final LocalStorageService _localStorage;

  ProfileRepository(LocalStorageService localStorage, SupabaseClient supabase)
    : _localStorage = localStorage,
      super(
        box: localStorage.profileBox,
        supabase: supabase,
        tableName: 'profiles',
        fromJson: UserProfile.fromJson,
      ) {
    initSync();
  }

  @override
  String getId(UserProfile item) => item.id;

  /// Returns the current user's profile stream
  Stream<UserProfile?> watchProfile() {
    return stream.map((box) {
      // We assume the box contains the current user's profile
      // We can filter by auth.uid if needed, but RLS ensures we only get ours usually.
      // Or we can explicitly return the one matching curr user.
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      if (box.containsKey(userId)) {
        return box.get(userId);
      }
      // Fallback: return the first one found (if RLS restricts to 1)
      if (box.isNotEmpty) return box.getAt(0);
      return null;
    });
  }

  /// Synchronous helper
  UserProfile? getProfileSync() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;
    return box.get(userId);
  }

  Future<void> updateActiveSemester(String semesterId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Get current profile or create one (optimistically)
    var profile = box.get(userId);

    if (profile == null) {
      // Should exist if we are logged in and sync happened, but handle edge case
      profile = UserProfile(
        id: userId,
        email: supabase.auth.currentUser?.email,
        activeSemesterId: semesterId,
      );
    } else {
      profile = profile.copyWith(activeSemesterId: semesterId);
    }

    // Optimistic
    await saveLocal(profile);

    // Remote
    await supabase.from('profiles').upsert(profile.toJson());
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    ref.watch(localStorageServiceProvider),
    SupabaseService().client,
  );
});
