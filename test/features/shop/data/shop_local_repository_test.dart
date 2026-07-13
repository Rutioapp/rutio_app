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
          BackpackItem(itemId: 'utility_xp_boost_1d', quantity: 2),
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
  });
}
