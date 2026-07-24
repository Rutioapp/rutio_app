import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ShopCosmeticsRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Future<SharedPreferences> prefsProvider() async {
      return prefs;
    }

    ShopCosmeticsRepository repositoryFor(String? scope) {
      return ShopCosmeticsRepository(
        sharedPreferencesProvider: prefsProvider,
        scopeResolver: () => scope,
      );
    }

    final stateA = ShopCosmeticsState(
      ownedAssetIds: <String>[
        'wallpaper_mist_blue',
        'habit_card_warm_beige',
        'user_card_warm_beige',
      ],
      ownedBundleIds: <String>['pack_beige_rutio'],
      equippedWallpaperId: 'wallpaper_mist_blue',
      equippedHabitCardSkinId: 'habit_card_warm_beige',
      equippedUserCardSkinId: 'user_card_warm_beige',
    );

    final stateB = ShopCosmeticsState(
      ownedAssetIds: <String>['wallpaper_soft_sage'],
      ownedBundleIds: <String>['pack_camel_suave'],
      equippedWallpaperId: 'wallpaper_soft_sage',
      equippedHabitCardSkinId: null,
      equippedUserCardSkinId: null,
    );

    test('persists and restores state per authenticated scope', () async {
      final repoA = repositoryFor('user-a');
      final repoB = repositoryFor('user-b');

      await repoA.save(stateA);
      await repoB.save(stateB);

      expect((await repoA.load()).ownedAssetIds, stateA.ownedAssetIds);
      expect((await repoA.load()).ownedBundleIds, stateA.ownedBundleIds);
      expect((await repoB.load()).ownedAssetIds, stateB.ownedAssetIds);
      expect((await repoB.load()).ownedBundleIds, stateB.ownedBundleIds);
      expect((await repoA.load()).equippedWallpaperId, 'wallpaper_mist_blue');
      expect((await repoB.load()).equippedWallpaperId, 'wallpaper_soft_sage');
    });

    test('authenticated save writes only the scoped key', () async {
      final repository = repositoryFor('user-a');
      final initialPrefs = await prefsProvider();
      await initialPrefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        'legacy',
      );
      await initialPrefs.setString(
        ShopCosmeticsRepository.legacyScopeOwnerKey,
        'legacy-owner',
      );

      await repository.save(stateA);

      expect(
        prefs.getString('rutio_shop_cosmetics_v1_user-a'),
        contains('"equippedWallpaperId":"wallpaper_mist_blue"'),
      );
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyStorageKey), 'legacy');
      expect(
        prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey),
        'legacy-owner',
      );
    });

    test('guest save writes only the guest key', () async {
      final repository = repositoryFor(null);

      await repository.save(stateA);

      expect(
        prefs.getString(ShopCosmeticsRepository.guestStorageKey),
        contains('"equippedWallpaperId":"wallpaper_mist_blue"'),
      );
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey), isNull);
    });

    test('exact-owner legacy migration preserves all fields and clears legacy',
        () async {
      final repository = repositoryFor('user-a');

      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
          ShopCosmeticsRepository.legacyScopeOwnerKey, 'user-a');

      final migrated = await repository.load();

      expect(migrated, stateA);
      expect(
        prefs.getString('rutio_shop_cosmetics_v1_user-a'),
        contains('"equippedUserCardSkinId":"user_card_warm_beige"'),
      );
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
        prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey),
        isNull,
      );
    });

    test('owner mismatch is discarded and not imported', () async {
      final repository = repositoryFor('user-b');

      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
          ShopCosmeticsRepository.legacyScopeOwnerKey, 'user-a');

      final loaded = await repository.load();

      expect(loaded, const ShopCosmeticsState.initial());
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey), isNull);
      expect(prefs.getString('rutio_shop_cosmetics_v1_user-b'), isNull);
    });

    test('missing legacy owner is discarded and not imported', () async {
      final repository = repositoryFor('user-a');

      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        jsonEncode(stateA.toJson()),
      );

      final loaded = await repository.load();

      expect(loaded, const ShopCosmeticsState.initial());
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey), isNull);
    });

    test('invalid legacy json is discarded safely', () async {
      final repository = repositoryFor('user-a');

      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        '{invalid-json',
      );
      await prefs.setString(
          ShopCosmeticsRepository.legacyScopeOwnerKey, 'user-a');

      final loaded = await repository.load();

      expect(loaded, const ShopCosmeticsState.initial());
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey), isNull);
    });

    test('guest never imports legacy data', () async {
      final repository = repositoryFor(null);

      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
          ShopCosmeticsRepository.legacyScopeOwnerKey, 'user-a');

      final loaded = await repository.load();

      expect(loaded, const ShopCosmeticsState.initial());
      expect(
          prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNotNull);
    });

    test('clear removes the active scope and matching legacy owner only',
        () async {
      final repository = repositoryFor('user-a');
      await prefs.setString(
        'rutio_shop_cosmetics_v1_user-a',
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
        'rutio_shop_cosmetics_v1_user-b',
        jsonEncode(stateB.toJson()),
      );
      await prefs.setString(
        ShopCosmeticsRepository.legacyStorageKey,
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
          ShopCosmeticsRepository.legacyScopeOwnerKey, 'user-a');

      await repository.clear();

      expect(prefs.getString('rutio_shop_cosmetics_v1_user-a'), isNull);
      expect(prefs.getString('rutio_shop_cosmetics_v1_user-b'), isNotNull);
      expect(prefs.getString(ShopCosmeticsRepository.legacyStorageKey), isNull);
      expect(
        prefs.getString(ShopCosmeticsRepository.legacyScopeOwnerKey),
        isNull,
      );
    });

    test('guest clear removes only the guest key', () async {
      final repository = repositoryFor(null);
      await prefs.setString(
        ShopCosmeticsRepository.guestStorageKey,
        jsonEncode(stateA.toJson()),
      );
      await prefs.setString(
        'rutio_shop_cosmetics_v1_user-a',
        jsonEncode(stateA.toJson()),
      );

      await repository.clear();

      expect(prefs.getString(ShopCosmeticsRepository.guestStorageKey), isNull);
      expect(prefs.getString('rutio_shop_cosmetics_v1_user-a'), isNotNull);
    });

    test('serializes operations on the same instance', () async {
      final harness = _QueuedPrefsProvider(prefs);
      final repository = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );

      final first = repository.save(stateA);
      await _waitForCalls(harness, 1);

      final second = repository.save(stateB);
      await _waitForCalls(harness, 1);

      harness.completeNext();
      await first;
      await _waitForCalls(harness, 2);

      harness.completeNext();
      await second;
    });

    test('different instances on the same scope keep the last write', () async {
      final harness = _QueuedPrefsProvider(prefs);
      final repoA = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );
      final repoB = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );

      final first = repoA.save(stateA);
      await _waitForCalls(harness, 1);

      final second = repoB.save(stateB);
      await _waitForCalls(harness, 1);

      harness.completeNext();
      await first;
      await _waitForCalls(harness, 2);

      harness.completeNext();
      await second;

      final loaded = await repositoryFor('user-a').load();
      expect(loaded, stateB);
    });

    test('different users do not block each other', () async {
      final harness = _QueuedPrefsProvider(prefs);
      final repoA = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );
      final repoB = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-b',
      );

      final first = repoA.save(stateA);
      await _waitForCalls(harness, 1);

      final second = repoB.save(stateB);
      await _waitForCalls(harness, 2);

      harness.completeNext();
      harness.completeNext();
      await first;
      await second;
    });

    test('guest and authenticated users do not share the queue', () async {
      final harness = _QueuedPrefsProvider(prefs);
      final guestRepo = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => null,
      );
      final authRepo = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );

      final guestSave = guestRepo.save(stateA);
      await _waitForCalls(harness, 1);

      final authSave = authRepo.save(stateB);
      await _waitForCalls(harness, 2);

      harness.completeNext();
      harness.completeNext();
      await guestSave;
      await authSave;
    });

    test('a failed operation does not block later operations', () async {
      final harness = _QueuedPrefsProvider(prefs);
      final repository = ShopCosmeticsRepository(
        sharedPreferencesProvider: harness.call,
        scopeResolver: () => 'user-a',
      );

      final first = repository.save(stateA);
      await _waitForCalls(harness, 1);

      harness.failNext(StateError('boom'));
      await expectLater(first, throwsA(isA<StateError>()));

      final second = repository.save(stateB);
      await _waitForCalls(harness, 2);

      harness.completeNext();
      await second;
    });
  });
}

Future<void> _waitForCalls(_QueuedPrefsProvider harness, int expected) async {
  for (var attempt = 0; attempt < 10 && harness.calls < expected; attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(harness.calls, expected);
}

class _QueuedPrefsProvider {
  _QueuedPrefsProvider(this.prefs);

  final SharedPreferences prefs;
  final List<Completer<SharedPreferences>> _pending =
      <Completer<SharedPreferences>>[];
  int _started = 0;

  int get calls => _started;
  int get pending => _pending.length;

  Future<SharedPreferences> call() {
    _started += 1;
    final completer = Completer<SharedPreferences>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() {
    if (_pending.isEmpty) {
      throw StateError('No pending preferences call.');
    }
    _pending.removeAt(0).complete(prefs);
  }

  void failNext(Object error) {
    if (_pending.isEmpty) {
      throw StateError('No pending preferences call.');
    }
    _pending.removeAt(0).completeError(error);
  }
}
