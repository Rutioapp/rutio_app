import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_opening_sheet.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MysteryBoxOpeningSheet', () {
    testWidgets('keeps safe area and shows a compact reward composition',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          MysteryBoxOpeningSheet(
            transaction: _transaction(),
            isPresenting: false,
            onContinue: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Tu recompensa'), findsOneWidget);
      expect(find.text('Aceptar'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsNothing);

      final descriptionBottom = tester
          .getBottomLeft(
            find.text(
              'La apertura ha terminado. Todo ya está guardado en tu cuenta y en tu mochila.',
            ),
          )
          .dy;
      final rewardTop = tester
          .getTopLeft(
            find.byKey(const Key('mysteryBoxRewardView')),
          )
          .dy;

      expect(rewardTop - descriptionBottom, inInclusiveRange(24.0, 32.0));
    });
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: AppTheme.theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('es'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 420,
          child: child,
        ),
      ),
    ),
  );
}

MysteryBoxOpeningTransaction _transaction() {
  return MysteryBoxOpeningTransaction(
    id: 'tx-sheet',
    userScope: 'shop-user',
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: MysteryBoxRewardResult(
      rewardId: 'reward_sheet',
      coins: 80,
      xp: 40,
      utilityRewards: <String, int>{},
    ),
    createdAtMillis: 1,
    status: MysteryBoxOpeningStatus.granted,
  );
}
