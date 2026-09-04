import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/widgets/weekly_report_recommendation.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';

void main() {
  testWidgets('productive fixture renders the recommendation and CTA only',
      (tester) async {
    var reviewCalls = 0;
    await tester.pumpWidget(_app(
      recommendation: _fixture(),
      habit: _habit(),
      onReview: () => reviewCalls += 1,
    ));

    expect(
        find.text('Un pequeño ajuste para la próxima semana'), findsOneWidget);
    expect(find.text('Revisar ajuste'), findsOneWidget);
    expect(find.text('Leer'), findsOneWidget);
    expect(reviewCalls, 0);

    await tester.tap(find.text('Revisar ajuste'));
    await tester.pump();
    expect(reviewCalls, 1);
  });

  testWidgets('fixture keeps CTA disabled when no compatible live habit exists',
      (tester) async {
    await tester.pumpWidget(_app(
      recommendation: _fixture(habitId: null),
      habit: null,
      onReview: () {},
    ));

    expect(
        find.text('Un pequeño ajuste para la próxima semana'), findsOneWidget);
    final button = tester.widget<TextButton>(find.byType(TextButton));
    expect(button.onPressed, isNull);
  });
}

Widget _app({
  required WeeklyReportRecommendation recommendation,
  required WeeklyReportHabit? habit,
  required VoidCallback onReview,
}) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: WeeklyReportRecommendationCard(
        recommendation: recommendation,
        habit: habit,
        onReview: onReview,
      ),
    ),
  );
}

WeeklyReportRecommendation _fixture({String? habitId = 'live-habit'}) =>
    WeeklyReportRecommendation(
      type: WeeklyReportRecommendationType.reduceFrequency,
      reason: 'weekly_report_recommendation_reduce_frequency_v1',
      habitId: habitId,
      habitName: 'Leer',
      emoji: '📚',
      currentConfig: const {
        'schedule': {'type': 'timesPerWeek', 'timesPerWeek': 5},
      },
      proposedPatch: const {
        'version': 1,
        'type': 'reduceFrequency',
        'current': {
          'schedule': {'type': 'timesPerWeek', 'timesPerWeek': 5},
        },
        'proposed': {
          'schedule': {'type': 'timesPerWeek', 'timesPerWeek': 4},
        },
      },
    );

WeeklyReportHabit _habit() => WeeklyReportHabit(
      habitId: 'live-habit',
      name: 'Leer',
      emoji: '📚',
      type: HabitKind.check,
      schedule: HabitSchedule.timesPerWeek(timesPerWeek: 5),
      scheduledCount: 5,
      completedCount: 2,
      skippedCount: 0,
      completionRate: .4,
      classification: WeeklyReportHabitClassification.needsAttention,
      occurrences: [],
    );
