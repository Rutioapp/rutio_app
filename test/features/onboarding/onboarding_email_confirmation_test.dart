import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/application/auth/onboarding_auth_state_machine.dart';
import 'package:rutio/features/onboarding/domain/auth/onboarding_auth_contracts.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_types.dart';

void main() {
  test('resend is real, one-shot, and reports typed failures', () async {
    final auth = _ConfirmationAuth();
    final machine = _machine(auth);
    await machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'person@example.com',
      password: 'secret',
    );
    final first = machine.resendConfirmation();
    final second = machine.resendConfirmation();
    expect(await Future.wait([first, second]), contains(true));
    expect(auth.resendCalls, 1);

    auth.resendError = const OnboardingAuthError(
      OnboardingAuthErrorCode.resendRateLimited,
    );
    expect(await machine.resendConfirmation(), isFalse);
    expect(machine.state.phase, OnboardingAuthPhase.awaitingEmailConfirmation);
    expect(
        machine.state.error?.code, OnboardingAuthErrorCode.resendRateLimited);
  });

  test('manual confirmation check uses refreshed session and deduplicates',
      () async {
    final auth = _ConfirmationAuth()..session = null;
    final machine = _machine(auth);
    await machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'person@example.com',
      password: 'secret',
    );
    expect(await machine.checkEmailConfirmation(), isFalse);
    expect(machine.state.error?.code,
        OnboardingAuthErrorCode.confirmationNotDetected);
    auth.session = const AuthenticatedOnboardingSession(userId: 'user-1');
    final first = machine.checkEmailConfirmation();
    final second = machine.checkEmailConfirmation();
    expect((await Future.wait([first, second])).where((v) => v).length, 1);
    expect(auth.refreshCalls, 2);
    expect(machine.state.phase, OnboardingAuthPhase.readyToComplete);
  });
}

OnboardingAuthStateMachine _machine(_ConfirmationAuth auth) =>
    OnboardingAuthStateMachine(
      draft: OnboardingDraft(
        draftId: 'draft',
        onboardingOperationId: 'operation-1',
        draftSchemaVersion: 1,
        onboardingVersion: 1,
        catalogVersion: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        currentStep: OnboardingStep.auth,
        firstName: 'Name',
        habit: <String, dynamic>{'name': 'Read'},
      ),
      auth: auth,
      accountResolution: const OnboardingAccountResolutionService(_Resolver()),
      completion: _Completion(),
    );

class _ConfirmationAuth
    implements OnboardingAuthPort, OnboardingEmailConfirmationPort {
  int resendCalls = 0;
  int refreshCalls = 0;
  OnboardingAuthError? resendError;
  AuthenticatedOnboardingSession? session =
      const AuthenticatedOnboardingSession(userId: 'user-1');

  @override
  Future<OnboardingAuthAttemptResult> authenticate(
          OnboardingAuthRequest request) async =>
      const OnboardingConfirmationRequired();

  @override
  Future<void> resendConfirmation(String email) async {
    resendCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    if (resendError != null) throw resendError!;
  }

  @override
  Future<AuthenticatedOnboardingSession?> refreshConfirmedSession() async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return session;
  }
}

class _Resolver implements OnboardingAccountResolver {
  const _Resolver();
  @override
  Future<RemoteAccountSnapshot> loadRemoteAccountSnapshot(
          String userId) async =>
      RemoteAccountSnapshot(userId: userId, remoteUserStateAvailable: true);
}

class _Completion implements OnboardingCompletionPort {
  @override
  Future<OnboardingCompletionResult> completeOnboarding(
          OnboardingCompletionIntent intent) async =>
      OnboardingCompletionResult(
        kind: OnboardingCompletionResultKind.completed,
        operationId: intent.operationId,
        userId: intent.authenticatedUserId,
      );
}
