import 'dart:convert';

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
    OnboardingDraft? draftOverride,
    OnboardingAuthDraftPersistence? draftPersistence,
    Future<void> Function({
      required String operationId,
      required bool habitPresent,
    })? onCompletionHandoff,
  }) {
    return OnboardingAuthStateMachine(
      draft: draftOverride ?? draft(),
      auth: auth,
      accountResolution: OnboardingAccountResolutionService(resolver),
      completion: completion,
      reconciler: reconciler,
      draftPersistence: draftPersistence,
      onCompletionHandoff: onCompletionHandoff,
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

  test('auto-created pending bootstrap profile resolves as new account',
      () async {
    final result = await OnboardingAccountResolutionService(_Resolver(
      RemoteAccountSnapshot(
        userId: 'user-1',
        profile: RemoteProfile(
          id: 'user-1',
          onboardingStatus: OnboardingStatus.pending,
          onboardingVersion: 1,
          onboardingCompletedAt: null,
        ),
        remoteUserStateAvailable: true,
        isFreshBootstrapProfile: true,
      ),
    )).resolve('user-1');

    expect(result.classification, OnboardingAccountResolution.newAccount);
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
    expect(m.state.failureStage, OnboardingAuthFailureStage.completion);
    expect(m.state.authenticatedUserId, 'user-1');
    expect(m.state.resolution, isNotNull);
    expect(m.state.intent?.operationId, 'operation-1');
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

  test('new account completion is invoked exactly once after ready state',
      () async {
    final completion = _Completion();
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
    expect(m.state.phase, OnboardingAuthPhase.readyToComplete);
    expect(await m.complete(), isTrue);
    expect(completion.calls, 1);
  });

  test('successful completion emits one handoff after cleanup', () async {
    final handoffs = <String>[];
    final persistence = _Persistence();
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
      reconciler: _RecordingReconciler(),
      draftPersistence: persistence,
      onCompletionHandoff: ({required operationId, required habitPresent}) {
        handoffs.add('$operationId:$habitPresent:${persistence.cleared}');
        return Future<void>.value();
      },
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );

    expect(await m.complete(), isTrue);
    expect(handoffs, ['operation-1:false:true']);
  });

  test('completion handoff is invoked once after draft clear', () async {
    final persistence = _Persistence();
    var handoffCalls = 0;
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
      draftPersistence: persistence,
      onCompletionHandoff: ({required operationId, required habitPresent}) {
        handoffCalls++;
        expect(persistence.cleared, isTrue);
        return Future<void>.value();
      },
    );

    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(await m.complete(), isTrue);
    expect(await m.complete(), isFalse);
    expect(handoffCalls, 1);
  });

  test('completion retry keeps session and never starts signup again',
      () async {
    var authCalls = 0;
    final completion = _Completion(retryOnce: true);
    final m = machine(
      auth: _Auth((_) async {
        authCalls++;
        return const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'),
        );
      }),
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
    expect(m.state.failureStage, OnboardingAuthFailureStage.completion);
    expect(await m.complete(), isTrue);
    expect(authCalls, 1);
    expect(completion.operations, ['operation-1', 'operation-1']);
  });

  test('a different session user is rejected after operation binding',
      () async {
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-a'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-a',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );

    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-b')),
        isFalse);
    expect(m.state.authenticatedUserId, 'user-a');
  });

  test('recreated state machine preserves operation id from persisted draft',
      () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      authIntent: AuthIntent.signUp,
      completionState: OnboardingCompletionState.remoteInProgress,
      boundUserId: 'user-1',
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: _Completion(),
    );

    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isTrue);
    expect(
        m.state.draft.onboardingOperationId, persisted.onboardingOperationId);
    expect(m.state.phase, OnboardingAuthPhase.completed);
  });

  test('completed remote operation replays and clears recovery draft',
      () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      authIntent: AuthIntent.signUp,
      firstName: 'Local',
      habit: <String, dynamic>{
        'name': 'Read',
        'type': 'check',
        'schedule': <String, dynamic>{'type': 'daily'},
      },
      reminder: <String, dynamic>{'enabled': false},
      completionState: OnboardingCompletionState.remoteInProgress,
      boundUserId: 'user-1',
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final completion = _AlreadyCompleted();
    final persistence = _Persistence();
    final reconciler = _RecordingReconciler();
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: completion,
      reconciler: reconciler,
      draftPersistence: persistence,
    );

    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isTrue);
    expect(completion.calls, 1);
    expect(completion.last!.operationId, persisted.onboardingOperationId);
    expect(completion.last!.accountResolution,
        OnboardingAccountResolution.newAccount);
    expect(completion.last!.preparedHabitDecision, PreparedHabitDecision.keep);
    expect(completion.last!.authenticatedUserId, 'user-1');
    expect(completion.last!.preparedHabit, isNotNull);
    expect(reconciler.calls, 1);
    expect(persistence.cleared, isTrue);
    expect(m.state.phase, OnboardingAuthPhase.completed);
  });

  test('cleanup failure keeps recovery envelope and retries without new op',
      () async {
    final completion = _Completion();
    final persistence = _Persistence(failClear: true);
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: completion,
      draftPersistence: persistence,
    );
    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );

    expect(await m.complete(), isFalse);
    expect(m.state.phase, OnboardingAuthPhase.failure);
    expect(persistence.saved.last.completionState,
        OnboardingCompletionState.remoteInProgress);
    expect(completion.operations, ['operation-1']);

    persistence.failClear = false;
    expect(await m.complete(), isTrue);
    expect(completion.operations, ['operation-1', 'operation-1']);
    expect(persistence.cleared, isTrue);
  });

  test('frozen recovery intent wins over completed remote classification',
      () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      authIntent: AuthIntent.signUp,
      completionState: OnboardingCompletionState.remoteInProgress,
      boundUserId: 'user-1',
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final completion = _AlreadyCompleted();
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: completion,
    );

    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isTrue);
    expect(m.state.phase, OnboardingAuthPhase.completed);
    expect(completion.last!.accountResolution,
        OnboardingAccountResolution.newAccount);
    expect(completion.last!.preparedHabitDecision, PreparedHabitDecision.keep);
    expect(completion.last!.authenticatedUserId, 'user-1');
  });

  test('remote resolution cannot mutate the frozen completion payload',
      () async {
    final remoteSnapshots = <RemoteAccountSnapshot>[
      const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      ),
      RemoteAccountSnapshot(
        userId: 'user-1',
        profile: RemoteProfile(
          id: 'user-1',
          onboardingStatus: OnboardingStatus.inProgress,
          onboardingVersion: 1,
          onboardingCompletedAt: null,
        ),
        remoteUserStateAvailable: true,
      ),
      RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      ),
    ];

    for (final remoteSnapshot in remoteSnapshots) {
      final persisted = draft().copyWith(
        currentStep: OnboardingStep.auth,
        authIntent: AuthIntent.signUp,
        completionState: OnboardingCompletionState.remoteInProgress,
        boundUserId: 'user-1',
        completionAccountResolutionCode:
            OnboardingAccountResolution.newAccount.name,
        completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
      );
      final completion = _AlreadyCompleted();
      final m = machine(
        draftOverride: persisted,
        auth: _Auth((_) async => const OnboardingAuthenticated(
            AuthenticatedOnboardingSession(userId: 'user-1'))),
        resolver: _Resolver(remoteSnapshot),
        completion: completion,
      );

      expect(
          await m.onAuthenticatedSessionAvailable(
              const AuthenticatedOnboardingSession(userId: 'user-1')),
          isTrue);
      expect(completion.last!.accountResolution,
          OnboardingAccountResolution.newAccount);
      expect(completion.last!.preparedHabitDecision,
          PreparedHabitDecision.keep);
    }
  });

  test('legacy frozen recovery adopts the current user without changing intent',
      () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      authIntent: AuthIntent.signUp,
      completionState: OnboardingCompletionState.remoteInProgress,
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final completion = _AlreadyCompleted();
    final persistence = _Persistence();
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: completion,
      draftPersistence: persistence,
    );

    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isTrue);
    expect(completion.last!.accountResolution,
        OnboardingAccountResolution.newAccount);
    expect(completion.last!.preparedHabitDecision, PreparedHabitDecision.keep);
    expect(persistence.saved.first.boundUserId, 'user-1');
  });

  test('frozen recovery never shows prepared habit decision UI', () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      completionState: OnboardingCompletionState.remoteInProgress,
      boundUserId: 'user-1',
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final completion = _AlreadyCompleted();
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: completion,
    );

    final future = m.onAuthenticatedSessionAvailable(
      const AuthenticatedOnboardingSession(userId: 'user-1'),
    );
    expect(m.state.phase,
        isNot(OnboardingAuthPhase.awaitingPreparedHabitDecision));
    await future;
    expect(m.state.phase, OnboardingAuthPhase.completed);
    expect(completion.calls, 1);
  });

  test('crash after RPC replays the frozen intent with a stable fingerprint',
      () async {
    final persistence = _Persistence(failClear: true);
    final completion = _SequenceCompletion();
    final first = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-1',
        remoteUserStateAvailable: true,
      )),
      completion: completion,
      draftPersistence: persistence,
    );

    await first.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(await first.complete(), isFalse);
    expect(persistence.saved.last.completionState,
        OnboardingCompletionState.remoteInProgress);

    persistence.failClear = false;
    final second = machine(
      draftOverride: persistence.saved.last,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: _Resolver(RemoteAccountSnapshot(
        userId: 'user-1',
        profile: profile,
        remoteUserStateAvailable: true,
      )),
      completion: completion,
      draftPersistence: persistence,
    );

    expect(
        await second.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isTrue);
    expect(completion.intents, hasLength(2));
    final initial = completion.intents.first;
    final replay = completion.intents.last;
    expect(replay.operationId, initial.operationId);
    expect(replay.authenticatedUserId, initial.authenticatedUserId);
    expect(replay.accountResolution, initial.accountResolution);
    expect(replay.preparedHabitDecision, initial.preparedHabitDecision);
    expect(replay.name, initial.name);
    expect(jsonEncode(replay.preparedHabit), jsonEncode(initial.preparedHabit));
    expect(jsonEncode(replay.reminder), jsonEncode(initial.reminder));
    expect(second.state.phase, OnboardingAuthPhase.completed);
    expect(persistence.cleared, isTrue);
  });

  test('frozen recovery fails closed for a different session user', () async {
    final persisted = draft().copyWith(
      currentStep: OnboardingStep.auth,
      completionState: OnboardingCompletionState.remoteInProgress,
      boundUserId: 'user-1',
      completionAccountResolutionCode:
          OnboardingAccountResolution.newAccount.name,
      completionPreparedHabitDecisionCode: PreparedHabitDecision.keep.name,
    );
    final completion = _AlreadyCompleted();
    final m = machine(
      draftOverride: persisted,
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-2'))),
      resolver: _Resolver(const RemoteAccountSnapshot(
        userId: 'user-2',
        remoteUserStateAvailable: true,
      )),
      completion: completion,
    );

    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-2')),
        isFalse);
    expect(completion.calls, 0);
  });

  test('duplicate authenticated callback does not resolve or complete twice',
      () async {
    final completion = _Completion();
    final resolver = _CountingResolver(const RemoteAccountSnapshot(
      userId: 'user-1',
      remoteUserStateAvailable: true,
    ));
    final m = machine(
      auth: _Auth((_) async => const OnboardingAuthenticated(
          AuthenticatedOnboardingSession(userId: 'user-1'))),
      resolver: resolver,
      completion: completion,
    );

    await m.authenticate(
      command: OnboardingAuthCommand.signUpWithEmail,
      email: 'a@example.com',
    );
    expect(
        await m.onAuthenticatedSessionAvailable(
            const AuthenticatedOnboardingSession(userId: 'user-1')),
        isFalse);
    expect(await m.complete(), isTrue);
    expect(resolver.calls, 1);
    expect(completion.calls, 1);
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

class _CountingResolver implements OnboardingAccountResolver {
  _CountingResolver(this.snapshot);
  final RemoteAccountSnapshot snapshot;
  int calls = 0;

  @override
  Future<RemoteAccountSnapshot> loadRemoteAccountSnapshot(String userId) async {
    calls++;
    return snapshot;
  }
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

class _AlreadyCompleted implements OnboardingCompletionPort {
  int calls = 0;
  OnboardingCompletionIntent? last;

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
      OnboardingCompletionIntent intent) async {
    calls++;
    last = intent;
    return OnboardingCompletionResult(
      kind: OnboardingCompletionResultKind.alreadyCompletedSameOperation,
      operationId: intent.operationId,
      userId: intent.authenticatedUserId,
      habitId: 'habit-1',
      preparedHabitApplied: true,
    );
  }
}

class _SequenceCompletion implements OnboardingCompletionPort {
  final intents = <OnboardingCompletionIntent>[];

  @override
  Future<OnboardingCompletionResult> completeOnboarding(
      OnboardingCompletionIntent intent) async {
    intents.add(intent);
    final alreadyCompleted = intents.length > 1;
    return OnboardingCompletionResult(
      kind: alreadyCompleted
          ? OnboardingCompletionResultKind.alreadyCompletedSameOperation
          : OnboardingCompletionResultKind.completed,
      operationId: intent.operationId,
      userId: intent.authenticatedUserId,
    );
  }
}

class _Persistence implements OnboardingAuthDraftPersistence {
  _Persistence({this.failClear = false});

  final saved = <OnboardingDraft>[];
  bool failClear;
  bool cleared = false;

  @override
  Future<void> save(OnboardingDraft draft) async => saved.add(draft);

  @override
  Future<void> clear(OnboardingDraft draft) async {
    if (failClear) throw StateError('draft clear failed');
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
