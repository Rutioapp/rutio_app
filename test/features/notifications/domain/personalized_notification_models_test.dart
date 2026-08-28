import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  group('NotificationKind', () {
    test('classifies kinds into the expected families', () {
      expect(
        NotificationKind.habitReminder.family,
        NotificationFamily.habitReminder,
      );
      expect(
        NotificationKind.generalDiaryPrompt.family,
        NotificationFamily.personalizedGeneral,
      );
      expect(
        NotificationKind.celebrationStreak.family,
        NotificationFamily.celebration,
      );
      expect(
        NotificationKind.futureWeeklyReport.family,
        NotificationFamily.weeklyReport,
      );
    });
  });

  group('NotificationPreferences', () {
    test('provides stable defaults for foundation V1', () {
      final preferences = NotificationPreferences.defaults();

      expect(preferences.masterEnabled, isTrue);
      expect(preferences.habitRemindersEnabled, isTrue);
      expect(preferences.generalNotificationsEnabled, isTrue);
      expect(
        preferences.intensityPreset,
        NotificationIntensityPreset.balanced,
      );
      expect(preferences.generalNotificationCapPerDay, 2);
      expect(preferences.maxAdditionalContextualPerDay, 1);
      expect(preferences.dailyAnchorTime.formatHhMm(), '20:30');
      expect(preferences.fallbackAnchorPolicy, 'fixed_20_30_local');
    });

    test('is immutable-friendly through copyWith and value equality', () {
      final base = NotificationPreferences.defaults();
      final updated = base.copyWith(
        generalNotificationsEnabled: false,
        quietHoursStart: const NotificationClockTime(hour: 22, minute: 0),
      );

      expect(base.generalNotificationsEnabled, isTrue);
      expect(base.quietHoursStart, isNull);
      expect(updated.generalNotificationsEnabled, isFalse);
      expect(updated.quietHoursStart?.formatHhMm(), '22:00');
      expect(
        updated,
        isNot(base),
      );
    });
  });

  group('NotificationScope', () {
    test('separates users and scope epochs in equality and hashes', () {
      final first = NotificationScope(
        userId: 'user-1',
        scopeEpoch: 3,
        installId: 'install-1',
        locale: 'es',
      );
      final second = NotificationScope(
        userId: 'user-1',
        scopeEpoch: 4,
        installId: 'install-1',
        locale: 'es',
      );

      expect(first, isNot(second));
      expect(first.scopeHash, isNot(second.scopeHash));
    });

    test('rejects blank identity fields', () {
      expect(
        () => NotificationScope(
          userId: ' ',
          scopeEpoch: 1,
          installId: 'install-1',
          locale: 'es',
        ),
        throwsArgumentError,
      );
      expect(
        () => NotificationScope(
          userId: 'user-1',
          scopeEpoch: 1,
          installId: ' ',
          locale: 'es',
        ),
        throwsArgumentError,
      );
    });
  });

  group('NotificationClockTime', () {
    test('parses valid hh:mm strings and falls back otherwise', () {
      expect(NotificationClockTime.parse('06:45').formatHhMm(), '06:45');
      expect(NotificationClockTime.parse('invalid').formatHhMm(), '20:30');
      expect(NotificationClockTime.parse('25:00').formatHhMm(), '20:30');
    });
  });

  group('Notification models', () {
    test('candidate derives its family from the kind', () {
      final candidate = NotificationCandidate(
        candidateId: 'cand-1',
        kind: NotificationKind.generalInactivity,
        priorityScore: 0.8,
        baseWeight: 10,
        reasonCode: 'inactive_3d',
        schedulePolicy: NotificationScheduleSpec(
          scheduleType: NotificationScheduleType.exactDateTime,
          scheduledLocalDateTime: DateTime(2026, 8, 28, 20, 30),
          repeats: false,
          anchorSource: 'last_app_open',
          timezoneIdAtPlanTime: 'Europe/Madrid',
        ),
        dedupeKey: 'inactive_3d',
        cooldownKey: 'generalInactivity',
      );

      expect(candidate.family, NotificationFamily.personalizedGeneral);
    });

    test('history snapshot exposes unmodifiable collections', () {
      final history = NotificationMessageHistorySnapshot(
        recentDeliveries: <NotificationDeliveryRecord>[
          NotificationDeliveryRecord(
            notificationKey: 'key-1',
            userId: 'user-1',
            templateId: 'template-1',
            kind: NotificationKind.generalDayClosure,
            scheduledAt: DateTime(2026, 8, 28, 20, 30),
          ),
        ],
      );

      expect(
        () => history.recentDeliveries.add(
          NotificationDeliveryRecord(
            notificationKey: 'key-2',
            userId: 'user-1',
            templateId: 'template-2',
            kind: NotificationKind.generalInactivity,
            scheduledAt: DateTime(2026, 8, 28, 21, 0),
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('schedule spec enforces required fields for exact schedules', () {
      expect(
        () => NotificationScheduleSpec(
          scheduleType: NotificationScheduleType.exactDateTime,
          repeats: false,
          anchorSource: 'missing_date',
          timezoneIdAtPlanTime: 'Europe/Madrid',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
