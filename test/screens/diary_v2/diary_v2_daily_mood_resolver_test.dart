import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/screens/diary_v2/diary_v2_daily_mood_resolver.dart';

void main() {
  group('Diary V2 daily mood resolver', () {
    test('prefers DailyMood over DiaryEntry mood for a day', () {
      final moodsByDate = dailyMoodMapByDate([
        DailyMood(
          date: DateTime(2026, 6, 13),
          mood: 2,
          createdAt: 100,
          updatedAt: 200,
        ),
      ]);

      final resolved = resolvePreferredMoodForDay(
        day: DateTime(2026, 6, 13),
        dailyMoodsByDate: moodsByDate,
        fallbackEntries: const [
          DiaryEntry(
            id: 'entry-1',
            createdAt: 1781308800000,
            text: 'Texto',
            mood: -1,
          ),
        ],
      );

      expect(resolved, 2);
    });

    test('falls back to DiaryEntry mood when no DailyMood exists', () {
      final resolved = resolvePreferredMoodForDay(
        day: DateTime(2026, 6, 14),
        dailyMoodsByDate: const {},
        fallbackEntries: const [
          DiaryEntry(
            id: 'entry-2',
            createdAt: 1781395200000,
            text: 'Texto',
            mood: 1,
          ),
        ],
      );

      expect(resolved, 1);
    });

    test('builds monthly preferred moods using both sources', () {
      final moodsByDate = dailyMoodMapByDate([
        DailyMood(
          date: DateTime(2026, 6, 1),
          mood: 2,
          createdAt: 100,
          updatedAt: 200,
        ),
      ]);

      final values = resolvePreferredMonthMoodValues(
        month: DateTime(2026, 6, 15),
        dailyMoodsByDate: moodsByDate,
        monthEntries: const [
          DiaryEntry(
            id: 'entry-3',
            createdAt: 1780704000000,
            text: 'Uno',
            mood: -1,
          ),
          DiaryEntry(
            id: 'entry-4',
            createdAt: 1780790400000,
            text: 'Dos',
            mood: 1,
          ),
        ],
      );

      expect(values, [2, -1, 1]);
    });
  });
}
