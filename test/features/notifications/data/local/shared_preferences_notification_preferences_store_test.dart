import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/data/local/shared_preferences_notification_preferences_store.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesNotificationPreferencesStore', () {
    late SharedPreferencesNotificationPreferencesStore store;
    late NotificationScope scopeA;
    late NotificationScope scopeB;
    late NotificationScope scopeAOtherInstall;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      store = SharedPreferencesNotificationPreferencesStore();
      scopeA = _scope(userId: 'user-a', installId: 'install-a');
      scopeB = _scope(userId: 'user-b', installId: 'install-a');
      scopeAOtherInstall = _scope(userId: 'user-a', installId: 'install-b');
    });

    test('returns defaults when no data exists', () async {
      final loaded = await store.load(scopeA);

      expect(loaded, NotificationPreferences.defaults());
    });

    test('supports round-trip persistence', () async {
      final preferences = NotificationPreferences.defaults().copyWith(
        masterEnabled: false,
        generalNotificationCapPerDay: 3,
        maxAdditionalContextualPerDay: 2,
        dailyAnchorTime: const NotificationClockTime(hour: 19, minute: 15),
        quietHoursStart: const NotificationClockTime(hour: 22, minute: 0),
        quietHoursEnd: const NotificationClockTime(hour: 7, minute: 30),
        wakeTimeSource: WakeTimeSource.userConfigured,
      );

      await store.save(scopeA, preferences);
      final reloaded = await store.load(scopeA);

      expect(reloaded, preferences);
    });

    test('update reads, mutates, and persists the next state', () async {
      await store.save(scopeA, NotificationPreferences.defaults());

      final updated = await store.update(
        scopeA,
        (current) => current.copyWith(
          generalNotificationsEnabled: false,
          intensityPreset: NotificationIntensityPreset.active,
        ),
      );

      expect(updated.generalNotificationsEnabled, isFalse);
      expect(updated.intensityPreset, NotificationIntensityPreset.active);
      expect(await store.load(scopeA), updated);
    });

    test('reset removes persisted data and falls back to defaults', () async {
      await store.save(
        scopeA,
        NotificationPreferences.defaults().copyWith(masterEnabled: false),
      );

      await store.reset(scopeA);

      expect(await store.load(scopeA), NotificationPreferences.defaults());
    });

    test('tolerates missing and corrupt fields', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'rutio_notifications_v2/installations/install-a/users/user-a/preferences',
        '{"masterEnabled":"nope","generalNotificationCapPerDay":-7,'
            '"preferredGeneralWindow":{"start":"oops"},"quietHoursEnd":"99:99"}',
      );

      final loaded = await store.load(scopeA);

      expect(loaded.masterEnabled, isTrue);
      expect(loaded.generalNotificationCapPerDay, 2);
      expect(
        loaded.preferredGeneralWindow,
        NotificationPreferences.defaults().preferredGeneralWindow,
      );
      expect(loaded.quietHoursEnd, isNull);
    });

    test('isolates data by user and install id', () async {
      await store.save(
        scopeA,
        NotificationPreferences.defaults().copyWith(masterEnabled: false),
      );
      await store.save(
        scopeB,
        NotificationPreferences.defaults()
            .copyWith(generalNotificationsEnabled: false),
      );

      expect((await store.load(scopeA)).masterEnabled, isFalse);
      expect((await store.load(scopeB)).masterEnabled, isTrue);
      expect(
        await store.load(scopeAOtherInstall),
        NotificationPreferences.defaults(),
      );
    });

    test('uses only scoped keys for per-user preferences data', () async {
      await store.save(scopeA, NotificationPreferences.defaults());

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys(),
        contains(
          'rutio_notifications_v2/installations/install-a/users/user-a/preferences',
        ),
      );
      expect(
        prefs
            .getKeys()
            .where((key) => key == 'rutio_notifications_v2/preferences'),
        isEmpty,
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
