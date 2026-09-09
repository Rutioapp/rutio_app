import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/diagnostics/onboarding_runtime_trace.dart';
import '../application/auth_callback_coordinator.dart';
import '../domain/auth_callback_failure.dart';
import '../domain/auth_callback_intent.dart';

/// The only application entry point for production auth deep links.
///
/// App Links/Universal Links deliver URIs here for cold, warm and background
/// launches. This class never navigates and never persists the URI.
class AuthDeepLinkReceiver {
  AuthDeepLinkReceiver({AppLinks? appLinks})
      : _appLinks = appLinks ?? AppLinks(),
        coordinator = AuthCallbackCoordinator(
          sessionPort: _SupabaseAuthCallbackSessionPort(),
        );

  final AppLinks _appLinks;
  final AuthCallbackCoordinator coordinator;
  StreamSubscription<Uri>? _subscription;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => unawaited(_deliver(uri, isColdStart: false)),
      onError: (Object error, StackTrace stackTrace) {
        _log('event=failed result=runtime_uri_error');
        if (kDebugMode) debugPrint('[AUTH_DEEP_LINK] receiver error: $error');
      },
    );

    // app_links emits the initial URI on mobile through the same stream, but
    // getInitialLink is also needed for platforms/configurations where it is
    // exposed separately. Coordinator dedupe makes both deliveries safe.
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _deliver(initialUri, isColdStart: true);
      }
    } catch (_) {
      _log('event=failed result=initial_uri_error');
    }
  }

  Future<AuthCallbackResult> _deliver(
    Uri uri, {
    required bool isColdStart,
  }) async {
    _log(
      'event=${isColdStart ? 'initial_uri_received' : 'runtime_uri_received'} '
      'isColdStart=$isColdStart',
    );
    final result = await coordinator.receive(uri, isColdStart: isColdStart);
    final intent = result.intent;
    _log(
      'event=${_eventName(result.kind)} '
      'callbackType=${intent?.type.name ?? 'unknown'} '
      'isColdStart=$isColdStart hasSession=${result.hasSession} '
      'result=${result.failure?.type.name ?? result.kind.name}',
    );
    return result;
  }

  String _eventName(AuthCallbackResultKind kind) {
    switch (kind) {
      case AuthCallbackResultKind.duplicateIgnored:
        return 'duplicate_ignored';
      case AuthCallbackResultKind.failed:
        return 'failed';
      case AuthCallbackResultKind.completed:
        return 'completed';
      case AuthCallbackResultKind.queued:
        return 'queued';
      case AuthCallbackResultKind.unsupported:
      case AuthCallbackResultKind.malformed:
        return 'failed';
    }
  }

  void _log(String message) {
    OnboardingRuntimeTrace.log('AUTH_DEEP_LINK', message);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}

class _SupabaseAuthCallbackSessionPort implements AuthCallbackSessionPort {
  @override
  Future<AuthCallbackSessionResult> processCallback(
    AuthCallbackIntent intent,
    Uri uri,
  ) async {
    OnboardingRuntimeTrace.log(
      'AUTH_CALLBACK',
      'event=supabase_processing_started callbackType=${intent.type.name} '
          'isColdStart=${intent.isColdStart}',
    );
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } on AuthException catch (error) {
      if (_isExpiredOrInvalid(error.message)) {
        throw const AuthCallbackFailure(
          AuthCallbackFailureType.expiredOrInvalidCallback,
        );
      }
      rethrow;
    }
    final user = Supabase.instance.client.auth.currentUser;
    OnboardingRuntimeTrace.log(
      'AUTH_CALLBACK',
      'event=session_established callbackType=${intent.type.name} '
          'hasSession=${user != null}',
    );
    return AuthCallbackSessionResult(
      userId: user?.id,
      hasSession: user != null,
    );
  }

  bool _isExpiredOrInvalid(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('expired') ||
        normalized.contains('invalid') ||
        normalized.contains('already used') ||
        normalized.contains('otp');
  }
}
