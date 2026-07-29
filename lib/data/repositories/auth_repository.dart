import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  AuthRepository({
    SupabaseClient? client,
    Stream<AuthState> Function()? authStateChangesProvider,
    User? Function()? currentUserProvider,
    Future<void> Function()? signOutProvider,
    Future<AuthResponse> Function({
      required String email,
      required String password,
    })? signInWithEmailPasswordProvider,
  })  : _client = client ??
            ((authStateChangesProvider != null || currentUserProvider != null)
                ? null
                : Supabase.instance.client),
        _authStateChangesProvider = authStateChangesProvider,
        _currentUserProvider = currentUserProvider,
        _signOutProvider = signOutProvider,
        _signInWithEmailPasswordProvider = signInWithEmailPasswordProvider;

  final SupabaseClient? _client;
  final Stream<AuthState> Function()? _authStateChangesProvider;
  final User? Function()? _currentUserProvider;
  final Future<void> Function()? _signOutProvider;
  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })? _signInWithEmailPasswordProvider;

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
    final provider = _signInWithEmailPasswordProvider;
    if (provider != null) {
      return provider(email: email, password: password);
    }
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

  Future<void> signOut() => _signOutProvider?.call() ?? _client!.auth.signOut();
}
