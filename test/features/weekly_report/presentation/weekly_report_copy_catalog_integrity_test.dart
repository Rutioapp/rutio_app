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
  'summary_first_partial': 18,
  'summary_provisional': 18,
  'summary_no_schedule': 14,
  'summary_strong': 20,
  'summary_good': 20,
  'summary_mixed': 20,
  'summary_needs_recovery': 20,
  'summary_improved': 18,
  'summary_declined': 18,
};

const _observationFamilies = <String, int>{
  'habit_highlighted': 16,
  'habit_stable': 16,
  'habit_needs_attention': 16,
};

List<String> _keys(Map<String, int> families) => [
      for (final entry in families.entries)
        for (var i = 1; i <= entry.value; i++)
          'weekly_report_${entry.key}_${i.toString().padLeft(2, '0')}',
    ];

List<String> _values(String path, String prefix, int count) {
  final values = jsonDecode(File(path).readAsStringSync()) as Map;
  return [
    for (var i = 1; i <= count; i++)
      values['$prefix${i.toString().padLeft(2, '0')}'].toString(),
  ];
}

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
    expect(summaryKeys, hasLength(166));
    expect(observationKeys, hasLength(48));
    expect(allKeys, hasLength(214));
    expect(allKeys.toSet(), hasLength(214));

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

  test('family prefixes are disjoint and backend migrations declare the pool',
      () {
    final migration = File(
          'supabase/migrations/20260903130000_weekly_report_copy_catalog_expansion.sql',
        ).readAsStringSync() +
        File(
          'supabase/migrations/20260904120000_weekly_report_copy_catalog_expansion_v2.sql',
        ).readAsStringSync();
    final expansionV2 = File(
      'supabase/migrations/20260904120000_weekly_report_copy_catalog_expansion_v2.sql',
    ).readAsStringSync();
    for (final entry
        in {..._summaryFamilies, ..._observationFamilies}.entries) {
      expect(expansionV2, contains("('${entry.key}'"));
      expect(expansionV2, contains(', ${entry.value})'));
    }
    expect(migration, contains('generate_series'));
    expect(migration, contains('md5('));
    expect(migration, contains('not exists'));
    expect(migration, isNot(contains('random()')));
  });

  test('catalog values are non-empty and unique within each family', () {
    final es =
        jsonDecode(File('lib/l10n/app_es.arb').readAsStringSync()) as Map;
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    for (final entry
        in {..._summaryFamilies, ..._observationFamilies}.entries) {
      final arbPrefix = entry.key
          .split('_')
          .skip(1)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join();
      final prefix = entry.key.startsWith('summary_')
          ? 'weeklyReportSummary$arbPrefix'
          : 'weeklyReportHabit$arbPrefix';
      final esValues = [
        for (var i = 1; i <= entry.value; i++)
          es['${prefix}${i.toString().padLeft(2, '0')}'],
      ];
      final enValues = [
        for (var i = 1; i <= entry.value; i++)
          en['${prefix}${i.toString().padLeft(2, '0')}'],
      ];
      expect(esValues, everyElement(isA<String>()));
      expect(enValues, everyElement(isA<String>()));
      expect(esValues.toSet(), hasLength(entry.value));
      expect(enValues.toSet(), hasLength(entry.value));
    }
  });

  test('no-schedule selection is reserved for exactly zero scheduled items',
      () {
    final source = File(
      'supabase/migrations/20260903120000_weekly_report_contextual_copy.sql',
    ).readAsStringSync();
    expect(source, contains("when p_scheduled = 0 then 'summary_no_schedule'"));
    expect(source, isNot(contains('low_signal')));
    expect(source, isNot(contains('p_rate <')));
  });

  test('provisional copy stays day-agnostic', () {
    for (final path in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final values = _values(
        path,
        path.endsWith('app_es.arb')
            ? 'weeklyReportSummaryProvisional'
            : 'weeklyReportSummaryProvisional',
        18,
      );
      expect(
        values.join(' '),
        isNot(matches(RegExp(
          r'próximos días|quedan días|cada día pendiente|days ahead|days to adjust|day ahead',
          caseSensitive: false,
        ))),
      );
    }
  });

  test('needs-attention copy is observational, not prescriptive', () {
    for (final path in ['lib/l10n/app_es.arb', 'lib/l10n/app_en.arb']) {
      final values = _values(
        path,
        'weeklyReportHabitNeedsAttention',
        16,
      );
      expect(
        values.join(' '),
        isNot(matches(RegExp(
          r'simplif|ajuste|ajustar|probar|siguiente paso|revisar|simplif|adjust|try |next step|review|easier|reduce |approach',
          caseSensitive: false,
        ))),
      );
    }
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
