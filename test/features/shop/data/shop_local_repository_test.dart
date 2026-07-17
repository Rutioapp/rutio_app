import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/models/backpack_item.dart';
import 'package:rutio/features/shop/domain/models/equipped_cosmetics.dart';
import 'package:rutio/features/shop/domain/models/owned_shop_item.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ShopLocalRepository', () {
    late ShopLocalRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      repository = ShopLocalRepository();
    });

    test('load returns initial state when empty', () async {
      final state = await repository.load();

      expect(state, const ShopState.initial());
    });

    test('save and load preserves coins', () async {
      const state = ShopState(coins: 420);

      await repository.save(state);
      final restored = await repository.load();

      expect(restored.coins, 420);
    });

    test('save and load preserves inventory', () async {
      const state = ShopState(
        inventory: <OwnedShopItem>[
          OwnedShopItem(
            itemId: 'wallpaper_mist_blue',
            acquiredAtMillis: 123,
            source: 'shop_purchase',
          ),
        ],
      );

      await repository.save(state);
      final restored = await repository.load();

      expect(restored.inventory, state.inventory);
    });

    test('save and load preserves backpack', () async {
      const state = ShopState(
        backpackItems: <BackpackItem>[
          BackpackItem(
            itemId: 'utility_xp_boost_1d',
            quantity: 2,
            updatedAtMillis: 123,
          ),
        ],
      );

      await repository.save(state);
      final restored = await repository.load();

      expect(restored.backpackItems, state.backpackItems);
    });

    test('save and load preserves equipped cosmetics', () async {
      const state = ShopState(
        inventory: <OwnedShopItem>[
          OwnedShopItem(itemId: 'wallpaper_mist_blue'),
          OwnedShopItem(itemId: 'habit_card_soft_camel'),
        ],
        equippedCosmetics: EquippedCosmetics(
          backgroundItemId: 'wallpaper_mist_blue',
          habitCardItemId: 'habit_card_soft_camel',
        ),
      );

      await repository.save(state);
      final restored = await repository.load();

      expect(restored.equippedCosmetics, state.equippedCosmetics);
    });

    test('obsolete equipped wallpaper falls back safely on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopLocalRepository.storageKey:
            '{"coins":0,"inventory":[{"itemId":"wallpaper_dune_layers","quantity":1}],"backpackItems":[],"equippedCosmetics":{"backgroundItemId":"wallpaper_dune_layers","habitCardItemId":null,"userCardItemId":null}}',
      });
      repository = ShopLocalRepository();

      final restored = await repository.load();

      expect(restored.inventory, isEmpty);
      expect(restored.equippedCosmetics.backgroundItemId, isNull);
    });

    test('corrupt json returns initial state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopLocalRepository.storageKey: '{invalid-json',
      });
      repository = ShopLocalRepository();

      final state = await repository.load();

      expect(state, const ShopState.initial());
    });

    test('clear removes persisted state', () async {
      await repository.save(const ShopState(coins: 90));

      await repository.clear();
      final restored = await repository.load();

      expect(restored, const ShopState.initial());
    });

    test('persists and restores state per scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final demoRepository = ShopLocalRepository(scopeResolver: () => 'demo');
      final otherRepository = ShopLocalRepository(scopeResolver: () => 'other');

      await demoRepository.save(
        const ShopState(
          backpackItems: <BackpackItem>[
            BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
          ],
        ),
      );

      final demoState = await demoRepository.load();
      final otherState = await otherRepository.load();

      expect(demoState.backpackItems, hasLength(1));
      expect(otherState, const ShopState.initial());
    });

    test('migrates legacy data into active scope once', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopLocalRepository.storageKey:
            '{"coins":0,"inventory":[],"backpackItems":[{"itemId":"utility_xp_boost_1d","quantity":2}],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      });
      final repository = ShopLocalRepository(scopeResolver: () => 'demo');

      final state = await repository.load();
      final reloaded = await repository.load();

      expect(state.backpackItems, const <BackpackItem>[
        BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
      ]);
      expect(reloaded.backpackItems, state.backpackItems);
    });

    test('sanitizes legacy invalid or duplicated backpack entries', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        ShopLocalRepository.storageKey:
            '{"coins":0,"inventory":[],"backpackItems":[{"itemId":"utility_xp_boost_1d","quantity":2,"updatedAtMillis":10},{"utilityId":"utility_xp_boost_1d","quantity":1,"updatedAtMillis":20},{"itemId":"utility_coin_boost_1d","quantity":0},{"itemId":"wallpaper_mist_blue","quantity":5}],"equippedCosmetics":{"backgroundItemId":null,"habitCardItemId":null,"userCardItemId":null}}',
      });
      repository = ShopLocalRepository(scopeResolver: () => 'demo');

      final restored = await repository.load();

      expect(
        restored.backpackItems,
        const <BackpackItem>[
          BackpackItem(
            itemId: 'utility_xp_boost_1d',
            quantity: 3,
            updatedAtMillis: 20,
          ),
        ],
      );
    });
  });
}
