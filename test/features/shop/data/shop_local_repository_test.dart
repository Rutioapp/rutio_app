import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ShopLocalRepository', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    Future<SharedPreferences> _prefs() async {
      return prefs;
    }

    ShopLocalRepository _repositoryFor(String? scope) {
      return ShopLocalRepository(
        sharedPreferencesProvider: _prefs,
        scopeResolver: () => scope,
      );
    }

    test('load returns initial state when guest storage is empty', () async {
      final repository = _repositoryFor(null);

      final state = await repository.load();

      expect(state, const ShopState.initial());
    });

    test('persists and restores state per authenticated scope', () async {
      final repoA = _repositoryFor('user-a');
      final repoB = _repositoryFor('user-b');

      await repoA.save(
        const ShopState(
          coins: 420,
          backpackItems: <BackpackItem>[
            BackpackItem(
              itemId: 'utility_xp_boost_1d',
              quantity: 2,
              updatedAtMillis: 123,
            ),
          ],
        ),
      );
      await repoB.save(
        const ShopState(
          coins: 77,
          backpackItems: <BackpackItem>[
            BackpackItem(
              itemId: 'utility_coin_boost_1d',
              quantity: 1,
              updatedAtMillis: 456,
            ),
          ],
        ),
      );

      expect((await repoA.load()).coins, 420);
      expect((await repoA.load()).backpackItems, hasLength(1));
      expect((await repoB.load()).coins, 77);
      expect((await repoB.load()).backpackItems, hasLength(1));
    });

    test('authenticated save writes only the scoped key', () async {
      final repository = _repositoryFor('user-a');
      final initialPrefs = await _prefs();
      await initialPrefs.setString(ShopLocalRepository.storageKey, 'legacy');
      await initialPrefs.setString(
        ShopLocalRepository.legacyScopeOwnerKey,
        'legacy-owner',
      );

      await repository.save(const ShopState(coins: 90));

      expect(
        prefs.getString('rutio_shop_state_v1_user-a'),
        contains('"coins":90'),
      );
      expect(prefs.getString(ShopLocalRepository.storageKey), 'legacy');
      expect(
        prefs.getString(ShopLocalRepository.legacyScopeOwnerKey),
        'legacy-owner',
      );
    });

    test('guest save writes only the guest key', () async {
      final repository = _repositoryFor(null);

      await repository.save(const ShopState(coins: 33));

      expect(
        prefs.getString(ShopLocalRepository.guestStorageKey),
        contains('"coins":33'),
      );
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
    });

    test('authenticated load migrates exact-owner legacy data once', () async {
      final repository = _repositoryFor('user-a');
      final legacyState = const ShopState(
        coins: 120,
        inventory: <OwnedShopItem>[
          OwnedShopItem(
            itemId: 'wallpaper_mist_blue',
            acquiredAtMillis: 999,
            source: 'shop_purchase',
          ),
        ],
        backpackItems: <BackpackItem>[
          BackpackItem(
            itemId: 'utility_xp_boost_1d',
            quantity: 2,
            updatedAtMillis: 123,
          ),
        ],
        equippedCosmetics: EquippedCosmetics(
          backgroundItemId: 'wallpaper_mist_blue',
        ),
      );
      await prefs.setString(
        ShopLocalRepository.storageKey,
        jsonEncode(legacyState.toJson()),
      );
      await prefs.setString(ShopLocalRepository.legacyScopeOwnerKey, 'user-a');

      final state = await repository.load();

      expect(state.coins, 120);
      expect(state.backpackItems, hasLength(1));
      expect(state.equippedCosmetics.backgroundItemId, 'wallpaper_mist_blue');
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
      expect(
        prefs.getString('rutio_shop_state_v1_user-a'),
        isNotNull,
      );
    });

    test('legacy owner mismatch is discarded and not imported', () async {
      final repository = _repositoryFor('user-b');
      await prefs.setString(
        ShopLocalRepository.storageKey,
        '{"coins":999,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(ShopLocalRepository.legacyScopeOwnerKey, 'user-a');

      final state = await repository.load();

      expect(state, const ShopState.initial());
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
      expect(prefs.getString('rutio_shop_state_v1_user-b'), isNull);
    });

    test('missing legacy owner is discarded and not imported', () async {
      final repository = _repositoryFor('user-a');
      await prefs.setString(
        ShopLocalRepository.storageKey,
        '{"coins":111,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );

      final state = await repository.load();

      expect(state, const ShopState.initial());
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
    });

    test('invalid legacy json is discarded safely', () async {
      final repository = _repositoryFor('user-a');
      await prefs.setString(ShopLocalRepository.storageKey, '{invalid-json');
      await prefs.setString(ShopLocalRepository.legacyScopeOwnerKey, 'user-a');

      final state = await repository.load();

      expect(state, const ShopState.initial());
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
    });

    test('guest never imports legacy data', () async {
      final repository = _repositoryFor(null);
      await prefs.setString(
        ShopLocalRepository.storageKey,
        '{"coins":250,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(ShopLocalRepository.legacyScopeOwnerKey, 'user-a');

      final state = await repository.load();

      expect(state, const ShopState.initial());
      expect(
        prefs.getString(ShopLocalRepository.storageKey),
        isNotNull,
      );
    });

    test('clear removes the active scope and matching legacy owner only',
        () async {
      final repository = _repositoryFor('user-a');
      await prefs.setString(
        'rutio_shop_state_v1_user-a',
        '{"coins":100,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(
        'rutio_shop_state_v1_user-b',
        '{"coins":200,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(
        ShopLocalRepository.storageKey,
        '{"coins":300,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(ShopLocalRepository.legacyScopeOwnerKey, 'user-a');

      await repository.clear();

      expect(prefs.getString('rutio_shop_state_v1_user-a'), isNull);
      expect(prefs.getString('rutio_shop_state_v1_user-b'), isNotNull);
      expect(prefs.getString(ShopLocalRepository.storageKey), isNull);
      expect(prefs.getString(ShopLocalRepository.legacyScopeOwnerKey), isNull);
    });

    test('guest clear removes only the guest key', () async {
      final repository = _repositoryFor(null);
      await prefs.setString(
        ShopLocalRepository.guestStorageKey,
        '{"coins":44,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );
      await prefs.setString(
        'rutio_shop_state_v1_user-a',
        '{"coins":100,"inventory":[],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      );

      await repository.clear();

      expect(prefs.getString(ShopLocalRepository.guestStorageKey), isNull);
      expect(prefs.getString('rutio_shop_state_v1_user-a'), isNotNull);
    });
  });
}
