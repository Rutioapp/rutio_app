import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/data/local/shared_preferences_notification_history_store.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesNotificationHistoryStore', () {
    late SharedPreferencesNotificationHistoryStore store;
    late NotificationScope scopeA;
    late NotificationScope scopeB;
    late NotificationScope scopeAOtherInstall;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesNotificationHistoryStore(maxRecords: 3);
      scopeA = _scope(userId: 'user-a', installId: 'install-a');
      scopeB = _scope(userId: 'user-b', installId: 'install-a');
      scopeAOtherInstall = _scope(userId: 'user-a', installId: 'install-b');
    });

    test('appends records and reads them ordered by recency', () async {
      await store.append(
        scopeA,
        _record('key-1', scheduledAt: DateTime.utc(2026, 8, 28, 18)),
        categoryTag: 'closure',
      );
      await store.append(
        scopeA,
        _record('key-2', scheduledAt: DateTime.utc(2026, 8, 28, 20)),
        categoryTag: 'closure',
      );

      final loaded = await store.load(scopeA);

      expect(
        loaded?.recentDeliveries.map((record) => record.notificationKey),
        <String>['key-2', 'key-1'],
      );
      expect(
        loaded?.lastSelectedAtByCategoryTag['closure'],
        DateTime.utc(2026, 8, 28, 20),
      );
    });

    test('enforces retention limit', () async {
      await store.append(
        scopeA,
        _record('key-1', scheduledAt: DateTime.utc(2026, 8, 28, 18)),
      );
      await store.append(
        scopeA,
        _record('key-2', scheduledAt: DateTime.utc(2026, 8, 28, 19)),
      );
      await store.append(
        scopeA,
        _record('key-3', scheduledAt: DateTime.utc(2026, 8, 28, 20)),
      );
      await store.append(
        scopeA,
        _record('key-4', scheduledAt: DateTime.utc(2026, 8, 28, 21)),
      );

      final loaded = await store.load(scopeA);

      expect(loaded?.recentDeliveries.length, 3);
      expect(
        loaded?.recentDeliveries.map((record) => record.notificationKey),
        <String>['key-4', 'key-3', 'key-2'],
      );
    });

    test('supports save/load round-trip and reload', () async {
      final history = NotificationMessageHistorySnapshot(
        recentDeliveries: <NotificationDeliveryRecord>[
          _record(
            'key-1',
            scheduledAt: DateTime.utc(2026, 8, 28, 18),
            categoryTag: 'encouragement',
          ),
        ],
        lastSelectedAtByTemplateId: <String, DateTime>{
          'template-1': DateTime.utc(2026, 8, 28, 18),
        },
      );

      await store.save(scopeA, history);

      final reloadedStore = SharedPreferencesNotificationHistoryStore(
        maxRecords: 3,
      );
      expect(await reloadedStore.load(scopeA), history);
    });

    test('isolates history by user and install', () async {
      await store.append(
        scopeA,
        _record('key-1', scheduledAt: DateTime.utc(2026, 8, 28, 18)),
      );

      expect(await store.load(scopeB), isNull);
      expect(await store.load(scopeAOtherInstall), isNull);
    });

    test('returns null for corrupt payloads', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'rutio_notifications_v2/installations/install-a/users/user-a/history',
        'not json',
      );

      expect(await store.load(scopeA), isNull);
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

NotificationDeliveryRecord _record(
  String key, {
  required DateTime scheduledAt,
  String? categoryTag,
}) {
  return NotificationDeliveryRecord(
    notificationKey: key,
    userId: 'user-a',
    templateId: 'template-$key',
    kind: NotificationKind.generalDayClosure,
    scheduledAt: scheduledAt,
    categoryTag: categoryTag,
  );
}
