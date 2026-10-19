import 'package:flutter_test/flutter_test.dart';

import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

void main() {
  test('uses account creation copy for Google in Spanish', () {
    expect(AppLocalizationsEs().onboardingAuthGoogleCta,
        'Crear cuenta con Google');
    expect(AppLocalizationsEs().loginGoogleCta, 'Continuar con Google');
  });

  test('uses account creation copy for Google in English', () {
    expect(AppLocalizationsEn().onboardingAuthGoogleCta,
        'Create account with Google');
    expect(AppLocalizationsEn().loginGoogleCta, 'Continue with Google');
  });
}
