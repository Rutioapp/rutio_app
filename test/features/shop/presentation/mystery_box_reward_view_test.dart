import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_reward_view.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MysteryBoxRewardView', () {
    testWidgets(
        'renders mixed currency rewards clearly without a general gift icon',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          MysteryBoxRewardView(
            transaction: _transaction(
              reward: MysteryBoxRewardResult(
                rewardId: 'reward_currency_mix',
                coins: 125,
                xp: 40,
                utilityRewards: <String, int>{},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Tu recompensa'), findsOneWidget);
      expect(find.text('125 monedas'), findsOneWidget);
      expect(find.text('40 XP'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsNothing);
      expect(find.byType(AmberCoinIcon), findsOneWidget);
      expect(find.byIcon(Icons.auto_graph_rounded), findsOneWidget);
    });

    testWidgets('renders utility rewards inside the reward modal body',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        _app(
          MysteryBoxRewardView(
            transaction: _transaction(
              reward: MysteryBoxRewardResult(
                rewardId: 'reward_utility_mix',
                coins: 30,
                xp: 0,
                utilityRewards: <String, int>{
                  'utility_xp_boost_1d': 2,
                },
              ),
            ),
            showIntroCopy: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Potenciador de XP de 1 día'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('30 monedas'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard_rounded), findsNothing);
      expect(find.byType(AmberCoinIcon), findsOneWidget);
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
      body: Center(
        child: SizedBox(
          width: 420,
          child: child,
        ),
      ),
    ),
  );
}

MysteryBoxOpeningTransaction _transaction({
  required MysteryBoxRewardResult reward,
}) {
  return MysteryBoxOpeningTransaction(
    id: 'tx-reward',
    userScope: 'shop-user',
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: reward,
    createdAtMillis: 1,
    status: MysteryBoxOpeningStatus.granted,
  );
}
