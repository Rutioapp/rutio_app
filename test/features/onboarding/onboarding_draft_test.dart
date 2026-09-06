import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/onboarding.dart';

void main() {
  final firstId = '11111111-1111-4111-8111-111111111111';
  final secondId = '22222222-2222-4222-8222-222222222222';
  final thirdId = '33333333-3333-4333-8333-333333333333';

  OnboardingDraft draft({
    DateTime? createdAt,
    OnboardingStep step = OnboardingStep.name,
    OnboardingCompletionState completion = OnboardingCompletionState.draft,
    String? boundUserId,
  }) {
    return OnboardingDraft(
      draftId: firstId,
      onboardingOperationId: secondId,
      draftSchemaVersion: OnboardingVersions.draftSchemaVersion,
      onboardingVersion: OnboardingVersions.onboardingVersion,
      catalogVersion: OnboardingVersions.catalogVersion,
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1, 10),
      updatedAt: createdAt ?? DateTime.utc(2026, 1, 1, 10),
      currentStep: step,
      completionState: completion,
      boundUserId: boundUserId,
    );
  }

  group('OnboardingDraft domain', () {
    test('new draft has distinct UUIDs and stable versions', () {
      final ids = <String>[
        firstId,
        secondId,
        thirdId,
      ];
      final newDraft = OnboardingDraft.create(
        now: () => DateTime.utc(2026, 1, 1),
        uuidGenerator: () => ids.removeAt(0),
      );

      expect(newDraft.draftId, firstId);
      expect(newDraft.onboardingOperationId, secondId);
      expect(newDraft.draftId, isNot(newDraft.onboardingOperationId));
      expect(newDraft.draftSchemaVersion, 1);
      expect(newDraft.onboardingVersion, 1);
      expect(newDraft.catalogVersion, 1);
      expect(newDraft.createdAt, DateTime.utc(2026, 1, 1));

      final sameIdDraft = OnboardingDraft.create(
        uuidGenerator: () => firstId,
      );
      expect(sameIdDraft.draftId, isNot(sameIdDraft.onboardingOperationId));
    });

    test('bind is idempotent but rejects a different user', () {
      final unbound = draft();
      final bound = unbound.bindToUser(' user-a ');
      expect(bound.boundUserId, 'user-a');
      expect(bound.bindToUser('user-a').boundUserId, 'user-a');
      expect(
        () => bound.bindToUser('user-b'),
        throwsA(isA<OnboardingDraftBindingException>()),
      );
    });

    test('completed drafts are retained as backup but are not resumable', () {
      final completed = draft(
        completion: OnboardingCompletionState.completed,
      ).copyWith(completedAt: DateTime.utc(2026, 1, 1, 12));
      final policy = const OnboardingDraftRetentionPolicy();

      expect(completed.isCompleted, isTrue);
      expect(
        policy.shouldRetain(completed, now: DateTime.utc(2026, 1, 2, 11)),
        isTrue,
      );
      expect(
        policy.isReanudable(completed, now: DateTime.utc(2026, 1, 2, 11)),
        isFalse,
      );
      expect(
        policy.shouldRetain(completed, now: DateTime.utc(2026, 1, 2, 13)),
        isFalse,
      );
    });
  });

  group('Onboarding validation and recovery', () {
    test('firstName trims, supports Unicode and limits code points', () {
      expect(
        OnboardingDraftValidator.validateFirstName('  María 李  ').isValid,
        isTrue,
      );
      expect(
        OnboardingDraft(
                firstName: '  María  ',
                currentStep: OnboardingStep.name,
                draftId: firstId,
                onboardingOperationId: secondId,
                draftSchemaVersion: 1,
                onboardingVersion: 1,
                catalogVersion: 1,
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026))
            .firstName,
        'María',
      );
      expect(
        OnboardingDraftValidator.validateFirstName('a' * 31).isValid,
        isFalse,
      );
      expect(
        OnboardingDraftValidator.validateFirstName('a' * 30).isValid,
        isTrue,
      );
    });

    test('goals and pace enforce step requirements', () {
      expect(
          OnboardingDraftValidator.validateGoalCodes(const <String>[]).isValid,
          isFalse);
      expect(
          OnboardingDraftValidator.validateGoalCodes(
              const <String>['care_body']).isValid,
          isTrue);
      expect(
          OnboardingDraftValidator.validateGoalCodes(
              const <String>['care_body', 'find_calm', 'learn_grow']).isValid,
          isTrue);
      expect(
          OnboardingDraftValidator.validateGoalCodes(
              const <String>['a', 'b', 'c', 'd']).isValid,
          isFalse);
      expect(
          OnboardingDraftValidator.validateGoalCodes(const <String>['unknown'])
              .isValid,
          isFalse);
      expect(OnboardingDraftValidator.validatePace(null).isValid, isFalse);
      expect(
          OnboardingDraftValidator.validatePace(OnboardingPace.balanced)
              .isValid,
          isTrue);
    });

    test('recovery does not trust an advanced currentStep', () {
      final invalidPrevious = draft(step: OnboardingStep.pace).copyWith(
        firstName: null,
        goalCodes: {'care_body'},
        pace: OnboardingPace.gentle,
      );
      expect(
        OnboardingDraftValidator.lastSafeStep(invalidPrevious),
        isNull,
      );

      final valid = invalidPrevious.copyWith(firstName: 'Ana');
      expect(
        OnboardingDraftValidator.lastSafeStep(valid),
        OnboardingStep.pace,
      );
    });

    test('optional fields may be absent', () {
      final result = OnboardingDraftValidator.validSteps(draft());
      expect(result, isNot(contains(OnboardingStep.name)));
      expect(result, isNot(contains(OnboardingStep.goals)));
    });
  });

  group('Onboarding codec', () {
    test('round trips fields, enums, sets and timestamps', () {
      final original = draft(step: OnboardingStep.habit).copyWith(
        firstName: ' Ana ',
        goalCodes: {'care_body', 'find_calm'},
        pace: OnboardingPace.energized,
        habit: {
          'id': 'local-habit',
          'type': 'check',
          'schedule': {'type': 'daily'},
        },
        reminder: {'permissionState': ReminderPermissionState.authorized.code},
        shownRecommendationIds: {'r1'},
        discardedRecommendationIds: {'r2'},
        selectedRecommendationId: 'r3',
        authIntent: AuthIntent.signUp,
        completionState: OnboardingCompletionState.authPending,
        completedAt: null,
      );
      final codec = OnboardingDraftCodec();
      final result = codec.decode(codec.encode(original));

      expect(result.status, OnboardingDraftDecodeStatus.valid);
      expect(result.draft!.firstName, 'Ana');
      expect(result.draft!.goalCodes, {'care_body', 'find_calm'});
      expect(result.draft!.pace, OnboardingPace.energized);
      expect(result.draft!.habit!['schedule'], {'type': 'daily'});
      expect(result.draft!.authIntent, AuthIntent.signUp);
      expect(
          result.draft!.completionState, OnboardingCompletionState.authPending);
      expect(result.draft!.createdAt, original.createdAt);
      expect(result.draft!.updatedAt, original.updatedAt);
    });

    test('unknown current step is safe and recoverable', () {
      final json = OnboardingDraftCodec().encode(draft());
      json['currentStep'] = 'futureStep';
      final result = OnboardingDraftCodec().decode(json);
      expect(result.status, OnboardingDraftDecodeStatus.recoverableError);
      expect(result.draft!.currentStep, OnboardingStep.name);
    });

    test('future schema does not crash or become a usable draft', () {
      final json = OnboardingDraftCodec().encode(draft());
      json['draftSchemaVersion'] = OnboardingVersions.draftSchemaVersion + 1;
      final result = OnboardingDraftCodec().decode(json);
      expect(
          result.status, OnboardingDraftDecodeStatus.unsupportedFutureSchema);
      expect(result.draft, isNull);
    });

    test('known invalid data is preserved as recoverable', () {
      final json = OnboardingDraftCodec().encode(draft())
        ..['firstName'] = 'a' * 31
        ..['goalCodes'] = ['a', 'b', 'c', 'd'];
      final result = OnboardingDraftCodec().decode(json);

      expect(result.status, OnboardingDraftDecodeStatus.recoverableError);
      expect(result.draft!.firstName, 'a' * 31);
      expect(result.draft!.goalCodes, {'a', 'b', 'c', 'd'});
      expect(OnboardingDraftValidator.lastSafeStep(result.draft!), isNull);
    });
  });
}
