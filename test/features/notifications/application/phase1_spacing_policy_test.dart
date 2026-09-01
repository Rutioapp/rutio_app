import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/application/phase1_spacing_policy.dart';
import 'package:rutio/services/notification_types.dart';
import 'package:rutio/services/phase1_notification_timing_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const policy = Phase1SpacingPolicy();

  Phase1NotificationScheduleIntent intentAt(DateTime time) {
    return Phase1NotificationScheduleIntent(
      logicalId: 'day_closure',
      platformId: RutioNotificationIds.dayClosure,
      kind: Phase1NotificationTimingKind.dayClosure,
      scheduledFor: time,
      isUserConfigured: true,
    );
  }

  test('uses a strict 30 minute boundary in both directions', () {
    final target = DateTime(2026, 9, 1, 20, 30);

    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [
          intentAt(target.subtract(const Duration(minutes: 15)))
        ],
      ),
      isTrue,
    );
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [
          intentAt(target.subtract(const Duration(minutes: 29, seconds: 59)))
        ],
      ),
      isTrue,
    );
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [
          intentAt(target.subtract(const Duration(minutes: 30)))
        ],
      ),
      isFalse,
    );
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [intentAt(target.add(const Duration(minutes: 30)))],
      ),
      isFalse,
    );
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [intentAt(target.add(const Duration(minutes: 15)))],
      ),
      isTrue,
    );
  });

  test('checks any Phase 1 schedule and ignores an empty registry', () {
    final target = DateTime(2026, 9, 1, 20, 30);
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: const [],
      ),
      isFalse,
    );
    expect(
      policy.conflictsWithPhase1(
        personalizedAt: target,
        phase1Schedules: [
          intentAt(target.subtract(const Duration(hours: 2))),
          intentAt(target.add(const Duration(minutes: 20))),
        ],
      ),
      isTrue,
    );
  });

  test('source resolves a daily reminder around midnight within a horizon',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final registry = SharedPreferencesPhase1NotificationScheduleRegistry(
      scope: 'scope-a',
    );
    await registry.upsert(
      Phase1NotificationScheduleIntent(
        logicalId: 'habit_reminder:habit-1',
        platformId: 10001,
        kind: Phase1NotificationTimingKind.habitReminder,
        scheduledFor: DateTime(2026, 9, 1, 0, 5),
        isUserConfigured: true,
        recurrence: Phase1NotificationRecurrence.daily,
      ),
    );

    final entries = await registry.upcomingForScope(
      scopeKey: 'scope-a',
      now: DateTime(2026, 9, 1, 23, 55),
      horizonEnd: DateTime(2026, 9, 2, 23, 55),
    );
    expect(entries.map((entry) => entry.scheduledFor), [
      DateTime(2026, 9, 2, 0, 5),
    ]);
  });

  test('wrong scope has no conflicts', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final registry = SharedPreferencesPhase1NotificationScheduleRegistry(
      scope: 'scope-a',
    );
    await registry.upsert(intentAt(DateTime(2026, 9, 1, 20, 15)));

    expect(
      await registry.upcomingForScope(
        scopeKey: 'scope-b',
        now: DateTime(2026, 9, 1, 19),
      ),
      isEmpty,
    );
  });
}
