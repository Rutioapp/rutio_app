import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Native iOS Sign in with Apple boundary. It deliberately has no routing or
/// onboarding knowledge; Supabase remains the session authority.
abstract interface class AppleAuthAdapter {
  Future<bool> isAvailable();
  Future<AuthResponse> signIn({String context = 'login'});
}

class NativeAppleAuthAdapter implements AppleAuthAdapter {
  NativeAppleAuthAdapter({SupabaseClient? supabaseClient})
      : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabaseClient;

  @override
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;
    final available = await SignInWithApple.isAvailable();
    _log('availability_checked available=$available');
    return available;
  }

  @override
  Future<AuthResponse> signIn({String context = 'login'}) async {
    _log('start context=$context');
    if (!await isAvailable()) {
      throw const AppleAuthException(AppleAuthErrorCode.notAvailable);
    }

    final rawNonce = generateNonce();
    final hashedNonce = sha256.convert(rawNonce.codeUnits).toString();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      _log('native_credential_received');
      final idToken = credential.identityToken;
      _log('id_token_checked present=${idToken != null}');
      if (idToken == null || idToken.isEmpty) {
        throw const AppleAuthException(AppleAuthErrorCode.missingIdentityToken);
      }
      _log('supabase_exchange_started');
      try {
        final response = await _supabaseClient.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce,
        );
        _log(
            'supabase_exchange_succeeded hasSession=${response.session != null}');
        return response;
      } on AuthException catch (error) {
        _logSupabaseException(error);
        throw AppleAuthException(AppleAuthErrorCode.supabaseError,
            cause: error);
      }
    } on AppleAuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        _log('cancelled');
        throw AppleAuthException(AppleAuthErrorCode.cancelled, cause: error);
      }
      throw AppleAuthException(AppleAuthErrorCode.invalidCredential,
          cause: error);
    } on SignInWithAppleNotSupportedException catch (error) {
      throw AppleAuthException(AppleAuthErrorCode.notSupported, cause: error);
    } on SignInWithAppleException catch (error) {
      throw AppleAuthException(AppleAuthErrorCode.unexpected, cause: error);
    } catch (error) {
      throw AppleAuthException(AppleAuthErrorCode.unexpected, cause: error);
    }
  }

  static void _log(String event) {
    if (kDebugMode) debugPrint('[APPLE_AUTH] event=$event');
  }

  static void _logSupabaseException(AuthException error) {
    if (!kDebugMode) return;
    debugPrint('[APPLE_AUTH] event=supabase_exception '
        'statusCode=${error.statusCode ?? 'none'} '
        'code=${_sanitize(error.code) ?? 'none'} '
        'message=${_sanitize(error.message) ?? 'none'}');
  }

  static String? _sanitize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value
        .replaceAll(
            RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
                caseSensitive: false),
            '<redacted-email>')
        .replaceAll(
            RegExp(
                r'(token|nonce|authorization_code|client_secret)\s*[:=]\s*[^\s,;]+',
                caseSensitive: false),
            r'\$1=<redacted>');
  }
}

enum AppleAuthErrorCode {
  cancelled,
  notSupported,
  notAvailable,
  network,
  invalidCredential,
  missingIdentityToken,
  providerConfigurationError,
  supabaseError,
  unexpected,
}

class AppleAuthException implements Exception {
  const AppleAuthException(this.code, {this.cause});
  final AppleAuthErrorCode code;
  final Object? cause;
  @override
  String toString() => 'AppleAuthException.${code.name}';
}
