import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/onboarding.dart';

void main() {
  final ids = <String>[
    '11111111-1111-4111-8111-111111111111',
    '22222222-2222-4222-8222-222222222222',
    '33333333-3333-4333-8333-333333333333',
    '44444444-4444-4444-8444-444444444444',
    '55555555-5555-4555-8555-555555555555',
    '66666666-6666-4666-8666-666666666666',
  ];

  OnboardingDraft makeDraft({
    OnboardingStep step = OnboardingStep.name,
    String? firstName,
    Set<String>? goals,
    OnboardingPace? pace,
    String? recommendation,
    Map<String, dynamic>? habit,
    Map<String, dynamic>? reminder,
    OnboardingCompletionState state = OnboardingCompletionState.draft,
  }) {
    return OnboardingDraft(
      draftId: ids[0],
      onboardingOperationId: ids[1],
      draftSchemaVersion: 1,
      onboardingVersion: 1,
      catalogVersion: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      currentStep: step,
      firstName: firstName,
      goalCodes: goals,
      pace: pace,
      selectedRecommendationId: recommendation,
      habit: habit,
      reminder: reminder,
      completionState: state,
    );
  }

  test('startNew persists a new draft at the first internal step', () async {
    final store = _MemoryStore();
    final service = OnboardingDraftService(
      store: store,
      uuidGenerator: () => ids.removeAt(2),
    );
    final coordinator = OnboardingCoordinator(draftService: service);

    await coordinator.startNew();

    expect(coordinator.state.status, OnboardingCoordinatorStatus.ready);
    expect(coordinator.state.effectiveStep, OnboardingStep.name);
    expect(coordinator.state.isAtWelcome, isFalse);
    expect(store.anonymous?.draftId, '33333333-3333-4333-8333-333333333333');
    expect(store.anonymous?.onboardingOperationId,
        '44444444-4444-4444-8444-444444444444');
    expect(store.anonymous?.draftId,
        isNot(store.anonymous?.onboardingOperationId));
  });

  test('resume preserves identities and clamps an unsafe cursor', () async {
    final draft = makeDraft(
      step: OnboardingStep.pace,
      goals: {'care_body'},
      pace: OnboardingPace.balanced,
    );
    final store = _MemoryStore()..anonymous = draft;
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();

    expect(coordinator.state.effectiveStep, OnboardingStep.name);
    expect(coordinator.draft?.draftId, draft.draftId);
    expect(
        coordinator.draft?.onboardingOperationId, draft.onboardingOperationId);
    expect(coordinator.state.isAtWelcome, isTrue);
  });

  test('resume enters Name for a missing name and Goals for a valid name',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(step: OnboardingStep.goals);
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.name);
    expect(coordinator.draft?.firstName, isNull);

    store.anonymous = makeDraft(step: OnboardingStep.goals, firstName: 'Ana');
    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(coordinator.draft?.firstName, 'Ana');
  });

  test('completed and missing drafts resolve to Welcome without a crash',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(state: OnboardingCompletionState.completed);
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    expect(coordinator.state.status, OnboardingCoordinatorStatus.ready);
    expect(coordinator.draft, isNull);

    store.anonymous = null;
    await coordinator.resume();
    expect(coordinator.state.status, OnboardingCoordinatorStatus.ready);
    expect(coordinator.state.isAtWelcome, isTrue);
  });

  test('submit persists before publishing the next step and Back keeps data',
      () async {
    final store = _MemoryStore()..anonymous = makeDraft(firstName: 'Ana');
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitCurrentStep(), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(store.anonymous?.currentStep, OnboardingStep.goals);
    expect(coordinator.draft?.firstName, 'Ana');

    expect(await coordinator.goBack(), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.name);
    expect(coordinator.draft?.firstName, 'Ana');
    expect(store.anonymous?.firstName, 'Ana');
  });

  test('invalid candidate is rejected by domain guards', () async {
    final store = _MemoryStore()..anonymous = makeDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitCurrentStep(), isFalse);
    expect(coordinator.effectiveStep, OnboardingStep.name);
    expect(coordinator.state.validation?.isValid, isFalse);
  });

  test('submitName trims, persists and preserves both identities', () async {
    final store = _MemoryStore()..anonymous = makeDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();
    final draftId = coordinator.draft?.draftId;
    final operationId = coordinator.draft?.onboardingOperationId;

    expect(await coordinator.submitName('  Vicenç  '), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(coordinator.draft?.firstName, 'Vicenç');
    expect(store.anonymous?.firstName, 'Vicenç');
    expect(coordinator.draft?.draftId, draftId);
    expect(coordinator.draft?.onboardingOperationId, operationId);
  });

  test('submitName rejects empty, whitespace and names over 30 code points',
      () async {
    final store = _MemoryStore()..anonymous = makeDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitName(''), isFalse);
    expect(await coordinator.submitName('   '), isFalse);
    expect(await coordinator.submitName('a' * 31), isFalse);
    expect(coordinator.effectiveStep, OnboardingStep.name);
    expect(coordinator.draft?.firstName, isNull);
    expect(store.anonymous?.firstName, isNull);
  });

  test('submitName accepts exactly 30 code points and international Unicode',
      () async {
    final store = _MemoryStore()..anonymous = makeDraft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitName('á' * 30), isTrue);
    expect(coordinator.draft?.firstName, 'á' * 30);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
  });

  test('submitGoals validates, persists, advances and preserves identities',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(step: OnboardingStep.goals, firstName: 'Ana');
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();
    final draftId = coordinator.draft?.draftId;
    final operationId = coordinator.draft?.onboardingOperationId;

    expect(await coordinator.submitGoals({'care_body', 'find_calm'}), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.pace);
    expect(coordinator.draft?.goalCodes, {'care_body', 'find_calm'});
    expect(store.anonymous?.currentStep, OnboardingStep.pace);
    expect(coordinator.draft?.firstName, 'Ana');
    expect(coordinator.draft?.draftId, draftId);
    expect(coordinator.draft?.onboardingOperationId, operationId);

    expect(await coordinator.goBack(), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(coordinator.draft?.goalCodes, {'care_body', 'find_calm'});
  });

  test('submitGoals rejects unknown and invalid quantities', () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(step: OnboardingStep.goals, firstName: 'Ana');
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitGoals({}), isFalse);
    expect(
        await coordinator.submitGoals({'care_body', 'find_calm', 'learn_grow'}),
        isTrue);

    final fourGoalStore = _MemoryStore()
      ..anonymous = makeDraft(step: OnboardingStep.goals, firstName: 'Ana');
    final fourGoalCoordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: fourGoalStore),
    );
    await fourGoalCoordinator.resume();
    fourGoalCoordinator.continueDraft();
    expect(
      await fourGoalCoordinator.submitGoals({
        'care_body',
        'find_calm',
        'learn_grow',
        'build_discipline',
      }),
      isFalse,
    );
    expect(
      await fourGoalCoordinator.submitGoals({'unknown_goal'}),
      isFalse,
    );
    expect(fourGoalCoordinator.effectiveStep, OnboardingStep.goals);
  });

  test('submitGoals persistence failure keeps confirmed state and retries',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(step: OnboardingStep.goals, firstName: 'Ana');
    store.failWrites = true;
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitGoals({'care_body'}), isFalse);
    expect(
        coordinator.state.status, OnboardingCoordinatorStatus.recoverableError);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(coordinator.draft?.goalCodes, isEmpty);

    store.failWrites = false;
    expect(await coordinator.submitGoals({'care_body'}), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.pace);
    expect(coordinator.draft?.goalCodes, {'care_body'});
  });

  test('resume keeps valid goals at Pace and repairs invalid advanced goals',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(
        step: OnboardingStep.pace,
        firstName: 'Ana',
        goals: {'care_body', 'find_calm'},
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.pace);

    store.anonymous = makeDraft(
      step: OnboardingStep.pace,
      firstName: 'Ana',
      goals: {'care_body', 'unknown_goal'},
    );
    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.goals);
  });

  test('submitPace persists every typed pace and advances to Recommendations',
      () async {
    for (final pace in OnboardingPace.values) {
      final store = _MemoryStore()
        ..anonymous = makeDraft(
          step: OnboardingStep.pace,
          firstName: 'Ana',
          goals: {'care_body'},
        );
      final coordinator = OnboardingCoordinator(
        draftService: OnboardingDraftService(store: store),
      );
      await coordinator.resume();
      coordinator.continueDraft();

      expect(await coordinator.submitPace(pace), isTrue);
      expect(coordinator.effectiveStep, OnboardingStep.recommendations);
      expect(coordinator.draft?.pace, pace);
      expect(store.anonymous?.pace, pace);
      expect(coordinator.draft?.firstName, 'Ana');
      expect(coordinator.draft?.goalCodes, {'care_body'});
    }
  });

  test('submitPace persistence failure preserves selection and retries',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(
        step: OnboardingStep.pace,
        firstName: 'Ana',
        goals: {'care_body'},
      );
    store.failWrites = true;
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitPace(OnboardingPace.gentle), isFalse);
    expect(
        coordinator.state.status, OnboardingCoordinatorStatus.recoverableError);
    expect(coordinator.effectiveStep, OnboardingStep.pace);
    expect(coordinator.draft?.pace, isNull);

    store.failWrites = false;
    expect(await coordinator.submitPace(OnboardingPace.gentle), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.recommendations);
    expect(coordinator.draft?.pace, OnboardingPace.gentle);
  });

  test('resume returns to Pace without pace and Recommendations with pace',
      () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(
        step: OnboardingStep.recommendations,
        firstName: 'Ana',
        goals: {'care_body'},
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.pace);

    store.anonymous = makeDraft(
      step: OnboardingStep.recommendations,
      firstName: 'Ana',
      goals: {'care_body'},
      pace: OnboardingPace.balanced,
    );
    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.effectiveStep, OnboardingStep.recommendations);
  });

  test('pace placeholder cannot auto-fill or advance Pace', () async {
    final store = _MemoryStore()
      ..anonymous = makeDraft(
        step: OnboardingStep.pace,
        firstName: 'Ana',
        goals: {'care_body'},
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitPlaceholderStep(), isFalse);
    expect(coordinator.effectiveStep, OnboardingStep.pace);
    expect(coordinator.draft?.pace, isNull);
  });

  test('persistence failure keeps the last known-good draft', () async {
    final store = _MemoryStore()..anonymous = makeDraft();
    store.failWrites = true;
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );
    await coordinator.resume();
    coordinator.continueDraft();

    expect(await coordinator.submitName('Ana'), isFalse);
    expect(
        coordinator.state.status, OnboardingCoordinatorStatus.recoverableError);
    expect(coordinator.draft?.currentStep, OnboardingStep.name);

    store.failWrites = false;
    expect(await coordinator.submitName('  Ana  '), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.goals);
    expect(coordinator.draft?.firstName, 'Ana');
  });

  test('restart creates fresh identities and invalidates a stale resume',
      () async {
    final stale = Completer<OnboardingDraftLoadResult>();
    final service = _DelayedService(stale);
    final coordinator = OnboardingCoordinator(draftService: service);
    final resuming = coordinator.resume();

    await coordinator.restart();
    stale.complete(OnboardingDraftLoadResult(
      status: OnboardingDraftLoadStatus.valid,
      draft: makeDraft(step: OnboardingStep.goals, firstName: 'Stale'),
    ));
    await resuming;

    expect(coordinator.state.effectiveStep, OnboardingStep.name);
    expect(coordinator.draft?.draftId, service.restarted?.draftId);
    expect(service.restarted?.draftId, isNot(makeDraft().draftId));
  });
}

class _MemoryStore implements OnboardingDraftStore {
  OnboardingDraft? anonymous;
  bool failWrites = false;

  @override
  Future<void> deleteAnonymousDraft() async => anonymous = null;

  @override
  Future<void> deleteForUser(String userId) async {}

  @override
  Future<bool> hasAnonymousDraft() async => anonymous != null;

  @override
  Future<OnboardingDraft?> loadAnonymousDraft() async => anonymous;

  @override
  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult() async =>
      anonymous == null
          ? const OnboardingDraftLoadResult.missing()
          : OnboardingDraftLoadResult(
              status: OnboardingDraftLoadStatus.valid,
              draft: anonymous,
            );

  @override
  Future<OnboardingDraft?> loadForUser(String userId) async => null;

  @override
  Future<void> saveAnonymousDraft(OnboardingDraft draft) async {
    if (failWrites) throw StateError('write failed');
    anonymous = draft;
  }

  @override
  Future<void> saveForUser(String userId, OnboardingDraft draft) async {}
}

class _DelayedService extends OnboardingDraftService {
  _DelayedService(this.loadCompleter)
      : super(store: _MemoryStore(), uuidGenerator: _freshId);

  final Completer<OnboardingDraftLoadResult> loadCompleter;
  OnboardingDraft? restarted;

  @override
  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult() =>
      loadCompleter.future;

  @override
  Future<OnboardingDraft> restart() async {
    final value = OnboardingDraft(
      draftId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      onboardingOperationId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      draftSchemaVersion: 1,
      onboardingVersion: 1,
      catalogVersion: 1,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      currentStep: OnboardingStep.name,
    );
    restarted = value;
    return value;
  }

  static String _freshId() => 'cccccccc-cccc-4ccc-8ccc-cccccccccccc';
}
