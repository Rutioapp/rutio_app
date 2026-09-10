import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/rutio_supabase_config.dart';

/// Boundary for the native provider. It is injectable so auth flows can be
/// tested without opening a platform account picker.
abstract interface class GoogleAuthAdapter {
  Future<AuthResponse> signIn();

  Future<void> signOut();
}

class NativeGoogleAuthAdapter implements GoogleAuthAdapter {
  NativeGoogleAuthAdapter({GoogleSignIn? client, SupabaseClient? supabaseClient})
      : _client = client,
        _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final GoogleSignIn? _client;
  final SupabaseClient _supabaseClient;
  GoogleSignIn? _initializedClient;
  Future<void>? _initialization;

  GoogleSignIn get _googleSignIn => _client ?? GoogleSignIn.instance;

  Future<void> _ensureInitialized() {
    final existing = _initialization;
    if (existing != null) return existing;
    final client = _googleSignIn;
    final future = client.initialize(
      clientId: RutioSupabaseConfig.googleIosClientIdOrNull,
      serverClientId: RutioSupabaseConfig.googleWebClientIdOrNull,
    );
    _initializedClient = client;
    _initialization = future;
    return future;
  }

  @override
  Future<AuthResponse> signIn() async {
    try {
      await _ensureInitialized();
      final client = _initializedClient ?? _googleSignIn;
      if (!client.supportsAuthenticate()) {
        throw const GoogleAuthException(GoogleAuthErrorCode.providerUnavailable);
      }
      final account = await client.authenticate();
      _logEvent('native_account_received');
      final idToken = account.authentication.idToken;
      _logEvent('id_token_checked', present: idToken != null);
      if (idToken == null) {
        throw const GoogleAuthException(GoogleAuthErrorCode.invalidCredential);
      }
      _logEvent('authorization_started');
      final authorization = await account.authorizationClient.authorizeScopes(
        const <String>['openid', 'email', 'profile'],
      );
      _logEvent('access_token_checked', present: authorization.accessToken.isNotEmpty);
      _logEvent('supabase_exchange_started');
      try {
        final response = await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: authorization.accessToken,
        );
        _logEvent(
          'supabase_exchange_succeeded',
          hasSession: response.session != null,
        );
        return response;
      } on AuthException catch (error) {
        _logSupabaseException(error);
        rethrow;
      }
    } on GoogleAuthException {
      rethrow;
    } on GoogleSignInException catch (error) {
      _logNativeException(error);
      final code = error.code == GoogleSignInExceptionCode.canceled
          ? GoogleAuthErrorCode.cancelled
          : error.code == GoogleSignInExceptionCode.clientConfigurationError
              ? GoogleAuthErrorCode.configurationError
              : GoogleAuthErrorCode.unexpected;
      throw GoogleAuthException(code, cause: error);
    }
  }

  static void _logEvent(
    String event, {
    bool? present,
    bool? hasSession,
  }) {
    if (!kDebugMode) return;
    final fields = <String>[
      '[GOOGLE_AUTH] event=$event',
      if (present != null) 'present=$present',
      if (hasSession != null) 'hasSession=$hasSession',
    ];
    debugPrint(fields.join(' '));
  }

  static void _logSupabaseException(AuthException error) {
    if (!kDebugMode) return;
    debugPrint(
      '[GOOGLE_AUTH] event=supabase_exception '
      'statusCode=${error.statusCode ?? 'none'} '
      'code=${_sanitizeDescription(error.code) ?? 'none'} '
      'message=${_sanitizeDescription(error.message) ?? 'none'}',
    );
  }

  static void _logNativeException(GoogleSignInException error) {
    if (!kDebugMode) return;
    final description = _sanitizeDescription(error.description);
    debugPrint(
      '[GOOGLE_AUTH] event=native_exception '
      'code=${error.code.name} '
      'description=${description ?? 'none'} '
      'detailsType=${error.details.runtimeType}',
    );
  }

  static String? _sanitizeDescription(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value
        .replaceAll(
          RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
          '<redacted-email>',
        )
        .replaceAll(
          RegExp(
            r'(id_token|access_token|refresh_token|server_auth_code|client_secret|authorization_code|bearer)\s*[:=]\s*[^\s,;]+',
            caseSensitive: false,
          ),
          r'$1=<redacted>',
        )
        .replaceAll(
          RegExp(
            r'ey[a-z0-9_-]{20,}\.[a-z0-9_-]{10,}\.[a-z0-9_-]{10,}',
            caseSensitive: false,
          ),
          '<redacted-token>',
        );
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await (_initializedClient ?? _googleSignIn).signOut();
  }
}

enum GoogleAuthErrorCode {
  cancelled,
  network,
  providerUnavailable,
  configurationError,
  invalidCredential,
  accountConflict,
  unexpected,
}

class GoogleAuthException implements Exception {
  const GoogleAuthException(this.code, {this.cause});

  final GoogleAuthErrorCode code;
  final Object? cause;

  @override
  String toString() => 'GoogleAuthException.${code.name}';
}
