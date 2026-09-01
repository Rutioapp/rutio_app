import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  final policy = NotificationSchedulePolicy();
  final scope = NotificationScope(
    userId: 'user-1',
    scopeEpoch: 1,
    installId: 'install-1',
    locale: 'es',
  );

  NotificationSelectionContext context({
    required DateTime now,
  }) {
    return NotificationSelectionContext(
      scope: scope,
      now: now,
      timezoneId: 'Europe/Madrid',
      timeOfDay: notificationContextTimeOfDayFromDateTime(now),
      progressRatio: 1 / 3,
      completedCount: 1,
      pendingCount: 2,
      totalCount: 3,
      journalWrittenToday: false,
    );
  }

  NotificationSelectionOpportunity journal(
    JournalNudgeContext journalContext,
  ) {
    final isPerfectDay = journalContext == JournalNudgeContext.perfectDay;
    return NotificationSelectionOpportunity(
      kind: NotificationKind.journalNudge,
      journalNudgeContext: journalContext,
      reason: isPerfectDay
          ? NotificationSelectionReason.journalPerfectDayPriority
          : NotificationSelectionReason.journalEndOfDayPriority,
      priority: isPerfectDay ? 94 : 72,
      primaryCategories: const <NotificationTemplateCategory>[
        NotificationTemplateCategory.journalNudge,
      ],
    );
  }

  test('journal opportunity uses the configured evening slot', () {
    final now = DateTime(2026, 8, 31, 9);
    final journal = NotificationSelectionOpportunity(
      kind: NotificationKind.journalNudge,
      journalNudgeContext: JournalNudgeContext.endOfDay,
      reason: NotificationSelectionReason.journalEndOfDayPriority,
      priority: 72,
      primaryCategories: const <NotificationTemplateCategory>[
        NotificationTemplateCategory.journalNudge,
      ],
    );

    final result = policy.buildOpportunities(
      context: context(now: now),
      preferences: NotificationPreferences.defaults(),
      discoveredOpportunities: <NotificationSelectionOpportunity>[journal],
    );

    final evening =
        result.singleWhere((item) => item.opportunityId == 'evening');
    expect(evening.kind, NotificationKind.journalNudge);
    expect(evening.intendedAtLocal.hour, 20);
    expect(evening.intendedAtLocal.minute, 30);
  });

  test('preserves general reflection when no journal nudge is eligible', () {
    final now = DateTime(2026, 8, 31, 9);
    final reflection = NotificationSelectionOpportunity(
      kind: NotificationKind.generalDailyReflection,
      reason: NotificationSelectionReason.reflectionPriority,
      priority: 64,
      primaryCategories: const <NotificationTemplateCategory>[
        NotificationTemplateCategory.reflection,
      ],
    );

    final result = policy.buildOpportunities(
      context: context(now: now),
      preferences: NotificationPreferences.defaults(),
      discoveredOpportunities: <NotificationSelectionOpportunity>[reflection],
    );

    expect(
      result.singleWhere((item) => item.opportunityId == 'evening').kind,
      NotificationKind.generalDailyReflection,
    );
  });

  test('blocks journal nudge when the evening slot is in quiet hours', () {
    final now = DateTime(2026, 8, 31, 9);
    final journal = NotificationSelectionOpportunity(
      kind: NotificationKind.journalNudge,
      journalNudgeContext: JournalNudgeContext.endOfDay,
      reason: NotificationSelectionReason.journalEndOfDayPriority,
      priority: 72,
      primaryCategories: const <NotificationTemplateCategory>[
        NotificationTemplateCategory.journalNudge,
      ],
    );

    final result = policy.buildOpportunities(
      context: context(now: now),
      preferences: NotificationPreferences.defaults().copyWith(
        quietHoursStart: const NotificationClockTime(hour: 20, minute: 0),
        quietHoursEnd: const NotificationClockTime(hour: 21, minute: 0),
      ),
      discoveredOpportunities: <NotificationSelectionOpportunity>[journal],
    );

    expect(
      result.singleWhere((item) => item.opportunityId == 'evening').isEligible,
      isFalse,
    );
  });

  test('keeps journal context on today before and at the evening anchor', () {
    final preferences = NotificationPreferences.defaults();
    for (final now in <DateTime>[
      DateTime(2026, 8, 31, 15),
      DateTime(2026, 8, 31, 20, 30),
    ]) {
      final result = policy.buildOpportunities(
        context: context(now: now),
        preferences: preferences,
        discoveredOpportunities: <NotificationSelectionOpportunity>[
          journal(JournalNudgeContext.perfectDay),
        ],
      );

      final evening =
          result.singleWhere((item) => item.opportunityId == 'evening');
      expect(evening.intendedAtLocal, DateTime(2026, 8, 31, 20, 30));
    }
  });

  test('does not roll perfect day or end of day into tomorrow', () {
    final now = DateTime(2026, 8, 31, 21, 45);
    final preferences = NotificationPreferences.defaults();

    for (final journalContext in <JournalNudgeContext>[
      JournalNudgeContext.perfectDay,
      JournalNudgeContext.endOfDay,
    ]) {
      final result = policy.buildOpportunities(
        context: context(now: now),
        preferences: preferences,
        discoveredOpportunities: <NotificationSelectionOpportunity>[
          journal(journalContext),
        ],
      );

      expect(
        result.where((item) => item.opportunityId == 'evening'),
        isEmpty,
      );
    }
  });

  test('quiet hours block same-day journal without rollover', () {
    final result = policy.buildOpportunities(
      context: context(now: DateTime(2026, 8, 31, 15)),
      preferences: NotificationPreferences.defaults().copyWith(
        quietHoursStart: const NotificationClockTime(hour: 20, minute: 0),
        quietHoursEnd: const NotificationClockTime(hour: 21, minute: 0),
      ),
      discoveredOpportunities: <NotificationSelectionOpportunity>[
        journal(JournalNudgeContext.endOfDay),
      ],
    );

    final evening =
        result.singleWhere((item) => item.opportunityId == 'evening');
    expect(evening.isEligible, isFalse);
    expect(evening.intendedAtLocal, DateTime(2026, 8, 31, 20, 30));
  });
}
