import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/daily_mood.dart';

void main() {
  group('DailyMood', () {
    test('serializes and deserializes safely', () {
      final dailyMood = DailyMood(
        date: DateTime(2026, 6, 13),
        mood: 2,
        note: 'Buen dia',
        createdAt: 100,
        updatedAt: 200,
      );

      final restored = DailyMood.fromJson(dailyMood.toJson());

      expect(restored.date, DateTime(2026, 6, 13));
      expect(restored.mood, 2);
      expect(restored.note, 'Buen dia');
      expect(restored.createdAt, 100);
      expect(restored.updatedAt, 200);
    });

    test('normalizes datetime input to day-only date key', () {
      final restored = DailyMood.fromJson({
        'date': '2026-06-13T23:59:59.000',
        'mood': -1,
        'createdAt': 10,
        'updatedAt': 20,
      });

      expect(restored.date, DateTime(2026, 6, 13));
      expect(restored.dateKey, '2026-06-13');
    });

    test('copyWith allows clearing note', () {
      final dailyMood = DailyMood(
        date: DateTime(2026, 6, 13),
        mood: 1,
        note: 'Nota',
        createdAt: 100,
        updatedAt: 200,
      );

      final updated = dailyMood.copyWith(note: null, updatedAt: 300);

      expect(updated.note, isNull);
      expect(updated.updatedAt, 300);
      expect(updated.mood, 1);
    });
  });
}
