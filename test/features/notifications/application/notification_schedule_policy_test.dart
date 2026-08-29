import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  group('NotificationSchedulePolicy', () {
    const policy = NotificationSchedulePolicy();

    test(
        'uses explicit default quiet hours when preferences do not define them',
        () {
      final preferences = NotificationPreferences.defaults();

      expect(policy.quietHoursStart(preferences).formatHhMm(), '22:30');
      expect(policy.quietHoursEnd(preferences).formatHhMm(), '08:00');
    });

    test('caps notifications per day by intensity preset', () {
      final base = NotificationPreferences.defaults();

      expect(
        policy.maxNotificationsPerDay(
          base.copyWith(intensityPreset: NotificationIntensityPreset.light),
        ),
        1,
      );
      expect(
        policy.maxNotificationsPerDay(
          base.copyWith(intensityPreset: NotificationIntensityPreset.balanced),
        ),
        2,
      );
      expect(
        policy.maxNotificationsPerDay(
          base.copyWith(
            intensityPreset: NotificationIntensityPreset.active,
            maxAdditionalContextualPerDay: 2,
          ),
        ),
        4,
      );
    });

    test('reduces cap when there are many known habit reminders', () {
      expect(policy.applyHabitReminderPressureAdjustment(4, 3), 3);
      expect(policy.applyHabitReminderPressureAdjustment(4, 6), 2);
      expect(policy.applyHabitReminderPressureAdjustment(2, null), 2);
    });
  });
}
