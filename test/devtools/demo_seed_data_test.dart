import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/devtools/demo_seed/demo_seed_data.dart';

void main() {
  group('DemoSeedData', () {
    test('is deterministic with a fixed now', () {
      final now = DateTime(2026, 5, 20, 10, 30);
      final first = DemoSeedData.build(now: now);
      final second = DemoSeedData.build(now: now);

      expect(jsonEncode(first.state), equals(jsonEncode(second.state)));
    });

    test('contains expected number and types of habits', () {
      final payload = DemoSeedData.build(now: DateTime(2026, 5, 20));
      final root = payload.state['userState'] as Map<String, dynamic>;
      final habits = (root['activeHabits'] as List).cast<Map<String, dynamic>>();

      expect(habits, hasLength(3));
      expect(habits.where((h) => h['type'] == 'check'), hasLength(2));
      expect(habits.where((h) => h['type'] == 'count'), hasLength(1));

      final families = habits
          .map((habit) => (habit['familyId'] ?? '').toString())
          .where((familyId) => familyId.isNotEmpty)
          .toSet();
      expect(families.length, greaterThanOrEqualTo(2));
    });

    test('contains at least one completion history entry', () {
      final payload = DemoSeedData.build(now: DateTime(2026, 5, 20));
      final root = payload.state['userState'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions =
          history['habitCompletions'] as Map<String, dynamic>;

      expect(completions, isNotEmpty);
      expect(
        completions.values.any(
          (day) => (day as Map<String, dynamic>).values.contains(true),
        ),
        isTrue,
      );
    });

    test('uses provided now value and does not rely on DateTime.now', () {
      final now = DateTime(2030, 1, 15, 17, 45);
      final payload = DemoSeedData.build(now: now);
      final root = payload.state['userState'] as Map<String, dynamic>;
      final daily = root['daily'] as Map<String, dynamic>;
      final history = root['history'] as Map<String, dynamic>;
      final completions =
          history['habitCompletions'] as Map<String, dynamic>;

      expect(daily['lastResetDate'], equals('2030-01-15'));
      expect(completions.containsKey('2030-01-14'), isTrue);
      expect(completions.containsKey('2030-01-13'), isTrue);
      expect(completions.containsKey('2030-01-12'), isTrue);
    });
  });
}
