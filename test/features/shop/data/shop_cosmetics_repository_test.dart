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

    Future<SharedPreferences> _prefs() async {
      return prefs;
    }

    ShopCosmeticsRepository _repositoryFor(String? scope) {
      return ShopCosmeticsRepository(
        sharedPreferencesProvider: _prefs,
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
      final repoA = _repositoryFor('user-a');
      final repoB = _repositoryFor('user-b');

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
      final repository = _repositoryFor('user-a');
      final initialPrefs = await _prefs();
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
      final repository = _repositoryFor(null);

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
      final repository = _repositoryFor('user-a');

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
      final repository = _repositoryFor('user-b');

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
      final repository = _repositoryFor('user-a');

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
      final repository = _repositoryFor('user-a');

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
      final repository = _repositoryFor(null);

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
      final repository = _repositoryFor('user-a');
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
      final repository = _repositoryFor(null);
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
  });
}
