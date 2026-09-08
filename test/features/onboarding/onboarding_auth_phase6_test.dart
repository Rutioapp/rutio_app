import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/application/auth/onboarding_auth_state_machine.dart';
import 'package:rutio/features/onboarding/data/onboarding_draft_codec.dart';
import 'package:rutio/features/onboarding/domain/auth/onboarding_auth_contracts.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_types.dart';

void main() {
  OnboardingDraft draft() => OnboardingDraft(
        draftId: '11111111-1111-4111-8111-111111111111',
        onboardingOperationId: '22222222-2222-4222-8222-222222222222',
        draftSchemaVersion: 1,
        onboardingVersion: 1,
        catalogVersion: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        currentStep: OnboardingStep.auth,
        authIntent: AuthIntent.signUp,
        authEmail: 'person@example.com',
      );

  test('double submit sends one request and never serializes password',
      () async {
    final gate = Completer<OnboardingAuthAttemptResult>();
    final auth = _FakeAuth((request) {
      expect(request.password, 'secret-value');
      return gate.future;
    });
    final machine = OnboardingAuthStateMachine(
      draft: draft(),
      auth: auth,
      accountResolution: OnboardingAccountResolutionService(_Resolver()),
      completion: _Completion(),
    );

    final first = machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: ' person@example.com ',
      password: 'secret-value',
    );
    final second = machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'person@example.com',
      password: 'another-secret',
    );
    expect(await second, isFalse);
    expect(auth.calls, 1);
    gate.complete(const OnboardingConfirmationRequired());
    expect(await first, isTrue);
    expect(machine.state.draft.authEmail, 'person@example.com');
    final encoded = OnboardingDraftCodec().encodeString(machine.state.draft);
    expect(encoded, isNot(contains('secret-value')));
    expect(encoded, isNot(contains('another-secret')));
  });

  test('confirmation persistence keeps operation and email but not password',
      () async {
    final saved = <OnboardingDraft>[];
    final machine = OnboardingAuthStateMachine(
      draft: draft(),
      auth: _FakeAuth((_) async => const OnboardingConfirmationRequired()),
      accountResolution: OnboardingAccountResolutionService(_Resolver()),
      completion: _Completion(),
      draftPersistence: _Persistence(saved),
    );
    await machine.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'person@example.com',
      password: 'secret-value',
    );
    expect(machine.state.phase, OnboardingAuthPhase.awaitingEmailConfirmation);
    expect(saved.last.authEmail, 'person@example.com');
    expect(saved.last.onboardingOperationId,
        '22222222-2222-4222-8222-222222222222');
    expect(OnboardingDraftCodec().encodeString(saved.last),
        isNot(contains('secret-value')));
  });
}

class _FakeAuth implements OnboardingAuthPort {
  _FakeAuth(this.handler);
  final Future<OnboardingAuthAttemptResult> Function(OnboardingAuthRequest)
      handler;
  int calls = 0;

  @override
  Future<OnboardingAuthAttemptResult> authenticate(
      OnboardingAuthRequest request) {
    calls++;
    return handler(request);
  }
}

class _Resolver implements OnboardingAccountResolver {
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

class _Persistence implements OnboardingAuthDraftPersistence {
  _Persistence(this.saved);
  final List<OnboardingDraft> saved;

  @override
  Future<void> save(OnboardingDraft draft) async => saved.add(draft);

  @override
  Future<void> clear(OnboardingDraft draft) async {}
}
