import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('HabitStep edits name, count, unit and weekly days',
      (tester) async {
    OnboardingHabitConfiguration? submitted;
    await tester.pumpWidget(
      _app(
        OnboardingHabitStep(
          initialConfiguration: OnboardingHabitConfiguration(
            name: 'Read',
            emoji: '📖',
            primaryFamilyCode: 'mind',
            kind: HabitKind.check,
            schedule: HabitSchedule.daily(),
          ),
          onSubmit: (value) => submitted = value,
        ),
      ),
    );

    await tester.enterText(
        find.byKey(const ValueKey('onboardingHabitName')), 'Read 10 pages');
    await tester.scrollUntilVisible(
      find.text('Contador'),
      240,
      scrollable: _verticalScrollables,
    );
    await tester.tap(find.text('Contador').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('onboardingHabitTarget')));
    await tester.pump();
    await tester.enterText(find.byType(CupertinoTextField), '10');
    await tester.tap(find.text('Guardar'));
    tester.testTextInput.hide();
    await tester.pump();
    await tester.ensureVisible(find.text('páginas').first);
    await tester.tap(find.text('páginas').first);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Días concretos'),
      240,
      scrollable: _verticalScrollables,
    );
    await tester.tap(find.text('Días concretos').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('onboardingHabitWeekday_1')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('onboardingHabitWeekday_1')),
    );

    tester
        .state<OnboardingHabitStepState>(
          find.byType(OnboardingHabitStep),
        )
        .submit();

    expect(submitted?.name, 'Read 10 pages');
    expect(submitted?.kind, HabitKind.count);
    expect(submitted?.targetValue, 10);
    expect(submitted?.unit, 'páginas');
    expect(submitted?.schedule.type, HabitScheduleType.weekly);
    expect(submitted?.schedule.weekdays, [2, 3, 4, 5, 6, 7]);
  });

  testWidgets('HabitStep remains scrollable on a compact scaled screen',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
        child: _app(
          OnboardingHabitStep(
            initialConfiguration: OnboardingHabitConfiguration.custom(),
            onSubmit: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsAtLeastNWidgets(1));
  });
}

final Finder _verticalScrollables = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axis == Axis.vertical,
);

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: child,
        ),
      ),
    ),
  );
}
