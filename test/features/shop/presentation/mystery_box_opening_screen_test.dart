import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/presentation/screens/mystery_box_opening_screen.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_hero_view.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MysteryBoxOpeningScreen', () {
    testWidgets('renders as an immersive fullscreen opening surface',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(onClose: () {})));
      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      final heroSizing = tester.widget<FractionallySizedBox>(
        find.byKey(const Key('mysteryBoxHeroSizing')),
      );

      expect(scaffold.backgroundColor, const Color(0xFFF6EFE8));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      expect(find.byType(Card), findsNothing);
      expect(find.byType(ClipRRect), findsNothing);
      expect(find.byType(DecoratedBox), findsNothing);
      expect(find.text('Mystery Box'), findsNothing);
      expect(find.text('Tu Mystery Box esta lista'), findsNothing);
      expect(find.text('Pulsa para abrir'), findsOneWidget);
      expect(find.byKey(const Key('mysteryBoxOpenButton')), findsNothing);
      expect(find.byKey(const Key('mysteryBoxCloseButton')), findsNothing);
      expect(
        find.byKey(const Key('mysteryBoxFullscreenImage')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('mysteryBoxInteractionLayer')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('mysteryBoxRevealOverlay')), findsOneWidget);
      expect(heroSizing.widthFactor, 0.78);
      expect(_currentAssetName(tester), MysteryBoxHeroView.defaultAssetPath);
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('mysteryBoxFlashOverlay')))
            .opacity,
        0,
      );
    });

    testWidgets('idle state animates the box and text before opening',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(onClose: () {})));
      await tester.pump();

      final initialBoxScale = _uniformScaleFor(
        tester,
        const Key('mysteryBoxIdleScale'),
      );
      final initialRotationEntry = _rotationEntryFor(
        tester,
        const Key('mysteryBoxIdleRotation'),
      );
      final initialTextScale = _uniformScaleFor(
        tester,
        const Key('mysteryBoxTapTextScale'),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(
        _uniformScaleFor(tester, const Key('mysteryBoxIdleScale')),
        isNot(closeTo(initialBoxScale, 0.0001)),
      );
      expect(
        _rotationEntryFor(tester, const Key('mysteryBoxIdleRotation')),
        isNot(closeTo(initialRotationEntry, 0.0001)),
      );
      expect(
        _uniformScaleFor(tester, const Key('mysteryBoxTapTextScale')),
        isNot(closeTo(initialTextScale, 0.0001)),
      );
    });

    testWidgets('reduced motion disables the looping idle animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: _app(_screen(onClose: () {})),
        ),
      );
      await tester.pump();

      final initialBoxScale = _uniformScaleFor(
        tester,
        const Key('mysteryBoxIdleScale'),
      );
      final initialRotationEntry = _rotationEntryFor(
        tester,
        const Key('mysteryBoxIdleRotation'),
      );
      final initialTextScale = _uniformScaleFor(
        tester,
        const Key('mysteryBoxTapTextScale'),
      );

      await tester.pump(const Duration(milliseconds: 1000));

      expect(
        _uniformScaleFor(tester, const Key('mysteryBoxIdleScale')),
        closeTo(initialBoxScale, 0.0001),
      );
      expect(
        _rotationEntryFor(tester, const Key('mysteryBoxIdleRotation')),
        closeTo(initialRotationEntry, 0.0001),
      );
      expect(
        _uniformScaleFor(tester, const Key('mysteryBoxTapTextScale')),
        closeTo(initialTextScale, 0.0001),
      );
    });

    testWidgets('successful tap opens once and reveals the reward sheet',
        (WidgetTester tester) async {
      var openCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () async {
              openCount += 1;
              return _successResult();
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();

      expect(openCount, 1);
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsNothing);
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('mysteryBoxTapTextOpacity')),
            )
            .opacity,
        0,
      );
      expect(_currentAssetName(tester), MysteryBoxHeroView.defaultAssetPath);

      await tester.pump(const Duration(milliseconds: 180));
      expect(_currentAssetName(tester), MysteryBoxHeroView.defaultAssetPath);

      await tester.pump(const Duration(milliseconds: 80));

      final duringFlash = tester
          .widget<Opacity>(find.byKey(const Key('mysteryBoxFlashOverlay')));
      expect(duringFlash.opacity, greaterThanOrEqualTo(0.94));
      expect(_currentAssetName(tester), MysteryBoxHeroView.openedAssetPath);

      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('mysteryBoxFlashOverlay')))
            .opacity,
        greaterThanOrEqualTo(0.94),
      );
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsNothing);

      await tester.pump(const Duration(milliseconds: 600));
      expect(_currentAssetName(tester), MysteryBoxHeroView.openedAssetPath);
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsNothing);

      await _pumpUntilRewardVisible(tester);

      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsOneWidget);
      expect(find.byKey(const Key('mysteryBoxRewardView')), findsOneWidget);
      expect(find.text('Tu recompensa'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsNothing);
      expect(
        tester
            .widget<Opacity>(find.byKey(const Key('mysteryBoxFlashOverlay')))
            .opacity,
        0,
      );
    });

    testWidgets('tapping anywhere on the screen triggers the opening flow',
        (WidgetTester tester) async {
      var openCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () async {
              openCount += 1;
              return _successResult();
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tapAt(const Offset(30, 30));
      await tester.pump();
      await _pumpUntilRewardVisible(tester);

      expect(openCount, 1);
      expect(_currentAssetName(tester), MysteryBoxHeroView.openedAssetPath);
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsOneWidget);
    });

    testWidgets('duplicate taps do not trigger multiple openings',
        (WidgetTester tester) async {
      final completer = Completer<MysteryBoxOperationResult>();
      var openCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () {
              openCount += 1;
              return completer.future;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();

      expect(openCount, 1);
    });

    testWidgets('interaction stays disabled while the opening is in progress',
        (WidgetTester tester) async {
      final completer = Completer<MysteryBoxOperationResult>();
      var openCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () {
              openCount += 1;
              return completer.future;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();

      expect(openCount, 1);
      expect(
        tester
            .widget<GestureDetector>(
              find.byKey(const Key('mysteryBoxInteractionLayer')),
            )
            .onTap,
        isNull,
      );
    });

    testWidgets('tap text disappears when the opening starts',
        (WidgetTester tester) async {
      final completer = Completer<MysteryBoxOperationResult>();

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () => completer.future,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pulsa para abrir'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const Key('mysteryBoxTapTextOpacity')),
            )
            .opacity,
        0,
      );
    });

    testWidgets('existing transaction skips open request and reveals reward',
        (WidgetTester tester) async {
      var openCount = 0;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            transaction: _transaction(),
            onOpenRequested: () async {
              openCount += 1;
              return _successResult();
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await _pumpUntilRewardVisible(tester);

      expect(openCount, 0);
      expect(_currentAssetName(tester), MysteryBoxHeroView.openedAssetPath);
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsOneWidget);
    });

    testWidgets('open failures show a recoverable error state',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {},
            onOpenRequested: () async {
              return const MysteryBoxOperationResult(
                status: MysteryBoxOperationStatus.persistenceError,
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      await tester.pump(const Duration(milliseconds: 160));

      expect(
        find.text('No pudimos guardar la apertura. Inténtalo otra vez.'),
        findsOneWidget,
      );
      expect(find.text('Pulsa para abrir'), findsOneWidget);
      expect(_currentAssetName(tester), MysteryBoxHeroView.defaultAssetPath);
      expect(find.byKey(const Key('mysteryBoxRewardSheet')), findsNothing);
      expect(
        tester
            .widget<GestureDetector>(
              find.byKey(const Key('mysteryBoxInteractionLayer')),
            )
            .onTap,
        isNotNull,
      );
    });

    testWidgets('continue marks the reward as presented before closing',
        (WidgetTester tester) async {
      var closed = false;
      MysteryBoxOpeningTransaction? presentedTransaction;

      await tester.pumpWidget(
        _app(
          _screen(
            onClose: () {
              closed = true;
            },
            transaction: _transaction(),
            onMarkPresented: (MysteryBoxOpeningTransaction transaction) async {
              presentedTransaction = transaction;
              return true;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('mysteryBoxInteractionLayer')));
      await tester.pump();
      await _pumpUntilRewardVisible(tester);

      final continueButton = tester.widget<ShopPrimaryButton>(
        find.byKey(const Key('mysteryBoxContinueButton')),
      );
      continueButton.onPressed!.call();
      await tester.pump();

      expect(closed, isTrue);
      expect(presentedTransaction?.id, 'tx-1');
    });

    testWidgets('does not render the legacy opening frame',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(_screen(onClose: () {})));
      await tester.pump();

      final image = tester.widget<Image>(
        find.descendant(
          of: find.byKey(const Key('mysteryBoxFullscreenImage')),
          matching: find.byType(Image),
        ),
      );

      expect(_currentAssetName(tester), MysteryBoxHeroView.defaultAssetPath);
      expect(image.fit, BoxFit.contain);
      expect(image.alignment, Alignment.center);
      expect(
        tester
            .widget<FractionallySizedBox>(
              find.byKey(const Key('mysteryBoxHeroSizing')),
            )
            .widthFactor,
        0.78,
      );
    });

    testWidgets('small layouts with larger text do not overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
          child: _app(_screen(onClose: () {})),
        ),
      );
      await tester.pump();

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
  required VoidCallback onClose,
  MysteryBoxOpeningTransaction? transaction,
  MysteryBoxOpenRequest? onOpenRequested,
  MysteryBoxMarkPresented? onMarkPresented,
}) {
  return MysteryBoxOpeningScreen(
    transaction: transaction,
    onClose: onClose,
    onOpenRequested: onOpenRequested,
    onMarkPresented: onMarkPresented,
    hapticPlayer: (_) async {},
  );
}

MysteryBoxOperationResult _successResult() {
  return MysteryBoxOperationResult(
    status: MysteryBoxOperationStatus.success,
    transaction: _transaction(),
  );
}

MysteryBoxOpeningTransaction _transaction() {
  return MysteryBoxOpeningTransaction(
    id: 'tx-1',
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

String _currentAssetName(WidgetTester tester) {
  final imageFinder = find.descendant(
    of: find.byKey(const Key('mysteryBoxFullscreenImage')),
    matching: find.byType(Image),
  );
  final image = tester.widget<Image>(imageFinder.first);
  final provider = image.image as AssetImage;
  return provider.assetName;
}

double _uniformScaleFor(WidgetTester tester, Key key) {
  final transform = tester.widget<Transform>(find.byKey(key));
  return transform.transform.getMaxScaleOnAxis();
}

double _rotationEntryFor(WidgetTester tester, Key key) {
  final transform = tester.widget<Transform>(find.byKey(key));
  final Matrix4 matrix = transform.transform;
  return matrix.storage[1];
}

Future<void> _pumpUntilRewardVisible(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 1250));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pumpAndSettle();
}
