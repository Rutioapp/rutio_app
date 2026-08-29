import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/data/local/notification_local_storage_scope.dart';
import 'package:rutio/features/notifications/data/local/shared_preferences_notification_install_id_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesNotificationInstallIdProvider', () {
    test('does not touch the random source when constructed', () {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final random = _CountingRandom();

      SharedPreferencesNotificationInstallIdProvider(
        random: random,
      );

      expect(random.nextIntCalls, 0);
    });

    test('generates an install id when missing', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = SharedPreferencesNotificationInstallIdProvider();

      final installId = await provider.getOrCreateInstallId();

      expect(
        installId,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(NotificationLocalStorageScope.installIdKey),
        installId,
      );
    });

    test('reuses the same install id on subsequent reads', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final provider = SharedPreferencesNotificationInstallIdProvider();

      final first = await provider.getOrCreateInstallId();
      final second = await provider.getOrCreateInstallId();

      expect(second, first);
    });

    test('creates a different install id for a simulated new installation',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final firstProvider = SharedPreferencesNotificationInstallIdProvider();
      final first = await firstProvider.getOrCreateInstallId();

      SharedPreferences.setMockInitialValues(<String, Object>{});
      final secondProvider = SharedPreferencesNotificationInstallIdProvider();
      final second = await secondProvider.getOrCreateInstallId();

      expect(second, isNot(first));
    });
  });
}

class _CountingRandom implements Random {
  int nextIntCalls = 0;

  @override
  int nextInt(int max) {
    nextIntCalls += 1;
    return 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0.0;
}
