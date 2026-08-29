import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/data/native/native_notification_schedule_executor.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  final scope = NotificationScope(
    userId: 'user-a',
    scopeEpoch: 3,
    installId: 'install-a',
    locale: 'es',
  );

  DesiredNotification desired({
    String timezoneId = 'Europe/Madrid',
    DateTime? scheduledAt,
  }) {
    return DesiredNotification(
      logicalNotificationId:
          'rutio:v2:general:generalProgressNudge:scope:today:morning',
      platformId: 20010,
      kind: NotificationKind.generalProgressNudge,
      family: NotificationFamily.personalizedGeneral,
      templateId: 'template-1',
      renderedTitle: 'Rutio',
      renderedBody: 'Body',
      intendedLocalDateTime: scheduledAt ?? DateTime(2026, 8, 29, 9, 30),
      timezoneSemantics: NotificationTimezoneSemantics.localClockTime,
      timezoneIdAtPlanTime: timezoneId,
      payload: NotificationPayloadV2(
        schema: 2,
        family: NotificationFamily.personalizedGeneral,
        kind: NotificationKind.generalProgressNudge,
        logicalId: 'rutio:v2:general:generalProgressNudge:scope:today:morning',
        templateId: 'template-1',
        scopeHash: scope.scopeHash,
        scopeEpoch: scope.scopeEpoch,
        categoryTag: 'encouragement',
      ),
      fingerprint: 'fp-1',
      scope: scope,
      categoryTag: 'encouragement',
      opportunityId: 'morning',
      planVersion: 1,
      metadata: const <String, String>{},
    );
  }

  group('NativeNotificationScheduleExecutor', () {
    test('creates when scope, permissions and timezone are valid', () async {
      final gateway = _FakeNativeGateway(
        capabilities: const NotificationSchedulingCapabilities(
          permissionStatus: NotificationSystemPermissionStatus.authorized,
          canScheduleNewEntries: true,
          canCancelExistingEntries: true,
        ),
      );
      final executor = NativeNotificationScheduleExecutor(
        gateway: gateway,
        isScopeActive: () async => true,
        now: () => DateTime(2026, 8, 29, 9, 0),
      );

      final result = await executor.create(desired());

      expect(result.isSuccess, isTrue);
      expect(result.scheduleAccepted, isTrue);
      expect(gateway.scheduledPlatformIds, <int>[20010]);
    });

    test('fails closed on stale scope', () async {
      final executor = NativeNotificationScheduleExecutor(
        gateway: _FakeNativeGateway(),
        isScopeActive: () async => false,
        now: () => DateTime(2026, 8, 29, 9, 0),
      );

      final result = await executor.create(desired());

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, NotificationNativeErrorCode.staleScope);
    });

    test('fails when permissions are not authorized', () async {
      final gateway = _FakeNativeGateway(
        capabilities: const NotificationSchedulingCapabilities(
          permissionStatus: NotificationSystemPermissionStatus.denied,
          canScheduleNewEntries: false,
          canCancelExistingEntries: true,
        ),
      );
      final executor = NativeNotificationScheduleExecutor(
        gateway: gateway,
        isScopeActive: () async => true,
        now: () => DateTime(2026, 8, 29, 9, 0),
      );

      final result = await executor.create(desired());

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, NotificationNativeErrorCode.permissionDenied);
    });

    test('fails when timezone is invalid', () async {
      for (final timezoneId in <String>[
        'CEST',
        'CET',
        'Mars/Olympus_Mons',
      ]) {
        final executor = NativeNotificationScheduleExecutor(
          gateway: _FakeNativeGateway(),
          isScopeActive: () async => true,
          now: () => DateTime(2026, 8, 29, 9, 0),
        );

        final result = await executor.create(
          desired(timezoneId: timezoneId),
        );

        expect(result.isSuccess, isFalse);
        expect(result.errorCode, NotificationNativeErrorCode.invalidTimezone);
      }
    });

    test('fails conservatively on iOS capacity exhaustion', () async {
      final gateway = _FakeNativeGateway(
        pendingNotifications: List<NativePendingNotification>.generate(
          60,
          (index) => NativePendingNotification(
            platformId: 5000 + index,
            isOwnedV2: false,
          ),
        ),
      );
      final executor = NativeNotificationScheduleExecutor(
        gateway: gateway,
        isScopeActive: () async => true,
        isIos: () => true,
        now: () => DateTime(2026, 8, 29, 9, 0),
      );

      final result = await executor.create(desired());

      expect(result.isSuccess, isFalse);
      expect(result.errorCode, NotificationNativeErrorCode.capacityExceeded);
    });

    test('replace failure after cancel reports cancelled state', () async {
      final gateway = _FakeNativeGateway(
        pendingNotifications: <NativePendingNotification>[
          NativePendingNotification(
            platformId: 20010,
            logicalNotificationId:
                'rutio:v2:general:generalProgressNudge:scope:today:morning',
            isOwnedV2: true,
          ),
        ],
        scheduleError: PlatformException(code: 'native_failure'),
      );
      final executor = NativeNotificationScheduleExecutor(
        gateway: gateway,
        isScopeActive: () async => true,
        now: () => DateTime(2026, 8, 29, 9, 0),
      );

      final result = await executor.replace(
        NotificationManifestEntry(
          notificationKey:
              'rutio:v2:general:generalProgressNudge:scope:today:morning',
          platformId: 20010,
          family: NotificationFamily.personalizedGeneral,
          kind: NotificationKind.generalProgressNudge,
          payload: desired().payload.encode(),
          templateId: 'template-1',
          scheduledAt: DateTime(2026, 8, 29, 9, 30).toUtc(),
          planVersion: 1,
          sourceFingerprint: 'fp-1',
        ),
        desired(),
      );

      expect(result.isSuccess, isFalse);
      expect(result.stateChange, NotificationExecutionStateChange.cancelled);
      expect(gateway.cancelledPlatformIds, <int>[20010]);
    });
  });
}

class _FakeNativeGateway implements NotificationNativeGateway {
  _FakeNativeGateway({
    this.capabilities = const NotificationSchedulingCapabilities(
      permissionStatus: NotificationSystemPermissionStatus.authorized,
      canScheduleNewEntries: true,
      canCancelExistingEntries: true,
    ),
    List<NativePendingNotification>? pendingNotifications,
    this.scheduleError,
  }) : _pendingNotifications =
            pendingNotifications ?? <NativePendingNotification>[];

  final NotificationSchedulingCapabilities capabilities;
  final List<NativePendingNotification> _pendingNotifications;
  final PlatformException? scheduleError;
  final List<int> scheduledPlatformIds = <int>[];
  final List<int> cancelledPlatformIds = <int>[];

  @override
  Future<void> cancelNotification(int platformId) async {
    cancelledPlatformIds.add(platformId);
    _pendingNotifications.removeWhere((item) => item.platformId == platformId);
  }

  @override
  Future<NotificationSchedulingCapabilities> getSchedulingCapabilities() async {
    return capabilities;
  }

  @override
  Future<List<NativePendingNotification>> pendingNotifications() async {
    return List<NativePendingNotification>.from(_pendingNotifications);
  }

  @override
  Future<void> scheduleNotification({
    required int platformId,
    required String title,
    required String body,
    required String payload,
    required NotificationScheduleSpec scheduleSpec,
    required String effectiveTimezoneId,
  }) async {
    if (scheduleError != null) {
      throw scheduleError!;
    }
    scheduledPlatformIds.add(platformId);
    _pendingNotifications.add(
      NativePendingNotification(
        platformId: platformId,
        title: title,
        body: body,
        payload: payload,
        logicalNotificationId:
            NotificationPayloadV2.tryParse(payload)?.logicalId,
        isOwnedV2: NotificationPayloadV2.tryParse(payload) != null,
      ),
    );
  }
}
