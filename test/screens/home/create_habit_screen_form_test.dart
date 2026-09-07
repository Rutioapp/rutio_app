import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/screens/home/ui/create_habit_screen.dart';

void main() {
  testWidgets('Create uses the shared flexible weekly check section',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CreateHabitScreen(initialFamilyId: 'mind'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('X veces / semana'),
      240,
      scrollable: find.byWidgetPredicate(
        (widget) => widget is Scrollable && widget.axis == Axis.vertical,
      ),
    );
    await tester.tap(find.text('X veces / semana').first);
    await tester.pumpAndSettle();

    expect(find.text('Objetivo semanal'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
