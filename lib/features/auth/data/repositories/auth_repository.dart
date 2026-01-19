import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/supabase_service.dart';

part 'auth_repository.g.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Current User Stream
  Stream<User?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map((event) => event.session?.user);

  User? get currentUser => _supabase.auth.currentUser;

  // Sign Up with Email
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: emailRedirectTo,
    );
  }

  // Sign In with Email
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepository(SupabaseService().client);
}

@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
}
