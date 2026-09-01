import 'package:rutio/models/diary_entry.dart';

/// Read-only diary facts used by personalized notification context.
class JournalNotificationSignals {
  const JournalNotificationSignals({
    required this.journalWrittenToday,
    required this.journalWrittenLast24h,
    required this.journalEntriesLast7Days,
    required this.latestJournalEntryAt,
  });

  factory JournalNotificationSignals.fromEntries({
    required List<DiaryEntry> entries,
    required DateTime now,
  }) {
    final todayKey = _dateKey(now);
    final firstDateKey = _dateOnly(now.subtract(const Duration(days: 6)));
    final last24hStart = now.subtract(const Duration(hours: 24));
    var writtenToday = false;
    var entriesLast7Days = 0;
    var writtenLast24h = false;
    DateTime? latestEntryAt;

    for (final entry in entries) {
      final createdAt =
          DateTime.fromMillisecondsSinceEpoch(entry.createdAt).toLocal();
      if (latestEntryAt == null || createdAt.isAfter(latestEntryAt)) {
        latestEntryAt = createdAt;
      }

      final logicalDateKey = entry.dateKey ?? _dateKey(createdAt);
      if (logicalDateKey == todayKey) writtenToday = true;
      if (_isWithinDateWindow(logicalDateKey, firstDateKey, todayKey)) {
        entriesLast7Days++;
      }

      // DiaryEntry has no local updatedAt. The only real activity timestamp
      // available here is createdAt; the 24h boundary is inclusive.
      if (!createdAt.isAfter(now) && !createdAt.isBefore(last24hStart)) {
        writtenLast24h = true;
      }
    }

    return JournalNotificationSignals(
      journalWrittenToday: writtenToday,
      journalWrittenLast24h: writtenLast24h,
      journalEntriesLast7Days: entriesLast7Days,
      latestJournalEntryAt: latestEntryAt,
    );
  }

  final bool journalWrittenToday;
  final bool journalWrittenLast24h;
  final int journalEntriesLast7Days;
  final DateTime? latestJournalEntryAt;
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

String _dateOnly(DateTime date) => _dateKey(date);

bool _isWithinDateWindow(String value, String first, String last) {
  return value.compareTo(first) >= 0 && value.compareTo(last) <= 0;
}
