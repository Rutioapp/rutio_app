import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/screens/shop_backpack_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopBackpackScreen', () {
    testWidgets(
        'empty backpack shows empty state and compact active-effects empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: const <BackpackItemViewModel>[],
            onOpenUtilities: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('La mochila está vacía'), findsOneWidget);
      expect(find.text('No tienes efectos activos.'), findsOneWidget);
      expect(find.text('Ir a Utilidades'), findsOneWidget);
    });

    testWidgets('shows a two-column consumables grid',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopBackpackItemsGrid')), findsOneWidget);

      final firstCard =
          find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d'));
      final secondCard =
          find.byKey(const Key('shopBackpackCard-utility_coin_boost_1d'));

      final firstTopLeft = tester.getTopLeft(firstCard);
      final secondTopLeft = tester.getTopLeft(secondCard);

      expect((firstTopLeft.dy - secondTopLeft.dy).abs(), lessThan(1));
      expect(secondTopLeft.dx, greaterThan(firstTopLeft.dx));
    });

    testWidgets(
        'cards do not show long descriptions and quantity appears only once',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
          find.text('Duplica la ganancia de XP durante un día.'), findsNothing);

      final quantityFinder = find.descendant(
        of: find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
        matching: find.text('x2'),
      );
      expect(quantityFinder, findsOneWidget);
    });

    testWidgets('filters change visible items', (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
          findsOneWidget);
      expect(
        find.byKey(const Key('shopBackpackCard-utility_streak_shield_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopBackpackCard-utility_mystery_box_basic')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('shopBackpackFilter-boosts')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
          findsOneWidget);
      expect(
        find.byKey(const Key('shopBackpackCard-utility_coin_boost_1d')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopBackpackCard-utility_streak_shield_1')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopBackpackCard-utility_mystery_box_basic')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('shopBackpackFilter-streaks')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopBackpackCard-utility_streak_recover_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopBackpackCard-utility_streak_shield_1')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('shopBackpackCard-utility_xp_boost_1d')),
          findsNothing);

      await tester.tap(find.byKey(const Key('shopBackpackFilter-boxes')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        find.byKey(const Key('shopBackpackCard-utility_mystery_box_basic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopBackpackCard-utility_streak_recover_1')),
        findsNothing,
      );
    });

    testWidgets('filter with no results shows compact empty state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: const <BackpackItemViewModel>[
              BackpackItemViewModel(
                itemId: 'utility_mystery_box_basic',
                title: 'Mystery Box',
                description:
                    'Una caja misteriosa básica con una sorpresa en su interior.',
                quantity: 1,
                rarity: ShopItemRarity.common,
                type: ShopItemType.mysteryBox,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester.tap(find.byKey(const Key('shopBackpackFilter-boosts')));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopBackpackFilteredEmptyState')),
          findsOneWidget);
      expect(
        find.text('No hay resultados para este filtro.'),
        findsOneWidget,
      );
    });

    testWidgets('active effects are shown in compact horizontal cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            items: _items(),
            activeEffects: const <ActiveUtilityEffect>[
              ActiveUtilityEffect(
                id: 'active-xp-boost',
                utilityId: 'utility_xp_boost_1d',
                type: ActiveUtilityEffectType.xpBoost,
                remainingUses: 9,
                totalUses: 10,
                activatedAtMillis: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byKey(const Key('shopBackpackActiveEffectsList')),
          findsOneWidget);
      expect(find.text('9 de 10 usos restantes'), findsOneWidget);
      expect(find.text('Activo'), findsOneWidget);
      expect(find.text('Boosts en progreso'), findsNothing);
    });

    testWidgets(
        'use button calls callback and mystery box exposes Abrir action',
        (WidgetTester tester) async {
      String? usedItemId;

      await tester.pumpWidget(
        _app(
          _screen(
            items: _items(),
            onUsePressed: (String itemId) async {
              usedItemId = itemId;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await tester
          .tap(find.byKey(const Key('shopBackpackUse-utility_xp_boost_1d')));
      await tester.pump(const Duration(milliseconds: 16));
      expect(usedItemId, 'utility_xp_boost_1d');

      expect(
        find.descendant(
          of: find
              .byKey(const Key('shopBackpackUse-utility_mystery_box_basic')),
          matching: find.text('Abrir'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pending mystery box shows compact recovery action',
        (WidgetTester tester) async {
      var recovered = false;

      await tester.pumpWidget(
        _app(
          _screen(
            items: _items(),
            pendingMysteryBoxOpenings: <MysteryBoxOpeningTransaction>[
              _pendingTransaction(),
            ],
            onContinueMysteryBoxOpening: (_) async {
              recovered = true;
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Tu Mystery Box está lista'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pump(const Duration(milliseconds: 16));

      expect(recovered, isTrue);
    });

    testWidgets('small layouts do not overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(_screen(items: _items())));
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: child,
  );
}

Widget _screen({
  required List<BackpackItemViewModel> items,
  ValueChanged<String>? onItemPressed,
  Future<void> Function(String)? onUsePressed,
  VoidCallback? onOpenUtilities,
  List<MysteryBoxOpeningTransaction> pendingMysteryBoxOpenings =
      const <MysteryBoxOpeningTransaction>[],
  Future<void> Function(MysteryBoxOpeningTransaction)?
      onContinueMysteryBoxOpening,
  List<ActiveUtilityEffect> activeEffects = const <ActiveUtilityEffect>[],
}) {
  return ShopBackpackScreen(
    walletCoins: 420,
    items: items,
    activeEffects: activeEffects,
    pendingMysteryBoxOpenings: pendingMysteryBoxOpenings,
    onBackPressed: () {},
    onItemPressed: onItemPressed ?? (_) {},
    onUsePressed: onUsePressed ?? (_) async {},
    onOpenUtilities: onOpenUtilities,
    onContinueMysteryBoxOpening: onContinueMysteryBoxOpening,
  );
}

List<BackpackItemViewModel> _items() {
  return const <BackpackItemViewModel>[
    BackpackItemViewModel(
      itemId: 'utility_xp_boost_1d',
      title: 'XP Boost 1 Day',
      description: 'Duplica la ganancia de XP durante un día.',
      quantity: 2,
      rarity: ShopItemRarity.common,
      type: ShopItemType.xpBoost,
    ),
    BackpackItemViewModel(
      itemId: 'utility_coin_boost_1d',
      title: 'Coin Boost 1 Day',
      description: 'Duplica la ganancia de monedas durante un día.',
      quantity: 1,
      rarity: ShopItemRarity.common,
      type: ShopItemType.coinBoost,
    ),
    BackpackItemViewModel(
      itemId: 'utility_streak_recover_1',
      title: 'Streak Recovery',
      description: 'Recupera una racha perdida una vez.',
      quantity: 1,
      rarity: ShopItemRarity.rare,
      type: ShopItemType.streakRecover,
    ),
    BackpackItemViewModel(
      itemId: 'utility_streak_shield_1',
      title: 'Streak Shield',
      description: 'Protege una racha frente a un día fallado.',
      quantity: 2,
      rarity: ShopItemRarity.rare,
      type: ShopItemType.streakShield,
    ),
    BackpackItemViewModel(
      itemId: 'utility_mystery_box_basic',
      title: 'Mystery Box',
      description:
          'Una caja misteriosa básica con una sorpresa en su interior.',
      quantity: 3,
      rarity: ShopItemRarity.common,
      type: ShopItemType.mysteryBox,
    ),
  ];
}

MysteryBoxOpeningTransaction _pendingTransaction() {
  return MysteryBoxOpeningTransaction(
    id: 'tx-pending',
    userScope: 'shop-user',
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: MysteryBoxRewardResult(
      rewardId: 'reward_80_coins_40_xp',
      coins: 80,
      xp: 40,
      utilityRewards: <String, int>{},
    ),
    createdAtMillis: 1,
    status: MysteryBoxOpeningStatus.granted,
  );
}
