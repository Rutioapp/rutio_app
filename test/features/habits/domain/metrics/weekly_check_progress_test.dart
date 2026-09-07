import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_check_progress.dart';

void main() {
  const calculator = HabitWeeklyCheckProgressCalculator();
  const habit = <String, dynamic>{
    'id': 'sport',
    'type': 'check',
    'schedule': <String, dynamic>{
      'type': 'timesPerWeek',
      'timesPerWeek': 3,
    },
  };

  Map<String, dynamic> history(Iterable<String> days) => <String, dynamic>{
        'habitCompletions': <String, dynamic>{
          for (final day in days) day: <String, dynamic>{'sport': true},
        },
      };

  Map<String, dynamic> historyWithSkips({
    required Iterable<String> completedDays,
    required Iterable<String> skippedDays,
  }) =>
      <String, dynamic>{
        'habitCompletions': <String, dynamic>{
          for (final day in completedDays)
            day: <String, dynamic>{'sport': true},
        },
        'habitSkips': <String, dynamic>{
          for (final day in skippedDays) day: <String, dynamic>{'sport': true},
        },
      };

  test('counts distinct completed Monday-Sunday days and allows 4/3', () {
    final result = calculator.calculate(
      habit: habit,
      history: history(
          const ['2026-09-07', '2026-09-09', '2026-09-11', '2026-09-12']),
      referenceDate: DateTime(2026, 9, 12),
    );

    expect(result.completedDays, 4);
    expect(result.targetDays, 3);
    expect(result.quotaMet, isTrue);
    expect(result.rawProgressRatio, closeTo(4 / 3, 0.0001));
  });

  test('duplicate rebuilds of the same day count once', () {
    final result = calculator.calculate(
      habit: habit,
      history: history(const ['2026-09-07', '2026-09-07', '2026-09-09']),
      referenceDate: DateTime(2026, 9, 9),
    );

    expect(result.completedDays, 2);
  });

  test('does not count the previous Sunday in the new Monday week', () {
    final result = calculator.calculate(
      habit: habit,
      history: history(const ['2026-09-06', '2026-09-07']),
      referenceDate: DateTime(2026, 9, 7),
    );

    expect(result.weekStart, DateTime(2026, 9, 7));
    expect(result.completedDays, 1);
  });

  test('skipped days do not count toward the weekly quota', () {
    final result = calculator.calculate(
      habit: habit,
      history: historyWithSkips(
        completedDays: const ['2026-09-07', '2026-09-08', '2026-09-09'],
        skippedDays: const ['2026-09-08'],
      ),
      referenceDate: DateTime(2026, 9, 9),
    );

    expect(result.completedDays, 2);
    expect(result.targetDays, 3);
    expect(result.quotaMet, isFalse);
  });

  test('flexible schedule is available on every day', () {
    final schedule = HabitSchedule.timesPerWeek(timesPerWeek: 3);

    expect(schedule.scheduledForDate(DateTime(2026, 9, 7)), isTrue);
    expect(schedule.scheduledForDate(DateTime(2026, 9, 13)), isTrue);
  });
}
