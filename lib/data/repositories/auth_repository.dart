import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedDisplayName = displayName?.trim();
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: normalizedDisplayName != null && normalizedDisplayName.isNotEmpty
          ? <String, dynamic>{'display_name': normalizedDisplayName}
          : null,
    );

    if (response.user == null && response.session == null) {
      throw AuthException(
        'Authentication failed. Please try again.',
      );
    }

    return response;
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final hasValidUser =
        response.user != null || _client.auth.currentUser != null;
    final hasValidSession = response.session != null;
    if (!hasValidUser && !hasValidSession) {
      throw AuthException(
        'Authentication failed. Please try again.',
      );
    }

    return response;
  }

  Future<void> signOut() => _client.auth.signOut();
}
