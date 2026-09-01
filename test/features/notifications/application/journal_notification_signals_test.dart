import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/application/journal_notification_signals.dart';
import 'package:rutio/models/diary_entry.dart';

void main() {
  final now = DateTime(2026, 8, 30, 12, 0);

  DiaryEntry entry({
    required String id,
    required DateTime createdAt,
    String? dateKey,
  }) {
    return DiaryEntry(
      id: id,
      createdAt: createdAt.millisecondsSinceEpoch,
      dateKey: dateKey,
      text: 'Entry $id',
    );
  }

  test('returns empty signals without entries', () {
    final signals = JournalNotificationSignals.fromEntries(
      entries: const <DiaryEntry>[],
      now: now,
    );

    expect(signals.journalWrittenToday, isFalse);
    expect(signals.journalWrittenLast24h, isFalse);
    expect(signals.journalEntriesLast7Days, 0);
    expect(signals.latestJournalEntryAt, isNull);
  });

  test('uses logical date for today and not creation date', () {
    final signals = JournalNotificationSignals.fromEntries(
      entries: <DiaryEntry>[
        entry(
          id: 'created-today-logical-yesterday',
          createdAt: now,
          dateKey: '2026-08-29',
        ),
        entry(
          id: 'created-yesterday-logical-today',
          createdAt: now.subtract(const Duration(days: 1)),
          dateKey: '2026-08-30',
        ),
      ],
      now: now,
    );

    expect(signals.journalWrittenToday, isTrue);
    expect(signals.journalEntriesLast7Days, 2);
  });

  test('falls back to local createdAt when no logical date is available', () {
    final signals = JournalNotificationSignals.fromEntries(
      entries: <DiaryEntry>[entry(id: 'today', createdAt: now)],
      now: now,
    );

    expect(signals.journalWrittenToday, isTrue);
  });

  test('uses inclusive last 24 hour boundary', () {
    final signals = JournalNotificationSignals.fromEntries(
      entries: <DiaryEntry>[
        entry(
            id: 'inside',
            createdAt: now.subtract(const Duration(hours: 23, minutes: 59))),
        entry(
            id: 'boundary', createdAt: now.subtract(const Duration(hours: 24))),
        entry(
            id: 'outside',
            createdAt: now.subtract(const Duration(hours: 24, minutes: 1))),
      ],
      now: now,
    );

    expect(signals.journalWrittenLast24h, isTrue);
  });

  test('counts logical dates in the seven local date-key window', () {
    final signals = JournalNotificationSignals.fromEntries(
      entries: <DiaryEntry>[
        entry(id: 'today', createdAt: now, dateKey: '2026-08-30'),
        entry(id: 'yesterday', createdAt: now, dateKey: '2026-08-29'),
        entry(id: 'six-days-ago', createdAt: now, dateKey: '2026-08-24'),
        entry(id: 'seven-days-ago', createdAt: now, dateKey: '2026-08-23'),
        entry(id: 'two-weeks-ago', createdAt: now, dateKey: '2026-08-16'),
      ],
      now: now,
    );

    expect(signals.journalEntriesLast7Days, 3);
  });

  test('returns the latest creation timestamp regardless of input order', () {
    final latest = now.subtract(const Duration(hours: 2));
    final signals = JournalNotificationSignals.fromEntries(
      entries: <DiaryEntry>[
        entry(id: 'older', createdAt: now.subtract(const Duration(days: 1))),
        entry(id: 'latest', createdAt: latest),
      ],
      now: now,
    );

    expect(signals.latestJournalEntryAt, latest);
  });
}
