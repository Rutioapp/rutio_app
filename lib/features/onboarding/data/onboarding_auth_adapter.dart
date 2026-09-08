import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/repository_result.dart';
import '../domain/auth/onboarding_auth_contracts.dart';

/// AUTH-2 adapter. The onboarding flow depends on this boundary instead of
/// reaching into Supabase or duplicating the app's AuthController.
class RepositoryOnboardingAuthAdapter implements OnboardingAuthPort {
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
      final response = request.command == OnboardingAuthCommand.signUpWithEmail
          ? await _repository.signUpWithEmailPassword(
              email: request.email.trim(),
              password: password,
            )
          : await _repository.signInWithEmailPassword(
              email: request.email.trim(),
              password: password,
            );
      if (response.session == null) {
        if (request.command == OnboardingAuthCommand.signUpWithEmail &&
            (response.user != null || _repository.currentUser != null)) {
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
    return RemoteAccountSnapshot(
      userId: expected,
      profile: profile,
      remoteUserStateAvailable: true,
    );
  }
}
