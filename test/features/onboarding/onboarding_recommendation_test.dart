import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/onboarding.dart';

void main() {
  test('bundled V1 snapshot is valid, localized and versioned', () {
    final snapshot = BundledRecommendationCatalogRepository.snapshot;
    final result = OnboardingRecommendationCatalogValidator.validate(snapshot);

    expect(result.isValid, isTrue);
    expect(result.validRecommendations.length, greaterThanOrEqualTo(6));
    expect(snapshot.version, OnboardingVersions.catalogVersion);
    final first = snapshot.recommendations.first;
    expect(first.nameFor('es-ES'), isNotEmpty);
    expect(first.nameFor('en-US'), isNotEmpty);
    expect(first.nameFor('ca'), first.localizedContent.names['es']);
    expect(
      snapshot.recommendations.every(
        (recommendation) =>
            !recommendation.initialScheduleSnapshot.containsKey('timesPerWeek'),
      ),
      isTrue,
    );
  });

  test('invalid recommendation entries are ignored without invalidating peers',
      () {
    final valid = _recommendation(id: 'valid');
    final invalid = _recommendation(
      id: 'invalid',
      primaryFamilyCode: 'not-a-family',
    );
    final result = OnboardingRecommendationCatalogValidator.validate(
      _snapshot([valid, invalid]),
    );

    expect(result.validRecommendations.map((item) => item.id), ['valid']);
    expect(
      result.issues.any(
        (issue) =>
            issue.recommendationId == 'invalid' &&
            issue.code ==
                OnboardingRecommendationCatalogIssueCode.invalidFamily,
      ),
      isTrue,
    );
  });

  test('ranking gives primary goal relevance over secondary relevance', () {
    final primary = _recommendation(
      id: 'primary',
      primaryFamilyCode: 'body',
      editorialPriority: 0,
    );
    final secondary = _recommendation(
      id: 'secondary',
      primaryFamilyCode: 'emotional',
      editorialPriority: 20,
    );
    final snapshot = _snapshot([primary, secondary]);
    final service = const OnboardingRecommendationRankingService();

    expect(
      service
          .rank(
            OnboardingRecommendationRankingRequest(
              snapshot: snapshot,
              selectedGoalCodes: {'care_body'},
              pace: OnboardingPace.balanced,
              requestedCount: 2,
            ),
          )
          .first
          .id,
      'primary',
    );
  });

  test('ranking is deterministic, excludes shown and chooses four normally',
      () {
    final snapshot = BundledRecommendationCatalogRepository.snapshot;
    final service = const OnboardingRecommendationRankingService();
    final request = OnboardingRecommendationRankingRequest(
      snapshot: snapshot,
      selectedGoalCodes: {'care_body'},
      pace: OnboardingPace.gentle,
    );

    final first = service.rank(request);
    final second = service.rank(request);
    expect(first.map((item) => item.id), second.map((item) => item.id));
    expect(first, hasLength(4));

    final withoutFirst = service.rank(
      OnboardingRecommendationRankingRequest(
        snapshot: snapshot,
        selectedGoalCodes: request.selectedGoalCodes,
        pace: request.pace,
        shownRecommendationIds: {first.first.id},
      ),
    );
    expect(
        withoutFirst.map((item) => item.id), isNot(contains(first.first.id)));
  });

  test('three-family context can show six diverse recommendations', () {
    final service = const OnboardingRecommendationRankingService();
    final result = service.rank(
      OnboardingRecommendationRankingRequest(
        snapshot: BundledRecommendationCatalogRepository.snapshot,
        selectedGoalCodes: {
          'care_body',
          'find_calm',
          'care_relationships',
        },
        pace: OnboardingPace.balanced,
      ),
    );

    expect(result, hasLength(6));
    expect(result.map((item) => item.primaryFamilyCode).toSet().length,
        greaterThanOrEqualTo(3));
  });

  test('coordinator refreshes history and selecting never creates a habit',
      () async {
    final store = _MemoryStore()
      ..anonymous = OnboardingDraft(
        draftId: 'draft',
        onboardingOperationId: 'operation',
        draftSchemaVersion: 1,
        onboardingVersion: 1,
        catalogVersion: OnboardingVersions.catalogVersion,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        currentStep: OnboardingStep.pace,
        firstName: 'Ana',
        goalCodes: {'care_body'},
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    coordinator.continueDraft();
    expect(await coordinator.submitPace(OnboardingPace.balanced), isTrue);
    final initial = coordinator.state.recommendations!;
    expect(initial, hasLength(4));
    expect(store.anonymous!.shownRecommendationIds,
        containsAll(initial.map((item) => item.id)));
    expect(store.anonymous!.habit, isNull);

    expect(await coordinator.selectRecommendation(initial.first.id), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.habit);
    expect(coordinator.draft!.selectedRecommendationId, initial.first.id);
    expect(coordinator.draft!.habit, isNull);

    expect(await coordinator.goBack(), isTrue);
    expect(coordinator.effectiveStep, OnboardingStep.recommendations);
    expect(await coordinator.refreshRecommendations(), isTrue);
    expect(store.anonymous!.discardedRecommendationIds,
        isNot(contains(initial.first.id)));
    expect(store.anonymous!.discardedRecommendationIds, isNotEmpty);
    expect(coordinator.state.recommendations!.map((item) => item.id),
        isNot(equals(initial.map((item) => item.id))));

    expect(await coordinator.createHabitFromScratch(), isTrue);
    expect(coordinator.draft!.selectedRecommendationId, isNull);
    expect(coordinator.draft!.habit, isNull);
  });

  test('pinned unavailable version is recoverable and remains unchanged',
      () async {
    final store = _MemoryStore()
      ..anonymous = OnboardingDraft(
        draftId: 'draft',
        onboardingOperationId: 'operation',
        draftSchemaVersion: 1,
        onboardingVersion: 1,
        catalogVersion: 99,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        currentStep: OnboardingStep.recommendations,
        firstName: 'Ana',
        goalCodes: {'care_body'},
        pace: OnboardingPace.balanced,
      );
    final coordinator = OnboardingCoordinator(
      draftService: OnboardingDraftService(store: store),
    );

    await coordinator.resume();
    expect(coordinator.state.isRecoverableError, isTrue);
    expect(coordinator.draft!.catalogVersion, 99);
    expect(
        coordinator.state.error?.type, OnboardingCoordinatorErrorType.catalog);
  });
}

OnboardingRecommendationCatalogSnapshot _snapshot(
  List<OnboardingRecommendation> recommendations,
) {
  return OnboardingRecommendationCatalogSnapshot(
    version: OnboardingVersions.catalogVersion,
    recommendations: recommendations,
    goalFamilyRelations: [
      OnboardingGoalFamilyRelation(
        goalCode: 'care_body',
        primaryFamilyCodes: {'body'},
        secondaryFamilyCodes: {'emotional'},
      ),
    ],
  );
}

OnboardingRecommendation _recommendation({
  required String id,
  String primaryFamilyCode = 'body',
  int editorialPriority = 10,
}) {
  return OnboardingRecommendation(
    id: id,
    catalogVersion: OnboardingVersions.catalogVersion,
    localizedContent: OnboardingLocalizedContent(
      names: const {'es': 'Cuerpo', 'en': 'Body'},
    ),
    emoji: '💪',
    habitType: 'check',
    primaryFamilyCode: primaryFamilyCode,
    secondaryFamilyCodes: const {'discipline'},
    goalCodes: const {'care_body'},
    paceCompatibility: const {
      OnboardingPace.gentle: OnboardingPaceCompatibility.adjacent,
      OnboardingPace.balanced: OnboardingPaceCompatibility.ideal,
      OnboardingPace.energized: OnboardingPaceCompatibility.neutral,
    },
    editorialPriority: editorialPriority,
    initialScheduleSnapshot: const {'type': 'daily'},
  );
}

class _MemoryStore implements OnboardingDraftStore {
  OnboardingDraft? anonymous;

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
    anonymous = draft;
  }

  @override
  Future<void> saveForUser(String userId, OnboardingDraft draft) async {}
}
