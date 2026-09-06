import 'package:flutter/foundation.dart';

/// Stable, persisted codes for the local onboarding contract.
enum OnboardingStep {
  name('name'),
  goals('goals'),
  pace('pace'),
  recommendations('recommendations'),
  habit('habit'),
  reminder('reminder'),
  preview('preview'),
  auth('auth'),
  emailConfirmation('emailConfirmation'),
  resolvingAccount('resolvingAccount'),
  finalizing('finalizing');

  const OnboardingStep(this.code);

  final String code;

  static OnboardingStep? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final step in values) {
      if (step.code == code) return step;
    }
    return null;
  }
}

enum OnboardingPace {
  gentle('gentle'),
  balanced('balanced'),
  energized('energized');

  const OnboardingPace(this.code);

  final String code;

  static OnboardingPace? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final pace in values) {
      if (pace.code == code) return pace;
    }
    return null;
  }
}

enum AuthIntent {
  signUp('signUp'),
  signIn('signIn');

  const AuthIntent(this.code);

  final String code;

  static AuthIntent? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final intent in values) {
      if (intent.code == code) return intent;
    }
    return null;
  }
}

enum OnboardingCompletionState {
  draft('draft'),
  authPending('authPending'),
  remoteInProgress('remoteInProgress'),
  finalizing('finalizing'),
  completed('completed'),
  recoverableError('recoverableError');

  const OnboardingCompletionState(this.code);

  final String code;

  static OnboardingCompletionState? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final state in values) {
      if (state.code == code) return state;
    }
    return null;
  }
}

enum ReminderPermissionState {
  notRequested('notRequested'),
  authorized('authorized'),
  denied('denied'),
  provisional('provisional'),
  restricted('restricted');

  const ReminderPermissionState(this.code);

  final String code;

  static ReminderPermissionState? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final state in values) {
      if (state.code == code) return state;
    }
    return null;
  }
}

enum ReminderSchedulingState {
  notRequested('notRequested'),
  readyToSchedule('readyToSchedule'),
  scheduled('scheduled'),
  pendingRetry('pendingRetry'),
  disabled('disabled');

  const ReminderSchedulingState(this.code);

  final String code;

  static ReminderSchedulingState? fromCode(Object? value) {
    final code = (value ?? '').toString().trim();
    for (final state in values) {
      if (state.code == code) return state;
    }
    return null;
  }
}

/// There is one source of truth for versions understood by this app build.
@immutable
class OnboardingVersions {
  const OnboardingVersions._();

  static const int draftSchemaVersion = 1;
  static const int onboardingVersion = 1;
  static const int catalogVersion = 1;
}
