import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({
    SupabaseClient? client,
    Stream<AuthState> Function()? authStateChangesProvider,
    User? Function()? currentUserProvider,
  })  : _client = client ??
            ((authStateChangesProvider != null || currentUserProvider != null)
                ? null
                : Supabase.instance.client),
        _authStateChangesProvider = authStateChangesProvider,
        _currentUserProvider = currentUserProvider;

  final SupabaseClient? _client;
  final Stream<AuthState> Function()? _authStateChangesProvider;
  final User? Function()? _currentUserProvider;

  Stream<AuthState> get authStateChanges =>
      _authStateChangesProvider?.call() ??
      (_client?.auth.onAuthStateChange ?? const Stream<AuthState>.empty());

  User? get currentUser {
    if (_currentUserProvider != null) {
      return _currentUserProvider!();
    }
    return _client?.auth.currentUser;
  }

  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedDisplayName = displayName?.trim();
    final response = await _client!.auth.signUp(
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
    final response = await _client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final hasValidUser =
        response.user != null || _client!.auth.currentUser != null;
    final hasValidSession = response.session != null;
    if (!hasValidUser && !hasValidSession) {
      throw AuthException(
        'Authentication failed. Please try again.',
      );
    }

    return response;
  }

  Future<void> signOut() => _client!.auth.signOut();
}
