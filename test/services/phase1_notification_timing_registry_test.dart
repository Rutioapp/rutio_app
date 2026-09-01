import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/services/notification_types.dart';
import 'package:rutio/services/phase1_notification_timing_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('missing registry is empty and invalid entries are ignored', () async {
    final registry = _registry('scope-a');

    expect(await registry.readAll(), isEmpty);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'rutio.notifications.phase1_timing_registry_v1_scope-a',
      '{"entries":[{"logicalId":"broken"}]}',
    );
    expect(await registry.readAll(), isEmpty);
  });

  test('upsert is idempotent and replaces the scheduled time', () async {
    final registry = _registry('scope-a');
    final first = _intent(DateTime(2026, 9, 1, 9));
    final second = _intent(DateTime(2026, 9, 1, 10));

    await registry.upsert(first);
    await registry.upsert(second);

    final entries = await registry.readAll();
    expect(entries, hasLength(1));
    expect(entries.single.scheduledFor, second.scheduledFor);
  });

  test('scope data is isolated and survives a new registry instance', () async {
    final first = _registry('scope-a');
    await first.upsert(_intent(DateTime(2026, 9, 1, 9)));

    expect(await _registry('scope-b').readAll(), isEmpty);
    expect(await _registry('scope-a').readAll(), hasLength(1));
  });

  test('daily entries expose the next local occurrence, including midnight',
      () async {
    final registry = _registry('scope-a');
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

    final upcoming = await registry.upcomingForScope(
      now: DateTime(2026, 9, 1, 23, 55),
    );
    expect(upcoming, hasLength(1));
    expect(upcoming.single.scheduledFor, DateTime(2026, 9, 2, 0, 5));
  });

  test('past one-time entries are not upcoming and cancellation removes them',
      () async {
    final registry = _registry('scope-a');
    await registry.upsert(_intent(DateTime(2026, 9, 1, 9)));

    expect(
      await registry.upcomingForScope(now: DateTime(2026, 9, 1, 10)),
      isEmpty,
    );
    await registry.removeByPlatformId(51001);
    expect(await registry.readAll(), isEmpty);
  });

  test('removeByScope clears only the selected scope', () async {
    final scopeA = _registry('scope-a');
    final scopeB = _registry('scope-b');
    await scopeA.upsert(_intent(DateTime(2026, 9, 1, 9)));
    await scopeB.upsert(_intent(DateTime(2026, 9, 1, 9)));

    await scopeA.removeByScope();
    expect(await scopeA.readAll(), isEmpty);
    expect(await scopeB.readAll(), hasLength(1));
  });
}

SharedPreferencesPhase1NotificationScheduleRegistry _registry(String scope) {
  return SharedPreferencesPhase1NotificationScheduleRegistry(scope: scope);
}

Phase1NotificationScheduleIntent _intent(DateTime scheduledFor) {
  return Phase1NotificationScheduleIntent(
    logicalId: 'day_closure',
    platformId: RutioNotificationIds.dayClosure,
    kind: Phase1NotificationTimingKind.dayClosure,
    scheduledFor: scheduledFor,
    isUserConfigured: true,
  );
}
