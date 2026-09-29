import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

void main() {
  test('all Premium strings are generated for Spanish and English', () {
    final locales = <String Function()>[
      for (final l10n in <AppLocalizations>[
        AppLocalizationsEs(),
        AppLocalizationsEn(),
      ]) ...[
        () => l10n.premiumSectionTitle,
        () => l10n.premiumTitle,
        () => l10n.premiumSettingsSubtitle,
        () => l10n.premiumSubtitle,
        () => l10n.premiumBenefitWeekly,
        () => l10n.premiumBenefitMonthly,
        () => l10n.premiumBenefitAnnual,
        () => l10n.premiumBenefitByHabit,
        () => l10n.premiumBenefitReport,
        () => l10n.premiumRetry,
        () => l10n.premiumActive,
        () => l10n.premiumActiveSubtitle,
        () => l10n.premiumSignInRequired,
        () => l10n.premiumUnavailable,
        () => l10n.premiumGenericError,
      ],
    ];

    for (final getter in locales) {
      expect(getter, returnsNormally);
      expect(getter(), isNotEmpty);
    }
  });
}
