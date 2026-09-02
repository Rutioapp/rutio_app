import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/widgets/weekly_report_habits_section.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('groups habits collapsed by default and expands in backend order',
      (tester) async {
    final habits = [
      _habit('Correr', '🏃',
          scheduled: 3,
          completed: 3,
          rate: 1,
          classification: WeeklyReportHabitClassification.highlighted),
      _habit('Beber agua', '💧',
          scheduled: 7,
          completed: 6,
          rate: 6 / 7,
          classification: WeeklyReportHabitClassification.stable),
      _habit('Nombre del reporte', '📖',
          scheduled: 4,
          completed: 2,
          rate: .5,
          occurrence: _occurrence(DateTime(2026, 8, 31), partial: true),
          classification: WeeklyReportHabitClassification.needsAttention),
    ];

    await tester.pumpWidget(_app(habits, width: 390));

    expect(find.text('Hábitos de la semana'), findsOneWidget);
    expect(find.text('Destacados'), findsOneWidget);
    expect(find.text('Estables'), findsOneWidget);
    expect(find.text('Necesitan atención'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    expect(find.text('Correr'), findsNothing);

    await tester.tap(find.text('Destacados'));
    await tester.pumpAndSettle();
    expect(find.text('Correr'), findsOneWidget);
    expect(find.text('Beber agua'), findsNothing);
    expect(find.text('Destacado'), findsNothing);
    expect(find.text('3/3 · 100%'), findsOneWidget);

    await tester.tap(find.text('Estables'));
    await tester.pumpAndSettle();
    expect(find.text('Beber agua'), findsOneWidget);
    expect(find.text('Correr'), findsOneWidget);

    await tester.tap(find.text('Destacados'));
    await tester.pumpAndSettle();
    expect(find.text('Correr'), findsNothing);
    await tester.tap(find.text('Necesitan atención'));
    await tester.pumpAndSettle();
    expect(find.text('Nombre del reporte'), findsOneWidget);
    expect(find.text('6/7 · 86%'), findsOneWidget);
    expect(find.text('2/4 · 50%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero scheduled is neutral and nullable streak is hidden',
      (tester) async {
    await tester.pumpWidget(_app([
      _habit('Sin plan', '🪴',
          scheduled: 0,
          completed: 0,
          rate: null,
          classification: WeeklyReportHabitClassification.unavailable),
    ], width: 390));
    expect(find.text('Sin programación esta semana'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(3));
    expect(find.text('Sin plan'), findsNothing);
    await tester.tap(find.text('Sin programación esta semana'));
    await tester.pumpAndSettle();
    expect(find.text('Sin plan'), findsOneWidget);
    expect(find.textContaining('0%'), findsNothing);
    expect(find.textContaining('racha'), findsNothing);
  });

  testWidgets('shows backend streak only when snapshot provides it',
      (tester) async {
    await tester.pumpWidget(_app([
      _habit('Con racha', '🔥',
          scheduled: 2,
          completed: 2,
          rate: 1,
          streak: const HabitStreakSnapshot(
              habitId: 'h',
              currentStreak: 4,
              bestStreak: 6,
              totalCompletedDays: 9)),
    ], width: 390));
    await tester.tap(find.text('Estables'));
    await tester.pumpAndSettle();
    expect(find.text('4 racha'), findsOneWidget);
  });

  testWidgets(
      'times per week uses weekly denominator and no artificial failures',
      (tester) async {
    final habit = _habit('Tres veces', '🔁',
        scheduled: 3,
        completed: 2,
        rate: 2 / 3,
        schedule: HabitSchedule.timesPerWeek(timesPerWeek: 3),
        occurrences: [
          _occurrence(DateTime(2026, 8, 31)),
          _occurrence(DateTime(2026, 9, 2)),
        ]);
    await tester.pumpWidget(_app([habit], width: 390));
    await tester.tap(find.text('Estables'));
    await tester.pumpAndSettle();
    expect(find.text('2/3 · 67%'), findsOneWidget);
    expect(find.text('3/3 · 100%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('days distinguish skipped, partial and incomplete',
      (tester) async {
    await tester.pumpWidget(_app([
      _habit('Estados', '🎯',
          scheduled: 3,
          completed: 0,
          rate: 0,
          classification: WeeklyReportHabitClassification.needsAttention,
          occurrences: [
            _occurrence(DateTime(2026, 8, 31), completed: false, skipped: true),
            _occurrence(DateTime(2026, 9, 1), completed: false, partial: true),
            _occurrence(DateTime(2026, 9, 2), completed: false),
          ]),
    ], width: 390));
    await tester.tap(find.text('Necesitan atención'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('lunes: omitido')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('martes: parcial')), findsOneWidget);
    expect(
        find.bySemanticsLabel(RegExp('miercoles: pendiente')), findsOneWidget);
  });

  testWidgets('narrow width and large text scale do not overflow',
      (tester) async {
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
      child: _app([
        _habit('Un nombre de hábito suficientemente largo', '📝',
            scheduled: 7,
            completed: 5,
            rate: 5 / 7,
            occurrence: _occurrence(DateTime(2026, 8, 31), skipped: true)),
      ], width: 340),
    ));
    await tester.tap(find.text('Necesitan atención'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('does not reclassify and keeps empty groups visible',
      (tester) async {
    await tester.pumpWidget(_app([
      _habit('Destacado por backend', '⭐',
          scheduled: 2,
          completed: 0,
          rate: 0,
          classification: WeeklyReportHabitClassification.highlighted),
    ], width: 390));
    expect(find.text('Destacados'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('Destacado por backend'), findsNothing);
    await tester.tap(find.text('Destacados'));
    await tester.pumpAndSettle();
    expect(find.text('Destacado por backend'), findsOneWidget);
  });
}

Widget _app(List<WeeklyReportHabit> habits, {required double width}) =>
    MaterialApp(
      locale: const Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
            width: width, child: WeeklyReportHabitsSection(habits: habits)),
      ),
    );

WeeklyReportHabit _habit(String name, String emoji,
        {required int scheduled,
        required int completed,
        required double? rate,
        HabitSchedule? schedule,
        HabitOccurrenceResult? occurrence,
        List<HabitOccurrenceResult>? occurrences,
        HabitStreakSnapshot? streak,
        WeeklyReportHabitClassification classification =
            WeeklyReportHabitClassification.stable}) =>
    WeeklyReportHabit(
      habitId: name,
      name: name,
      emoji: emoji,
      type: HabitKind.check,
      schedule: schedule ?? HabitSchedule.daily(),
      scheduledCount: scheduled,
      completedCount: completed,
      skippedCount: 0,
      completionRate: rate,
      classification: classification,
      occurrences:
          occurrences ?? (occurrence == null ? const [] : [occurrence]),
      streakSnapshot: streak,
    );

HabitOccurrenceResult _occurrence(DateTime date,
        {bool completed = true, bool skipped = false, bool partial = false}) =>
    HabitOccurrenceResult(
      date: date,
      scope: HabitOccurrenceScope.dateBound,
      scheduleType: HabitScheduleType.daily,
      scheduled: true,
      completed: completed,
      skipped: skipped,
      progress: partial ? 1 : null,
      target: partial ? 2 : null,
    );
