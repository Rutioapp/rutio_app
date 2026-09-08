import 'package:flutter_test/flutter_test.dart';

import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/features/onboarding/application/auth/onboarding_auth_state_machine.dart';
import 'package:rutio/features/onboarding/domain/auth/onboarding_auth_contracts.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_draft.dart';
import 'package:rutio/features/onboarding/domain/models/onboarding_types.dart';

void main() {
  final profile = RemoteProfile(
    id: 'user-1',
    onboardingStatus: OnboardingStatus.completed,
    onboardingVersion: 1,
    onboardingCompletedAt: DateTime.utc(2026, 1, 1),
    displayName: 'Remote',
  );

  OnboardingDraft draft() => OnboardingDraft(
        draftId: 'draft-1',
        onboardingOperationId: 'operation-1',
        draftSchemaVersion: 1,
        onboardingVersion: 1,
        catalogVersion: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        currentStep: OnboardingStep.auth,
        firstName: 'Local',
        habit: <String, dynamic>{'id': 'stable-habit', 'name': 'Read'},
        reminder: <String, dynamic>{'enabled': true},
      );

  OnboardingAuthStateMachine machine({
    required OnboardingAuthPort auth,
    required OnboardingAccountResolver resolver,
    required OnboardingCompletionPort completion,
    OnboardingCompletionReconciler? reconciler,
  }) {
    return OnboardingAuthStateMachine(
      draft: draft(),
      auth: auth,
      accountResolution: OnboardingAccountResolutionService(resolver),
      completion: completion,
      reconciler: reconciler,
    );
  }

  test('new account reaches readyToComplete and keeps prepared habit',
      () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: ' A@EXAMPLE.COM ',
    );
    expect(m.state.phase, OnboardingAuthPhase.readyToComplete);
    expect(m.state.preparedHabitDecision, PreparedHabitDecision.keep);
    expect(m.state.draft.onboardingOperationId, 'operation-1');
  });

  test(
      'existing completed account waits for explicit discard and preserves remote',
      () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signInWithEmail,
      email: 'a@example.com',
    );
    expect(m.state.phase, OnboardingAuthPhase.awaitingPreparedHabitDecision);
    m.choosePreparedHabit(PreparedHabitDecision.discard);
    await m.complete();
    expect(_Completion.last!.preparedHabit, isNull);
    expect(_Completion.last!.reminder, isNull);
    expect(_Completion.last!.name, isNull);
    expect(_Completion.last!.profileApplication,
        OnboardingProfileApplication.preserveRemote);
  });

  test('confirmation and duplicate callback do not complete or clear draft',
      () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingConfirmationRequired()),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(m.state.phase, OnboardingAuthPhase.awaitingEmailConfirmation);
    expect(m.state.draft.onboardingOperationId, 'operation-1');
    expect(m.state.pendingAuthRequest!.email, 'a@example.com');
    expect(m.state.pendingAuthRequest!.operationId, 'operation-1');
    final session = const AuthenticatedOnboardingSession(userId: 'user-1');
    expect(await m.onAuthenticatedSessionAvailable(session), isTrue);
    expect(await m.onAuthenticatedSessionAvailable(session), isFalse);
    expect(m.state.phase, OnboardingAuthPhase.readyToComplete);
  });

  test(
      'retryable completion retries with the same operation and conflict preserves draft',
      () async {
    final completion = _Completion(retryOnce: true);
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: completion,
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(await m.complete(), isFalse);
    expect(m.state.phase, OnboardingAuthPhase.failure);
    expect(await m.complete(), isTrue);
    expect(completion.operations, ['operation-1', 'operation-1']);
    expect(m.state.phase, OnboardingAuthPhase.completed);
  });

  test('cross-user snapshot fails closed', () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-2',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signInWithEmail,
      email: 'a@example.com',
    );
    expect(m.state.phase, OnboardingAuthPhase.failure);
    expect(
        m.state.error!.code, OnboardingAuthErrorCode.accountResolutionFailed);
  });

  test('existing incomplete account has an explicit classification', () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: RemoteProfile(
          id: 'user-1',
          onboardingStatus: OnboardingStatus.inProgress,
          onboardingVersion: 1,
          onboardingCompletedAt: null,
        ),
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signInWithEmail,
      email: 'a@example.com',
    );
    expect(m.state.resolution!.classification,
        OnboardingAccountResolution.existingAccountIncomplete);
    expect(m.state.phase, OnboardingAuthPhase.awaitingPreparedHabitDecision);
  });

  test('discard completion reconciles without a reminder request', () async {
    final reconciler = _RecordingReconciler();
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
      reconciler: reconciler,
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signInWithEmail,
      email: 'a@example.com',
    );
    m.choosePreparedHabit(PreparedHabitDecision.discard);
    expect(await m.complete(), isTrue);
    expect(reconciler.calls, 1);
    expect(reconciler.last!.reminder, isNull);
  });

  test('completion exception is retryable and definitive success clears draft',
      () async {
    final persistence = _Persistence();
    final completion = _ThrowingThenCompleted();
    final m = OnboardingAuthStateMachine(
      draft: draft(),
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      accountResolution: OnboardingAccountResolutionService(
        _Resolver(const RemoteAccountSnapshot(
          userId: 'user-1',
          remoteUserStateAvailable: true,
        )),
      ),
      completion: completion,
      draftPersistence: persistence,
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(await m.complete(), isFalse);
    expect(m.state.error!.code, OnboardingAuthErrorCode.completionRetryable);
    expect(persistence.cleared, isFalse);
    expect(await m.complete(), isTrue);
    expect(persistence.cleared, isTrue);
  });
}

class _Auth implements OnboardingAuthPort {
  _Auth(this.handler);
  final Future<OnboardingAuthAttemptResult> Function(OnboardingAuthRequest)
      handler;
  @override
  Future<OnboardingAuthAttemptResult> authenticate(
          OnboardingAuthRequest request) =>
      handler(request);
}

class _Resolver implements OnboardingAccountResolver {
  _Resolver(this.snapshot);
  final RemoteAccountSnapshot snapshot;
  @override
  Future<RemoteAccountSnapshot> loadRemoteAccountSnapshot(
          String userId) async =>
      snapshot;
}

class _Completion implements OnboardingCompletionPort {
  _Completion({this.retryOnce = false});
  final bool retryOnce;
  final operations = <String>[];
  static OnboardingCompletionIntent? last;
  int calls = 0;
  @override
  Future<OnboardingCompletionResult> completeOnboarding(
      OnboardingCompletionIntent intent) async {
    last = intent;
    operations.add(intent.operationId);
    calls++;
    if (retryOnce && calls == 1) {
      return OnboardingCompletionResult(
        kind: OnboardingCompletionResultKind.retryableFailure,
        operationId: intent.operationId,
        userId: intent.authenticatedUserId,
      );
    }
    return OnboardingCompletionResult(
      kind: OnboardingCompletionResultKind.completed,
      operationId: intent.operationId,
      userId: intent.authenticatedUserId,
    );
  }
}

class _ThrowingThenCompleted implements OnboardingCompletionPort {
  int calls = 0;

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
      OnboardingCompletionIntent intent) async {
    calls++;
    if (calls == 1) throw StateError('network');
    return OnboardingCompletionResult(
      kind: OnboardingCompletionResultKind.alreadyCompletedSameOperation,
      operationId: intent.operationId,
      userId: intent.authenticatedUserId,
    );
  }
}

class _Persistence implements OnboardingAuthDraftPersistence {
  bool cleared = false;

  @override
  Future<void> save(OnboardingDraft draft) async {}

  @override
  Future<void> clear(OnboardingDraft draft) async {
    cleared = true;
  }
}

class _RecordingReconciler implements OnboardingCompletionReconciler {
  int calls = 0;
  OnboardingCompletionIntent? last;

  @override
  Future<void> reconcile({
    required OnboardingCompletionIntent intent,
    required OnboardingCompletionResult result,
  }) async {
    calls++;
    last = intent;
  }
}
