import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/data/local/notification_platform_id_repository.dart';
import 'package:rutio/features/notifications/data/local/shared_preferences_notification_schedule_store.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesNotificationScheduleStore', () {
    late SharedPreferencesNotificationScheduleStore store;
    late NotificationPlatformIdRepository platformIds;
    late NotificationScope scopeA;
    late NotificationScope scopeB;
    late NotificationScope scopeAOtherInstall;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesNotificationScheduleStore();
      platformIds = NotificationPlatformIdRepository(scheduleStore: store);
      scopeA = _scope(userId: 'user-a', installId: 'install-a');
      scopeB = _scope(userId: 'user-b', installId: 'install-a');
      scopeAOtherInstall = _scope(userId: 'user-a', installId: 'install-b');
    });

    test('saves and loads a manifest round-trip', () async {
      final manifest = NotificationScheduleManifest(
        scope: scopeA,
        scopeEpochAtPlanTime: 1,
        timezoneId: 'Europe/Madrid',
        lastReconciledAt: DateTime.utc(2026, 8, 28, 10),
        lastReconciledDate: DateTime(2026, 8, 28),
        entries: <NotificationManifestEntry>[
          NotificationManifestEntry(
            notificationKey: 'rutio:v2:general:generalDayClosure:a:b:c',
            platformId: 20001,
            family: NotificationFamily.personalizedGeneral,
            kind: NotificationKind.generalDayClosure,
            payload: '{"v":2}',
            templateId: 'template-1',
            scheduledAt: DateTime.utc(2026, 8, 28, 20, 30),
            planVersion: 1,
            sourceFingerprint: 'fingerprint-1',
          ),
        ],
        platformIdIndex: const <String, int>{
          'rutio:v2:general:generalDayClosure:a:b:c': 20001,
        },
      );

      await store.save(scopeA, manifest);
      final loaded = await store.load(scopeA);

      expect(loaded, manifest);
    });

    test('upserts and removes manifest entries', () async {
      final entry = NotificationManifestEntry(
        notificationKey: 'rutio:v2:general:generalInactivity:a:b:c',
        platformId: 20010,
        family: NotificationFamily.personalizedGeneral,
        kind: NotificationKind.generalInactivity,
        payload: '{"v":2}',
        templateId: 'template-1',
        scheduledAt: DateTime.utc(2026, 8, 28, 20, 30),
        planVersion: 1,
        sourceFingerprint: 'fingerprint-1',
      );

      await store.upsertEntry(
        scopeA,
        entry,
        timezoneId: 'Europe/Madrid',
        reconciledAt: DateTime.utc(2026, 8, 28, 10),
        reconciledDate: DateTime(2026, 8, 28),
      );
      var loaded = await store.load(scopeA);
      expect(loaded?.entries.single, entry);

      await store.removeEntry(scopeA, entry.notificationKey);
      loaded = await store.load(scopeA);
      expect(loaded?.entries, isEmpty);
      expect(
          loaded?.platformIdIndex.containsKey(entry.notificationKey), isFalse);
    });

    test('returns null for corrupt manifest payloads', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'rutio_notifications_v2/installations/install-a/users/user-a/manifest',
        '{"scope":{"userId":"user-a"}}',
      );

      expect(await store.load(scopeA), isNull);
    });

    test('isolates manifests by user and install', () async {
      final manifest = NotificationScheduleManifest(
        scope: scopeA,
        scopeEpochAtPlanTime: 1,
        timezoneId: 'Europe/Madrid',
        lastReconciledAt: DateTime.utc(2026, 8, 28, 10),
        lastReconciledDate: DateTime(2026, 8, 28),
        entries: const <NotificationManifestEntry>[],
        platformIdIndex: const <String, int>{},
      );

      await store.save(scopeA, manifest);

      expect(await store.load(scopeB), isNull);
      expect(await store.load(scopeAOtherInstall), isNull);
    });

    test('persists platform id mappings across repository instances', () async {
      const notificationKey =
          'rutio:v2:general:generalDayClosure:scope:today:slot_1';

      final first = await platformIds.getOrAllocate(
        scopeA,
        family: NotificationFamily.personalizedGeneral,
        notificationKey: notificationKey,
        timezoneId: 'Europe/Madrid',
      );

      final reloadedStore = SharedPreferencesNotificationScheduleStore();
      final reloadedRepo =
          NotificationPlatformIdRepository(scheduleStore: reloadedStore);
      final second = await reloadedRepo.getOrAllocate(
        scopeA,
        family: NotificationFamily.personalizedGeneral,
        notificationKey: notificationKey,
        timezoneId: 'Europe/Madrid',
      );

      expect(second, first);
      expect(
        NotificationIdNamespace.personalizedGeneralRange.contains(first),
        isTrue,
      );
    });

    test('detects persisted platform id conflicts', () async {
      final conflictManifest = NotificationScheduleManifest(
        scope: scopeA,
        scopeEpochAtPlanTime: 1,
        timezoneId: 'Europe/Madrid',
        lastReconciledAt: DateTime.utc(2026, 8, 28, 10),
        lastReconciledDate: DateTime(2026, 8, 28),
        entries: const <NotificationManifestEntry>[],
        platformIdIndex: const <String, int>{
          'rutio:v2:general:generalDayClosure:scope:today:slot_1': 20001,
          'rutio:v2:general:generalInactivity:scope:today:slot_2': 20001,
        },
      );
      await store.save(scopeA, conflictManifest);

      expect(
        () => platformIds.getOrAllocate(
          scopeA,
          family: NotificationFamily.personalizedGeneral,
          notificationKey:
              'rutio:v2:general:generalDiaryPrompt:scope:today:slot_3',
          timezoneId: 'Europe/Madrid',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}

NotificationScope _scope({
  required String userId,
  required String installId,
}) {
  return NotificationScope(
    userId: userId,
    scopeEpoch: 1,
    installId: installId,
    locale: 'es',
  );
}
