import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/application/notification_interaction_router.dart';
import 'package:rutio/features/notifications/domain/notification_payload.dart';
import 'package:rutio/features/notifications/domain/personalized_notification_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('receiving after attach drains without a MaterialApp rebuild',
      (tester) async {
    final drained = <NotificationPayloadV2>[];
    final router = NotificationInteractionRouter(
      drainForTesting: (payload) async => drained.add(payload),
    );
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            router.attach(context, navigatorKey);
            return const SizedBox();
          },
        ),
      ),
    );

    final payload = _payload();
    router.receiveRawPayload(payload.encode());
    await tester.pump();
    await tester.pump();

    expect(drained, <NotificationPayloadV2>[payload]);
  });

  testWidgets('pre-attach payload waits and is consumed once', (tester) async {
    final drained = <NotificationPayloadV2>[];
    final router = NotificationInteractionRouter(
      drainForTesting: (payload) async => drained.add(payload),
    );
    final navigatorKey = GlobalKey<NavigatorState>();
    final payload = _payload();

    router.receiveRawPayload(payload.encode());
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            router.attach(context, navigatorKey);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    router.attach(
      tester.element(find.byType(SizedBox)),
      navigatorKey,
    );
    router.receiveRawPayload(payload.encode());
    await tester.pump();
    await tester.pump();

    expect(drained, <NotificationPayloadV2>[payload]);
  });

  testWidgets('invalid and non-journal payloads do not schedule a drain',
      (tester) async {
    var drainCount = 0;
    final router = NotificationInteractionRouter(
      drainForTesting: (_) async => drainCount++,
    );
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) {
            router.attach(context, navigatorKey);
            return const SizedBox();
          },
        ),
      ),
    );

    router.receiveRawPayload('{not-json');
    router.receiveRawPayload(
      _payload(kind: NotificationKind.generalProgressNudge).encode(),
    );
    await tester.pump();
    await tester.pump();

    expect(drainCount, 0);
  });
}

NotificationPayloadV2 _payload({
  NotificationKind kind = NotificationKind.journalNudge,
}) {
  return NotificationPayloadV2(
    schema: 2,
    family: NotificationFamily.diary,
    kind: kind,
    logicalId: 'rutio:v2:diary:journalNudge:test',
    templateId: 'journal.nudge.end_of_day.reflection_01',
    scopeHash: 'scope-hash',
    scopeEpoch: 1,
    categoryTag: 'journalNudge',
    dateKey: '2026-09-01',
  );
}
