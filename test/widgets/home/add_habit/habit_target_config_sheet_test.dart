import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/widgets/home/add_habit/habit_target_config_sheet.dart';

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('supports count selection, target stepper and weekly result',
      (tester) async {
    HabitTargetConfigResult? result;

    await tester.pumpWidget(
      _testApp(
        Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showHabitTargetConfigSheet(
                    context: context,
                    habitDef: <String, dynamic>{
                      'id': 'meditate',
                      'name': 'Meditate',
                      'emoji': '🧘',
                      'type': 'count_or_check',
                      'metric': <String, dynamic>{
                        'unit': 'minutes',
                        'default': 10,
                      },
                    },
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Meditate'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    await tester.tap(find.byIcon(CupertinoIcons.add).first);
    await tester.pumpAndSettle();

    expect(find.text('15'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Semanal'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Semanal'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('L'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('L'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Añadir'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.type, 'count');
    expect(result!.target, 15);
    expect(result!.scheduleType, 'weekly');
    expect(result!.weekdays, <int>[2, 3, 4, 5, 6, 7]);
  });
}
