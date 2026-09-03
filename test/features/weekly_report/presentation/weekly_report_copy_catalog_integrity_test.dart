import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/weekly_report/presentation/weekly_report_copy_resolver.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

const _summaryFamilies = <String, int>{
  'summary_first_partial': 8,
  'summary_provisional': 8,
  'summary_no_schedule': 6,
  'summary_strong': 10,
  'summary_good': 10,
  'summary_mixed': 10,
  'summary_needs_recovery': 10,
  'summary_improved': 8,
  'summary_declined': 8,
};

const _observationFamilies = <String, int>{
  'habit_highlighted': 8,
  'habit_stable': 8,
  'habit_needs_attention': 8,
};

List<String> _keys(Map<String, int> families) => [
      for (final entry in families.entries)
        for (var i = 1; i <= entry.value; i++)
          'weekly_report_${entry.key}_${i.toString().padLeft(2, '0')}',
    ];

WeeklyReport _report(String? key) => WeeklyReport(
      id: 'r',
      userId: 'u',
      week: WeeklyReportWeek.fromDate(DateTime(2026, 8, 31)),
      timezoneId: 'Europe/Madrid',
      status: WeeklyReportStatus.finalized,
      firstPartialWeek: false,
      summary: const WeeklyReportSummary(
        scheduledCount: 4,
        completedCount: 3,
        completionRate: .75,
      ),
      days: const [],
      habits: const [],
      trend: const WeeklyReportTrend(
        kind: WeeklyReportTrendKind.unavailable,
        delta: 0,
        comparable: false,
        reason: '',
      ),
      schemaVersion: 1,
      metricsPolicyVersion: 1,
      contentVersion: 1,
      summaryMessageKey: key,
    );

WeeklyReportHabit _habit(String key) => WeeklyReportHabit(
      habitId: 'h',
      name: 'Habit',
      type: HabitKind.check,
      schedule: HabitSchedule.daily(),
      scheduledCount: 4,
      completedCount: 3,
      skippedCount: 0,
      completionRate: .75,
      occurrences: const <HabitOccurrenceResult>[],
      classification: WeeklyReportHabitClassification.stable,
      observationKey: key,
    );

void main() {
  final summaryKeys = _keys(_summaryFamilies);
  final observationKeys = _keys(_observationFamilies);
  final allKeys = [...summaryKeys, ...observationKeys];

  test('approved catalog has exact family counts and l10n parity', () {
    expect(summaryKeys, hasLength(78));
    expect(observationKeys, hasLength(24));
    expect(allKeys.toSet(), hasLength(102));

    for (final path in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final values = jsonDecode(File(path).readAsStringSync()) as Map;
      for (final key in allKeys) {
        final parts = key.substring('weekly_report_'.length).split('_');
        final getter = parts
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join();
        final arbKey = 'weeklyReport$getter';
        final value = values[arbKey];
        expect(value, isA<String>(), reason: '$path is missing $arbKey');
        expect(value, isNotEmpty, reason: '$path has empty $arbKey');
        expect(value, isNot(equals(key)));
        expect(
            value.toString(),
            isNot(matches(RegExp(
              r'\bTODO\b|\bTBD\b|\bFIXME\b|\bplaceholder\b|\bLorem ipsum\b',
            ))));
      }
    }
  });

  test('every approved key resolves in both languages', () {
    for (final key in summaryKeys) {
      expect(
          WeeklyReportCopyResolver.summary(AppLocalizationsEs(), _report(key)),
          isNotEmpty);
      expect(
          WeeklyReportCopyResolver.summary(AppLocalizationsEn(), _report(key)),
          isNotEmpty);
    }
    for (final key in observationKeys) {
      expect(
        WeeklyReportCopyResolver.observation(AppLocalizationsEs(), _habit(key)),
        isNotEmpty,
      );
      expect(
        WeeklyReportCopyResolver.observation(AppLocalizationsEn(), _habit(key)),
        isNotEmpty,
      );
    }
  });

  test('family prefixes are disjoint and backend migration declares the pool',
      () {
    final migration = File(
      'supabase/migrations/20260903130000_weekly_report_copy_catalog_expansion.sql',
    ).readAsStringSync();
    for (final entry
        in {..._summaryFamilies, ..._observationFamilies}.entries) {
      expect(migration, contains("('${entry.key}'"));
      expect(migration, contains(',${entry.value})'));
    }
    expect(migration, contains('generate_series'));
    expect(migration, isNot(contains('random()')));
  });

  test('unknown keys remain safe and language switching preserves the key', () {
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEs(), _report('future_key')),
        contains('buena'));
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEn(), _report('future_key')),
        contains('good'));
    expect(
        WeeklyReportCopyResolver.observation(
            AppLocalizationsEs(), _habit('future_key')),
        isNull);
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEs(), _report('weekly_report_summary_strong_01')),
        contains('sólido'));
    expect(
        WeeklyReportCopyResolver.summary(
            AppLocalizationsEn(), _report('weekly_report_summary_strong_01')),
        contains('solid'));
  });
}
