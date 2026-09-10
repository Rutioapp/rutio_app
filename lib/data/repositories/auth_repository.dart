import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_config.dart';
import '../../features/auth/infrastructure/google_auth_adapter.dart';

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
    Future<void> Function({required String email})? resendConfirmationProvider,
    Future<AuthResponse> Function()? refreshSessionProvider,
    Future<void> Function({required String email})?
        resetPasswordForEmailProvider,
    Future<UserResponse> Function({required String password})?
        updatePasswordProvider,
    GoogleAuthAdapter? googleAuthAdapter,
    Future<void> Function()? googleSignOutProvider,
  })  : _client = client ??
            ((authStateChangesProvider != null || currentUserProvider != null)
                ? null
                : Supabase.instance.client),
        _authStateChangesProvider = authStateChangesProvider,
        _currentUserProvider = currentUserProvider,
        _signOutProvider = signOutProvider,
        _signInWithEmailPasswordProvider = signInWithEmailPasswordProvider,
        _resendConfirmationProvider = resendConfirmationProvider,
        _refreshSessionProvider = refreshSessionProvider,
        _resetPasswordForEmailProvider = resetPasswordForEmailProvider,
        _updatePasswordProvider = updatePasswordProvider,
        _googleAuthAdapter = googleAuthAdapter,
        _googleSignOutProvider = googleSignOutProvider;

  final SupabaseClient? _client;
  final Stream<AuthState> Function()? _authStateChangesProvider;
  final User? Function()? _currentUserProvider;
  final Future<void> Function()? _signOutProvider;
  final Future<AuthResponse> Function({
    required String email,
    required String password,
  })? _signInWithEmailPasswordProvider;
  final Future<void> Function({required String email})?
      _resendConfirmationProvider;
  final Future<AuthResponse> Function()? _refreshSessionProvider;
  final Future<void> Function({required String email})?
      _resetPasswordForEmailProvider;
  final Future<UserResponse> Function({required String password})?
      _updatePasswordProvider;
  final GoogleAuthAdapter? _googleAuthAdapter;
  final Future<void> Function()? _googleSignOutProvider;

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
    String? emailRedirectTo,
  }) async {
    final normalizedDisplayName = displayName?.trim();
    final response = await _client!.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: emailRedirectTo ?? RutioSupabaseConfig.authCallbackUri,
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

  Future<void> signOut() async {
    await (_signOutProvider?.call() ?? _client!.auth.signOut());
    try {
      await (_googleSignOutProvider?.call() ?? _googleAuthAdapter?.signOut());
    } catch (_) {
      // Supabase logout is authoritative; provider cleanup is best effort.
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    final adapter = _googleAuthAdapter;
    if (adapter == null) {
      throw const GoogleAuthException(GoogleAuthErrorCode.configurationError);
    }
    return adapter.signIn();
  }

  Future<void> resendConfirmation({required String email}) async {
    final provider = _resendConfirmationProvider;
    if (provider != null) return provider(email: email.trim());
    await _client!.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: RutioSupabaseConfig.authCallbackUri,
    );
  }

  Future<AuthResponse> refreshSession() =>
      _refreshSessionProvider?.call() ?? _client!.auth.refreshSession();

  Future<void> resetPasswordForEmail({required String email}) async {
    final provider = _resetPasswordForEmailProvider;
    if (provider != null) return provider(email: email.trim());
    await _client!.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: RutioSupabaseConfig.authCallbackUri,
    );
  }

  Future<UserResponse> updatePassword({required String password}) {
    final provider = _updatePasswordProvider;
    if (provider != null) return provider(password: password);
    return _client!.auth.updateUser(UserAttributes(password: password));
  }
}
