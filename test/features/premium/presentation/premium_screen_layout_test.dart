import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/domain/premium_access.dart';
import 'package:rutio/features/premium/presentation/premium_screen.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('premium fallback status renders in a finite phone viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [AppLocalizations.delegate],
        supportedLocales: AppLocalizations.supportedLocales,
        home: PremiumScreen(
          fallback: true,
          accessStateOverride: PremiumAccessState.unknown(),
          onRetry: _noop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rutio Premium'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
}

void _noop() {}
