import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/data/shop_cosmetics_repository.dart';
import 'package:rutio/features/shop/domain/models/shop_cosmetics_state.dart';
import 'package:rutio/features/shop/presentation/screens/shop_cosmetics_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopCosmeticsScreen', () {
    testWidgets('shows cosmetics catalog with assets and packs',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Cosméticos'), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
    });

    testWidgets('tabs filter wallpapers cards and packs correctly',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-wallpapers')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-user_card_warm_beige')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
        findsNothing,
      );
    });

    testWidgets(
        'habit card catalog card renders only background swatch without applied content',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      final card = find.byKey(
        const Key('shopCosmeticsAssetCard-habit_card_warm_beige'),
      );

      expect(card, findsOneWidget);
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopAssetVisualPreview-habit_card_warm_beige'),
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: card,
          matching: find.byKey(
            const Key('shopHabitCardAppliedPreview-habit_card_warm_beige'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('Leer 10 min')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('07:30')),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.text('3/7 esta semana')),
        findsNothing,
      );
    });

    testWidgets('locked states show Comprar and packs stay visible',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
    });

    testWidgets('partially owned packs show the blocked state',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_rutio_beige'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();

      expect(find.text('Ya tienes parte de este pack'), findsOneWidget);
      expect(
        find.byKey(const Key('shopCosmeticsAction-pack_beige_rutio')),
        findsNothing,
      );
    });

    testWidgets('owned asset hides CTA and equipped asset shows state only',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>[
            'wallpaper_mist_blue',
            'habit_card_warm_beige',
          ],
          ownedBundleIds: const <String>[],
          equippedHabitCardSkinId: 'habit_card_warm_beige',
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.byKey(
            const Key('shopCosmeticsAction-wallpaper_mist_blue'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprado'),
        ),
        findsWidgets,
      );

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-habit_card_warm_beige'),
          ),
          matching: find.text('Equipado'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-habit_card_warm_beige'),
          ),
          matching: find.byKey(
            const Key('shopCosmeticsAction-habit_card_warm_beige'),
          ),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping Comprar opens confirmation and does not buy yet',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const Key(
              'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('canceling asset confirmation does not buy item',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shopCosmeticsPurchaseConfirmationCancel')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprar'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming asset purchase updates state to equipable',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAction-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key(
              'shopCosmeticsPurchaseConfirmationConfirm-wallpaper_mist_blue'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.byKey(
            const Key('shopCosmeticsAction-wallpaper_mist_blue'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprado'),
        ),
        findsWidgets,
      );
    });

    testWidgets('insufficient balance does not allow purchase',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 10);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Saldo insuficiente'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('purchased asset keeps owned state without CTA in card',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.byKey(
            const Key('shopCosmeticsAction-wallpaper_mist_blue'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const Key('shopCosmeticsAssetCard-wallpaper_mist_blue'),
          ),
          matching: find.text('Comprado'),
        ),
        findsWidgets,
      );
    });

    testWidgets('unowned cosmetics appear before owned cosmetics',
        (WidgetTester tester) async {
      final controller = await _createController(
        walletCoins: 600,
        cosmeticsState: ShopCosmeticsState(
          ownedAssetIds: const <String>['wallpaper_mist_blue'],
          ownedBundleIds: const <String>[],
        ),
      );

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      final double ownedDy = tester
          .getTopLeft(
            find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
          )
          .dy;
      final double unownedDy = tester
          .getTopLeft(
            find.byKey(
                const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
          )
          .dy;

      expect(unownedDy <= ownedDy, isTrue);
    });

    testWidgets('detail sheet shows rarity and packs filter shows packs',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('shopCosmeticsAssetCard-wallpaper_mist_blue')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(find.byKey(const Key('shopCosmeticsRarity-common')), findsWidgets);

      Navigator.of(
        tester.element(find.byKey(const Key('shopCosmeticsDetailSheet'))),
      ).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-packs')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('shopCosmeticsBundleCard-pack_beige_rutio')),
        findsOneWidget,
      );
      expect(find.text('Nada por mostrar'), findsNothing);
    });

    testWidgets('habit card detail sheet keeps applied preview',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(
        find.byKey(
            const Key('shopHabitCardAppliedPreview-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(find.text('Leer 10 min'), findsOneWidget);
    });

    testWidgets('user card detail sheet keeps applied preview',
        (WidgetTester tester) async {
      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('shopCosmeticsAssetCard-user_card_warm_beige')),
      );
      await tester.tap(
        find.byKey(const Key('shopCosmeticsAssetCard-user_card_warm_beige')),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('shopCosmeticsDetailSheet')), findsOneWidget);
      expect(
        find.byKey(
            const Key('shopUserCardAppliedPreview-user_card_warm_beige')),
        findsOneWidget,
      );
      expect(find.text('Rutio User'), findsOneWidget);
    });

    testWidgets(
        'small-width cosmetics grid keeps habit card products stable without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final controller = await _createController(walletCoins: 600);

      await tester
          .pumpWidget(_app(ShopCosmeticsScreen(controller: controller)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('shopCosmeticsFilter-cards')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('shopCosmeticsAssetCard-habit_card_warm_beige')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('es'),
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

Future<ShopCosmeticsController> _createController({
  required int walletCoins,
  ShopCosmeticsState cosmeticsState = const ShopCosmeticsState.initial(),
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await ShopCosmeticsRepository().save(cosmeticsState);

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('shop-cosmetics-screen-user');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(walletCoins: walletCoins));

  return ShopCosmeticsController(userStateStore: store);
}

Map<String, dynamic> _baseState({
  required int walletCoins,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': 'shop-cosmetics-screen-user',
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': DateTime.now().toUtc().toIso8601String(),
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': walletCoins},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': '2026-07-06',
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': <dynamic>[],
    },
  };
}
