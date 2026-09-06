import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/onboarding/onboarding.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('Name keeps the baseline layout without keyboard',
      (tester) async {
    await _pumpWithViewport(
      tester,
      const Size(800, 600),
      const MediaQueryData(),
      OnboardingShell(
        step: OnboardingStep.name,
        progress: 0.14,
        canGoBack: false,
        isBusy: false,
        onBack: () {},
        onContinue: () {},
        content: OnboardingNameStep(
          initialValue: '',
          onSubmit: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Continuar'), findsOneWidget);
  });

  testWidgets('Name stays scrollable and CTA reachable with keyboard',
      (tester) async {
    bool continued = false;
    await _pumpWithViewport(
      tester,
      const Size(800, 600),
      const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
      OnboardingShell(
        step: OnboardingStep.name,
        progress: 0.14,
        canGoBack: false,
        isBusy: false,
        onBack: () {},
        onContinue: () => continued = true,
        content: OnboardingNameStep(
          initialValue: '',
          onSubmit: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsAtLeastNWidgets(1));
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    expect(continued, isTrue);
  });

  testWidgets('Name handles compact viewport plus keyboard', (tester) async {
    await _pumpWithViewport(
      tester,
      const Size(320, 568),
      const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 260)),
      OnboardingShell(
        step: OnboardingStep.name,
        progress: 0.14,
        canGoBack: false,
        isBusy: false,
        onBack: () {},
        onContinue: () {},
        content: OnboardingNameStep(
          initialValue: '',
          onSubmit: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continuar'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Name handles Dynamic Type plus keyboard', (tester) async {
    await _pumpWithViewport(
      tester,
      const Size(800, 600),
      const MediaQueryData(
        textScaler: TextScaler.linear(1.6),
        viewInsets: EdgeInsets.only(bottom: 280),
      ),
      OnboardingShell(
        step: OnboardingStep.name,
        progress: 0.14,
        canGoBack: false,
        isBusy: false,
        onBack: () {},
        onContinue: () {},
        content: OnboardingNameStep(
          initialValue: '',
          onSubmit: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsAtLeastNWidgets(1));
    await tester.ensureVisible(find.text('Continuar'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Habit form stays scrollable with keyboard and CTA reachable',
      (tester) async {
    await _pumpWithViewport(
      tester,
      const Size(800, 600),
      const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 280)),
      OnboardingShell(
        step: OnboardingStep.habit,
        progress: 0.86,
        canGoBack: true,
        isBusy: false,
        onBack: () {},
        onContinue: () {},
        content: OnboardingHabitStep(
          initialConfiguration: OnboardingHabitConfiguration(
            name: 'Leer',
            emoji: '📖',
            primaryFamilyCode: 'mind',
            kind: HabitKind.count,
            schedule: HabitSchedule.daily(),
            targetValue: 10,
            unit: 'páginas',
          ),
          onSubmit: (_) {},
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('onboardingHabitName')));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsAtLeastNWidgets(1));
    await tester.ensureVisible(find.text('Continuar'));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpWithViewport(
  WidgetTester tester,
  Size surfaceSize,
  MediaQueryData mediaQueryData,
  Widget child,
) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
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
      home: MediaQuery(
        data: mediaQueryData,
        child: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
