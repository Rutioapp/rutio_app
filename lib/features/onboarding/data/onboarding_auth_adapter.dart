import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/remote/remote_profile.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/supabase/rutio_supabase_config.dart';
import '../../../core/diagnostics/onboarding_runtime_trace.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/repository_result.dart';
import '../domain/auth/onboarding_auth_contracts.dart';
import '../../auth/infrastructure/google_auth_adapter.dart';

/// AUTH-2 adapter. The onboarding flow depends on this boundary instead of
/// reaching into Supabase or duplicating the app's AuthController.
class RepositoryOnboardingAuthAdapter
    implements OnboardingAuthPort, OnboardingEmailConfirmationPort {
  const RepositoryOnboardingAuthAdapter(this._repository);

  final AuthRepository _repository;

  @override
  Future<OnboardingAuthAttemptResult> authenticate(
    OnboardingAuthRequest request,
  ) async {
    final password = request.password;
    if (password == null || password.isEmpty) {
      return const OnboardingAuthenticationFailed(
        OnboardingAuthError(OnboardingAuthErrorCode.weakPassword),
      );
    }
    try {
      final response = request.method == OnboardingAuthMethod.google
          ? await _repository.signInWithGoogle()
          : request.command == OnboardingAuthCommand.signUpWithEmail
          ? await _repository.signUpWithEmailPassword(
              email: request.email.trim(),
              password: password,
              emailRedirectTo: RutioSupabaseConfig.authCallbackUri,
            )
          : await _repository.signInWithEmailPassword(
              email: request.email.trim(),
              password: password,
            );
      if (response.session == null) {
        if (request.command == OnboardingAuthCommand.signUpWithEmail &&
            (response.user != null || _repository.currentUser != null)) {
          OnboardingRuntimeTrace.log(
            'EMAIL_CONFIRMATION',
            'event=fallback_entered reason=session_missing_after_signup',
          );
          return const OnboardingConfirmationRequired();
        }
        return const OnboardingAuthenticationFailed(
          OnboardingAuthError(OnboardingAuthErrorCode.sessionExpired),
        );
      }
      final user = response.session?.user ?? _repository.currentUser;
      if (user == null) {
        return const OnboardingAuthenticationFailed(
          OnboardingAuthError(OnboardingAuthErrorCode.sessionExpired),
        );
      }
      return OnboardingAuthenticated(
        AuthenticatedOnboardingSession(userId: user.id),
      );
    } on AuthException catch (error) {
      return OnboardingAuthenticationFailed(_mapAuthException(error));
    } on GoogleAuthException catch (error) {
      return OnboardingAuthenticationFailed(_mapGoogleException(error));
    } on SocketException catch (error) {
      return OnboardingAuthenticationFailed(
        OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error),
      );
    } catch (error) {
      return OnboardingAuthenticationFailed(
        OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error),
      );
    }
  }

  static OnboardingAuthError _mapGoogleException(GoogleAuthException error) {
    switch (error.code) {
      case GoogleAuthErrorCode.cancelled:
        return const OnboardingAuthError(OnboardingAuthErrorCode.providerCancelled);
      case GoogleAuthErrorCode.network:
        return OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
      case GoogleAuthErrorCode.providerUnavailable:
      case GoogleAuthErrorCode.configurationError:
        return OnboardingAuthError(OnboardingAuthErrorCode.providerFailure, cause: error);
      case GoogleAuthErrorCode.invalidCredential:
      case GoogleAuthErrorCode.accountConflict:
      case GoogleAuthErrorCode.unexpected:
        return OnboardingAuthError(OnboardingAuthErrorCode.providerFailure, cause: error);
    }
  }

  @override
  Future<void> resendConfirmation(String email) async {
    try {
      await _repository.resendConfirmation(email: email);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } on SocketException catch (error) {
      throw OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
    } catch (error) {
      throw OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
    }
  }

  @override
  Future<AuthenticatedOnboardingSession?> refreshConfirmedSession() async {
    try {
      final response = await _repository.refreshSession();
      final user = response.session?.user ?? _repository.currentUser;
      return user == null
          ? null
          : AuthenticatedOnboardingSession(userId: user.id);
    } on AuthException catch (error) {
      throw _mapAuthException(error);
    } on SocketException catch (error) {
      throw OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
    } catch (error) {
      throw OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
    }
  }

  static OnboardingAuthError _mapAuthException(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('already exists') ||
        message.contains('user already')) {
      return OnboardingAuthError(
        OnboardingAuthErrorCode.emailAlreadyRegistered,
        cause: error,
      );
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return OnboardingAuthError(OnboardingAuthErrorCode.resendRateLimited,
          cause: error);
    }
    if (message.contains('email')) {
      return OnboardingAuthError(OnboardingAuthErrorCode.invalidEmail,
          cause: error);
    }
    if (message.contains('weak')) {
      return OnboardingAuthError(
        OnboardingAuthErrorCode.weakPassword,
        cause: error,
      );
    }
    if (message.contains('invalid login') ||
        message.contains('invalid credentials') ||
        message.contains('password')) {
      return OnboardingAuthError(
        OnboardingAuthErrorCode.invalidCredentials,
        cause: error,
      );
    }
    if (message.contains('network') ||
        message.contains('timeout') ||
        message.contains('connection')) {
      return OnboardingAuthError(OnboardingAuthErrorCode.network, cause: error);
    }
    return OnboardingAuthError(
      OnboardingAuthErrorCode.unknown,
      cause: error,
    );
  }
}

/// Scope-safe read adapter used by account resolution. It never creates or
/// updates a profile; the remote profile remains authoritative.
class RepositoryOnboardingAccountResolver implements OnboardingAccountResolver {
  const RepositoryOnboardingAccountResolver(this._repository);

  final ProfileRepository _repository;

  @override
  Future<RemoteAccountSnapshot> loadRemoteAccountSnapshot(String userId) async {
    final expected = userId.trim();
    _onboardingAuthTrace(
        'event=resolve_remote_start user=${_shortId(expected)}');
    final result = await _repository.fetchCurrentProfile();
    if (!result.isSuccess) {
      throw OnboardingAuthError(
        result.error?.code == RepositoryErrorCode.network
            ? OnboardingAuthErrorCode.network
            : OnboardingAuthErrorCode.accountResolutionFailed,
        cause: result.error,
      );
    }
    final profile = result.data;
    if (profile != null && profile.id.trim() != expected) {
      throw const OnboardingAuthError(OnboardingAuthErrorCode.crossUser);
    }
    final freshBootstrap =
        profile != null && _isFreshBootstrapProfile(profile, expected);
    _onboardingAuthTrace(
      'event=resolve_remote_result user=${_shortId(expected)} '
      'profileExists=${profile != null} '
      'remoteStatus=${profile?.onboardingStatus.name ?? 'none'} '
      'remoteCompleted=${profile?.onboardingCompletedAt != null} '
      'freshBootstrap=$freshBootstrap remoteStateAvailable=true',
    );
    return RemoteAccountSnapshot(
      userId: expected,
      profile: profile,
      remoteUserStateAvailable: true,
      isFreshBootstrapProfile: freshBootstrap,
    );
  }

  bool _isFreshBootstrapProfile(RemoteProfile profile, String userId) {
    if (profile.id.trim() != userId ||
        profile.onboardingStatus != OnboardingStatus.pending ||
        profile.onboardingCompletedAt != null ||
        profile.pillarHabitIds.isNotEmpty ||
        profile.lastLoginAt != null ||
        profile.lastSeenAt != null) {
      return false;
    }

    final profileCreatedAt = profile.createdAt;
    final profileUpdatedAt = profile.updatedAt;
    final authCreatedAt = _parseDateTime(_repository.currentUser?.createdAt);
    if (profileCreatedAt == null || authCreatedAt == null) return false;
    if (profileCreatedAt.difference(authCreatedAt).abs() >
        const Duration(minutes: 15)) {
      return false;
    }
    if (profileUpdatedAt != null &&
        profileUpdatedAt.difference(profileCreatedAt).abs() >
            const Duration(minutes: 2)) {
      return false;
    }
    return true;
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  static String _shortId(String value) =>
      value.length <= 8 ? value : value.substring(0, 8);

  static void _onboardingAuthTrace(String message) {
    if (kDebugMode) debugPrint('[ONBOARDING_AUTH] $message');
  }
}
