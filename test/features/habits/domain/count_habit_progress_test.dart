import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/count_habit_progress.dart';

void main() {
  group('CountHabitProgress.fromValues', () {
    test('current 0 / target 8', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 0,
        targetValue: 8,
      );

      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isFalse);
      expect(progress.completionRatio, 0);
      expect(progress.remainingValue, 8);
    });

    test('current 6 / target 8', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 6,
        targetValue: 8,
      );

      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isTrue);
      expect(progress.completionRatio, 0.75);
      expect(progress.remainingValue, 2);
    });

    test('current 8 / target 8', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 8,
        targetValue: 8,
      );

      expect(progress.isCompleted, isTrue);
      expect(progress.hasPartialProgress, isFalse);
      expect(progress.completionRatio, 1);
      expect(progress.remainingValue, 0);
    });

    test('current 12 / target 8 clamps ratio', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 12,
        targetValue: 8,
      );

      expect(progress.isCompleted, isTrue);
      expect(progress.completionRatio, 1);
      expect(progress.remainingValue, 0);
    });

    test('negative current is clamped safely', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: -5,
        targetValue: 8,
      );

      expect(progress.currentValue, 0);
      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isFalse);
      expect(progress.completionRatio, 0);
    });

    test('target 0 uses safe fallback and is invalid', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 0,
        targetValue: 0,
      );

      expect(progress.isTargetValid, isFalse);
      expect(progress.effectiveTarget, 1);
      expect(progress.isCompleted, isFalse);
    });

    test('negative target uses safe fallback and is invalid', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 4,
        targetValue: -3,
      );

      expect(progress.isTargetValid, isFalse);
      expect(progress.effectiveTarget, 1);
      expect(progress.isCompleted, isTrue);
    });

    test('skipped resets completion and partial state', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 6,
        targetValue: 8,
        skipped: true,
      );

      expect(progress.isSkipped, isTrue);
      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isFalse);
      expect(progress.completionRatio, 0);
    });

    test('supports decimal values', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 2.5,
        targetValue: 5,
      );

      expect(progress.completionRatio, 0.5);
      expect(progress.hasPartialProgress, isTrue);
      expect(progress.isCompleted, isFalse);
    });
  });

  group('CountHabitProgress.fromHabitMap aliases', () {
    test('resolves targetCount and unitLabel aliases', () {
      final progress = CountHabitProgress.fromHabitMap({
        'progress': 6,
        'targetCount': 8,
        'unitLabel': 'km',
      });

      expect(progress.currentValue, 6);
      expect(progress.targetValue, 8);
      expect(progress.unit, 'km');
      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isTrue);
    });

    test('resolves goal and counterUnit aliases', () {
      final progress = CountHabitProgress.fromHabitMap({
        'currentValue': 2.5,
        'goal': 5,
        'counterUnit': 'L',
      });

      expect(progress.targetValue, 5);
      expect(progress.unit, 'L');
      expect(progress.completionRatio, 0.5);
    });

    test('resolves times alias and skipped alias', () {
      final progress = CountHabitProgress.fromHabitMap({
        'value': 6,
        'times': 8,
        'unit': 'pages',
        'skippedToday': true,
      });

      expect(progress.targetValue, 8);
      expect(progress.unit, 'pages');
      expect(progress.isSkipped, isTrue);
      expect(progress.isCompleted, isFalse);
      expect(progress.hasPartialProgress, isFalse);
    });
  });

  group('CountHabitProgress display formatting', () {
    test('formats whole numbers without trailing .0', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 6,
        targetValue: 8,
        unit: 'km',
      );

      expect(progress.displayText, '6 / 8 km');
    });

    test('formats decimals without ugly trailing zeroes', () {
      final progress = CountHabitProgress.fromValues(
        currentValue: 2.50,
        targetValue: 5.0,
        unit: 'h',
      );

      expect(progress.displayText, '2.5 / 5 h');
    });
  });
}
