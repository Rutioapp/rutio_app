import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shop localization helpers', () {
    testWidgets('resolve utility titles in Spanish and English',
        (WidgetTester tester) async {
      final xpBoost = ShopCatalog.getItemById('utility_xp_boost_1d')!;
      final mysteryBox = ShopCatalog.getItemById('utility_mystery_box_basic')!;

      await tester.pumpWidget(
        _app(
          const Locale('es'),
          Builder(
            builder: (BuildContext context) {
              final l10n = AppLocalizations.of(context);
              expect(
                l10n.shopUtilityTitleForItem(xpBoost),
                'Potenciador de XP de 1 día',
              );
              expect(
                l10n.shopUtilityTitleForItem(mysteryBox),
                'Caja misteriosa',
              );
              expect(l10n.shopUtilityDurationHours(2), '2 horas');
              expect(l10n.shopUtilityCharges(1), '1 uso');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _app(
          const Locale('en'),
          Builder(
            builder: (BuildContext context) {
              final l10n = AppLocalizations.of(context);
              expect(l10n.shopUtilityTitleForItem(xpBoost), 'XP Boost 1 Day');
              expect(l10n.shopUtilityTitleForItem(mysteryBox), 'Mystery Box');
              expect(l10n.shopUtilityDurationHours(2), '2 hours');
              expect(l10n.shopUtilityCharges(1), '1 use');
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pump();
    });
  });
}

Widget _app(Locale locale, Widget child) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
