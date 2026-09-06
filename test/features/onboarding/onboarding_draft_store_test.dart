import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final draftId = '11111111-1111-4111-8111-111111111111';
  final operationId = '22222222-2222-4222-8222-222222222222';

  OnboardingDraft draft(
      {OnboardingCompletionState state = OnboardingCompletionState.draft}) {
    return OnboardingDraft(
      draftId: draftId,
      onboardingOperationId: operationId,
      draftSchemaVersion: 1,
      onboardingVersion: 1,
      catalogVersion: 1,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      currentStep: OnboardingStep.name,
      completionState: state,
    );
  }

  SharedPreferencesOnboardingDraftStore createStore({DateTime? now}) {
    return SharedPreferencesOnboardingDraftStore(
      now: () => now ?? DateTime.utc(2026, 1, 1, 1),
    );
  }

  group('SharedPreferencesOnboardingDraftStore', () {
    test('missing, save, load, overwrite and delete', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = createStore();

      expect(await store.loadAnonymousDraft(), isNull);
      expect(await store.hasAnonymousDraft(), isFalse);
      await store.saveAnonymousDraft(draft());
      expect((await store.loadAnonymousDraft())!.draftId, draftId);
      expect(await store.hasAnonymousDraft(), isTrue);

      final overwritten = draft().copyWith(firstName: 'Updated');
      await store.saveAnonymousDraft(overwritten);
      expect((await store.loadAnonymousDraft())!.firstName, 'Updated');

      await store.deleteAnonymousDraft();
      expect(await store.loadAnonymousDraft(), isNull);
    });

    test('corrupt and future payloads are safe and preserved', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = createStore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(store.storageKeyForAnonymous(), '{not-json');

      final corrupt = await store.loadAnonymousDraftResult();
      expect(corrupt.status, OnboardingDraftLoadStatus.corrupt);
      expect(await store.loadAnonymousDraft(), isNull);
      expect(prefs.getString(store.storageKeyForAnonymous()), '{not-json');

      final future = OnboardingDraftCodec().encode(draft())
        ..['draftSchemaVersion'] = 99;
      await prefs.setString(store.storageKeyForAnonymous(), jsonEncode(future));
      final futureResult = await store.loadAnonymousDraftResult();
      expect(futureResult.status,
          OnboardingDraftLoadStatus.unsupportedFutureSchema);
      expect(futureResult.draft, isNull);
    });

    test('schema 0 migrates and is rewritten as current', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = createStore();
      final old = OnboardingDraftCodec().encode(draft())
        ..remove('draftSchemaVersion')
        ..remove('onboardingVersion')
        ..remove('catalogVersion');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(store.storageKeyForAnonymous(), jsonEncode(old));

      final result = await store.loadAnonymousDraftResult();
      expect(result.status, OnboardingDraftLoadStatus.migrated);
      expect(result.draft, isNotNull);
      final rewritten =
          jsonDecode(prefs.getString(store.storageKeyForAnonymous())!);
      expect(rewritten['draftSchemaVersion'], 1);
      expect(rewritten['onboardingVersion'], 1);
    });

    test('anonymous and user scopes are isolated', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = createStore();
      await store.saveAnonymousDraft(draft());
      final bound = draft().bindToUser('user-a');
      await store.saveForUser('user-a', bound);

      expect(await store.loadAnonymousDraft(), isNotNull);
      expect((await store.loadForUser('user-a'))!.boundUserId, 'user-a');
      expect(await store.loadForUser('user-b'), isNull);
      expect(
        () => store.saveForUser('user-b', bound),
        throwsA(isA<OnboardingDraftBindingException>()),
      );
    });

    test('completed draft is stored but is not resumable', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final store = createStore();
      await store.saveAnonymousDraft(
        draft(state: OnboardingCompletionState.completed),
      );
      expect(await store.loadAnonymousDraft(), isNotNull);
      expect(await store.hasAnonymousDraft(), isFalse);
    });
  });

  group('OnboardingDraftService', () {
    test('restart deletes old draft and generates new identities', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final ids = <String>[
        draftId,
        operationId,
        '33333333-3333-4333-8333-333333333333',
        '44444444-4444-4444-8444-444444444444',
      ];
      final service = OnboardingDraftService(
        store: createStore(),
        now: () => DateTime.utc(2026, 1, 1),
        uuidGenerator: () => ids.removeAt(0),
      );
      final first = await service.createNew();
      final second = await service.restart();

      expect(first.draftId, draftId);
      expect(second.draftId, isNot(first.draftId));
      expect(second.onboardingOperationId, isNot(first.onboardingOperationId));
      expect((await service.loadAnonymousDraft())!.draftId, second.draftId);
    });
  });
}
