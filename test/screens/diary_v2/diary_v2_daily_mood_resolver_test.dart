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

    test('returns null when no DailyMood exists for the day', () {
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

      expect(resolved, isNull);
    });

    test('builds monthly preferred moods from DailyMood only', () {
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

      expect(values, [2]);
    });

    test('matches DailyMood by calendar day and replaces same-day duplicates', () {
      final moodsByDate = dailyMoodMapByDate([
        DailyMood(
          date: DateTime(2026, 6, 13, 0, 5),
          mood: -1,
          createdAt: 100,
          updatedAt: 100,
        ),
        DailyMood(
          date: DateTime(2026, 6, 13, 23, 55),
          mood: 2,
          createdAt: 100,
          updatedAt: 200,
        ),
      ]);

      expect(moodsByDate.keys, <String>['2026-06-13']);
      expect(
        resolvePreferredMoodForDay(
          day: DateTime(2026, 6, 13, 12),
          dailyMoodsByDate: moodsByDate,
          fallbackEntries: const <DiaryEntry>[],
        ),
        2,
      );
    });

    test('does not use DiaryEntry mood for month preview data', () {
      final values = resolvePreferredMonthMoodValues(
        month: DateTime(2026, 6, 15),
        dailyMoodsByDate: const <String, DailyMood>{},
        monthEntries: const [
          DiaryEntry(
            id: 'entry-5',
            createdAt: 1780704000000,
            text: 'Uno',
            mood: -1,
          ),
          DiaryEntry(
            id: 'entry-6',
            createdAt: 1780790400000,
            text: 'Dos',
            mood: 2,
          ),
        ],
      );

      expect(values, isEmpty);
    });
  });
}
