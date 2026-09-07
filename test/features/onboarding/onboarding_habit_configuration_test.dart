import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/onboarding/onboarding.dart';

void main() {
  test('recommendation creates a typed prefill with primary family only', () {
    final recommendation = BundledRecommendationCatalogRepository
        .snapshot.recommendations
        .firstWhere((item) => item.id == 'onboarding_v1_walk_body');

    final configuration = OnboardingHabitConfiguration.fromRecommendation(
      recommendation,
      locale: 'en-US',
    );

    expect(configuration.name, 'Go for a walk');
    expect(configuration.emoji, '👟');
    expect(configuration.primaryFamilyCode, 'body');
    expect(configuration.kind, HabitKind.count);
    expect(configuration.targetValue, 6000);
    expect(configuration.unit, 'steps');
    expect(configuration.schedule.isDaily, isTrue);
  });

  test('custom defaults are check + daily with a valid fallback emoji', () {
    final configuration =
        OnboardingHabitConfiguration.custom(familyCode: 'body');

    expect(configuration.name, isEmpty);
    expect(configuration.kind, HabitKind.check);
    expect(configuration.schedule.isDaily, isTrue);
    expect(configuration.primaryFamilyCode, 'body');
    expect(configuration.emoji, '💪');
  });

  test('adapter round trips canonical check daily and count weekly maps', () {
    final values = <OnboardingHabitConfiguration>[
      OnboardingHabitConfiguration(
        name: 'Breathe',
        emoji: '🌬️',
        primaryFamilyCode: 'emotional',
        kind: HabitKind.check,
        schedule: HabitSchedule.daily(),
      ),
      OnboardingHabitConfiguration(
        name: 'Read',
        emoji: '📖',
        primaryFamilyCode: 'mind',
        kind: HabitKind.count,
        targetValue: 10,
        unit: 'minutes',
        schedule: HabitSchedule.daily(),
      ),
    ];

    for (final value in values) {
      final map = OnboardingHabitDraftAdapter.encode(value);
      final decoded = OnboardingHabitDraftAdapter.decode(map);
      expect(decoded.name, value.name);
      expect(decoded.emoji, value.emoji);
      expect(decoded.primaryFamilyCode, value.primaryFamilyCode);
      expect(decoded.kind, value.kind);
      expect(decoded.targetValue, value.targetValue);
      expect(decoded.unit, value.unit);
      expect(decoded.schedule, value.schedule);
      expect(
          map.keys, containsAll(<String>['name', 'emoji', 'type', 'schedule']));
    }
  });

  test('legacy count draft remains valid without target period metadata', () {
    final decoded = OnboardingHabitDraftAdapter.decode(<String, dynamic>{
      'name': 'Read',
      'emoji': '📖',
      'type': 'count',
      'target': 8,
      'unit': 'pages',
      'schedule': <String, dynamic>{'type': 'daily'},
    });

    expect(decoded.kind, HabitKind.count);
    expect(OnboardingHabitDraftAdapter.encode(decoded),
        isNot(contains('targetPeriod')));
  });

  test('count onboarding keeps a concrete weekly schedule', () {
    final configuration = OnboardingHabitConfiguration(
      name: 'Run',
      emoji: '🏃',
      primaryFamilyCode: null,
      kind: HabitKind.count,
      targetValue: 3,
      schedule: HabitSchedule.weekly(weekdays: [1, 3, 5]),
    );

    expect(
      OnboardingHabitConfigurationValidator.validate(configuration).isValid,
      isTrue,
    );
  });

  test(
      'adapter writes no stale count fields and round-trips flexible CHECK schedules',
      () {
    final check = OnboardingHabitConfiguration(
      name: 'Walk',
      emoji: '👟',
      primaryFamilyCode: 'body',
      kind: HabitKind.check,
      schedule: HabitSchedule.daily(),
    );
    final map = OnboardingHabitDraftAdapter.encode(check);
    expect(map, isNot(contains('target')));
    expect(map, isNot(contains('unit')));

    final decodedFlexible =
        OnboardingHabitDraftAdapter.decode(<String, dynamic>{
      'name': 'Legacy',
      'emoji': '✅',
      'type': 'check',
      'schedule': <String, dynamic>{
        'type': 'timesPerWeek',
        'timesPerWeek': 3,
      },
    });
    expect(decodedFlexible.schedule.isTimesPerWeek, isTrue);
    expect(decodedFlexible.schedule.timesPerWeek, 3);
    expect(
      () => OnboardingHabitDraftAdapter.decode(<String, dynamic>{
        'name': 'Bad days',
        'emoji': '✅',
        'type': 'check',
        'schedule': <String, dynamic>{
          'type': 'weekly',
          'weekdays': [1, 1],
        },
      }),
      throwsA(isA<OnboardingHabitDraftAdapterException>()),
    );
  });

  test('count requires a positive target and check cannot carry count data',
      () {
    final countWithoutTarget = OnboardingHabitConfiguration(
      name: 'Read',
      emoji: '📖',
      primaryFamilyCode: 'mind',
      kind: HabitKind.count,
      schedule: HabitSchedule.daily(),
    );
    expect(
      OnboardingHabitConfigurationValidator.validate(countWithoutTarget)
          .isValid,
      isFalse,
    );

    final checkWithTarget = countWithoutTarget.copyWith(
      kind: HabitKind.check,
      targetValue: 4,
    );
    expect(
      OnboardingHabitConfigurationValidator.validate(checkWithTarget).isValid,
      isFalse,
    );
  });

  test('coordinator persists recommendation habit and advances to Reminder',
      () async {
    final store = _MemoryOnboardingStore()..anonymous = _draft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();
    expect(coordinator.state.effectiveStep, OnboardingStep.recommendations);
    expect(await coordinator.selectRecommendation('onboarding_v1_walk_body'),
        isTrue);

    final prefill = coordinator.habitConfigurationForDraft(locale: 'en-US');
    expect(prefill?.name, 'Go for a walk');
    final edited = prefill!.copyWith(name: 'Walk after lunch');
    expect(await coordinator.submitHabit(edited), isTrue);

    expect(coordinator.effectiveStep, OnboardingStep.reminder);
    expect(
        store.anonymous?.selectedRecommendationId, 'onboarding_v1_walk_body');
    expect(store.anonymous?.habit, <String, dynamic>{
      'name': 'Walk after lunch',
      'emoji': '👟',
      'familyId': 'body',
      'type': 'count',
      'target': 6000,
      'targetCount': 6000,
      'unit': 'steps',
      'unitLabel': 'steps',
      'schedule': <String, dynamic>{'type': 'daily'},
      'reminderEnabled': false,
    });
  });

  test('custom route keeps selected null and persistence failure is retryable',
      () async {
    final store = _MemoryOnboardingStore()..anonymous = _draft();
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();
    expect(await coordinator.createHabitFromScratch(), isTrue);
    final custom = coordinator.habitConfigurationForDraft()!.copyWith(
          name: 'Drink water',
          primaryFamilyCode: 'body',
          emoji: '💪',
        );

    store.failWrites = true;
    expect(await coordinator.submitHabit(custom), isFalse);
    expect(coordinator.effectiveStep, OnboardingStep.habit);
    expect(store.anonymous?.habit, isNull);

    store.failWrites = false;
    expect(await coordinator.submitHabit(custom), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.reminder);
    expect(store.anonymous?.selectedRecommendationId, isNull);
    expect(store.anonymous?.habit?['name'], 'Drink water');
    expect(store.anonymous?.habit?['emoji'], '💪');
  });

  test('existing draft habit wins over selected recommendation prefill',
      () async {
    final store = _MemoryOnboardingStore()
      ..anonymous = _draft(
        step: OnboardingStep.habit,
        recommendation: 'onboarding_v1_walk_body',
        habit: const <String, dynamic>{
          'name': 'My edited habit',
          'emoji': '🌱',
          'familyId': 'mind',
          'type': 'check',
          'schedule': <String, dynamic>{
            'type': 'weekly',
            'weekdays': [2, 4]
          },
        },
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();
    final configuration = coordinator.habitConfigurationForDraft();
    expect(configuration?.name, 'My edited habit');
    expect(configuration?.kind, HabitKind.check);
    expect(configuration?.schedule.weekdays, [2, 4]);
  });
}

OnboardingDraft _draft({
  OnboardingStep step = OnboardingStep.recommendations,
  String? recommendation,
  Map<String, dynamic>? habit,
}) {
  return OnboardingDraft(
    draftId: 'draft',
    onboardingOperationId: 'operation',
    draftSchemaVersion: 1,
    onboardingVersion: 1,
    catalogVersion: OnboardingVersions.catalogVersion,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    currentStep: step,
    firstName: 'Ana',
    goalCodes: {'care_body'},
    pace: OnboardingPace.balanced,
    selectedRecommendationId: recommendation,
    habit: habit,
  );
}

class _MemoryOnboardingStore implements OnboardingDraftStore {
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
