import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/diary_v2/widgets/diary_v2_header.dart';

void main() {
  testWidgets('keeps title visually centered with right action present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DiaryV2Header(
            title: 'Diario',
            subtitle: 'Tu espacio para recordar el día.',
            onMenuTap: () {},
            onAllEntriesTap: () {},
            allEntriesTooltip: 'Todas las entradas',
          ),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text('Diario'));
    final scaffoldRect = tester.getRect(find.byType(Scaffold));

    expect(
      (titleRect.center.dx - scaffoldRect.center.dx).abs(),
      lessThanOrEqualTo(1),
    );
    expect(find.byTooltip('Todas las entradas'), findsOneWidget);
  });
}
