import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  final scope = NotificationScope(
    userId: 'user-a',
    scopeEpoch: 3,
    installId: 'install-a',
    locale: 'es',
  );

  DesiredNotification desired({
    String logicalId =
        'rutio:v2:general:generalProgressNudge:scope:today:morning',
    String templateId = 'template-1',
    String fingerprint = 'fp-1',
    DateTime? scheduledAt,
  }) {
    return DesiredNotification(
      logicalNotificationId: logicalId,
      platformId: 20011,
      kind: NotificationKind.generalProgressNudge,
      family: NotificationFamily.personalizedGeneral,
      templateId: templateId,
      renderedTitle: 'Rutio',
      renderedBody: 'Body',
      intendedLocalDateTime: scheduledAt ?? DateTime(2026, 8, 29, 9, 30),
      timezoneSemantics: NotificationTimezoneSemantics.localClockTime,
      timezoneIdAtPlanTime: 'Europe/Madrid',
      payload: NotificationPayloadV2(
        schema: 2,
        family: NotificationFamily.personalizedGeneral,
        kind: NotificationKind.generalProgressNudge,
        logicalId: logicalId,
        templateId: templateId,
        scopeHash: scope.scopeHash,
        scopeEpoch: scope.scopeEpoch,
        categoryTag: 'encouragement',
      ),
      fingerprint: fingerprint,
      scope: scope,
      categoryTag: 'encouragement',
      opportunityId: 'morning',
      planVersion: 1,
      metadata: const <String, String>{},
    );
  }

  DesiredNotificationPlan plan(List<DesiredNotification> notifications) {
    return DesiredNotificationPlan.ready(
      scope: scope,
      generatedAt: DateTime(2026, 8, 29, 9, 0),
      horizonStart: DateTime(2026, 8, 29, 9, 0),
      horizonEnd: DateTime(2026, 8, 30, 9, 0),
      notifications: notifications,
      opportunities: const <NotificationOpportunity>[],
      diagnostics: DesiredNotificationPlanDiagnostics(
        usedWakeUpFallback: false,
        habitReminderLoadUnavailable: false,
      ),
    );
  }

  NotificationScheduleManifest manifest({
    List<NotificationManifestEntry> entries =
        const <NotificationManifestEntry>[],
  }) {
    return NotificationScheduleManifest(
      scope: scope,
      scopeEpochAtPlanTime: scope.scopeEpoch,
      timezoneId: 'Europe/Madrid',
      lastReconciledAt: DateTime(2026, 8, 29, 9, 0).toUtc(),
      lastReconciledDate: DateTime(2026, 8, 29),
      entries: entries,
      platformIdIndex: const <String, int>{},
    );
  }

  NativePendingNotification pendingFor(
    DesiredNotification notification, {
    NotificationScope? pendingScope,
    String? title,
    String? body,
  }) {
    final effectiveScope = pendingScope ?? scope;
    return NativePendingNotification(
      platformId: notification.platformId,
      title: title ?? notification.renderedTitle,
      body: body ?? notification.renderedBody,
      payload: notification.payload.encode(),
      logicalNotificationId: notification.logicalNotificationId,
      templateId: notification.templateId,
      scopeHash: effectiveScope.scopeHash,
      scopeEpoch: effectiveScope.scopeEpoch,
      family: notification.family,
      kind: notification.kind,
      isOwnedV2: true,
    );
  }

  group('NotificationReconciler OS aware', () {
    const reconciler = NotificationReconciler();

    test(
        'keeps an owned debug weekly report entry instead of orphan-cleaning it',
        () {
      const logicalId = 'rutio:v2:debug:weekly_report_test:2026-08-31';
      final notification = DesiredNotification(
        logicalNotificationId: logicalId,
        platformId: 60025,
        kind: NotificationKind.futureWeeklyReport,
        family: NotificationFamily.weeklyReport,
        templateId: 'weekly_report.review',
        renderedTitle: 'Revisa tu semana',
        renderedBody: 'Tu resumen semanal está listo.',
        intendedLocalDateTime: DateTime(2026, 8, 29, 20, 50),
        timezoneSemantics: NotificationTimezoneSemantics.localCalendarDay,
        timezoneIdAtPlanTime: 'Europe/Madrid',
        payload: NotificationPayloadV2(
          schema: 2,
          family: NotificationFamily.weeklyReport,
          kind: NotificationKind.futureWeeklyReport,
          logicalId: logicalId,
          templateId: 'weekly_report.review',
          scopeHash: scope.scopeHash,
          scopeEpoch: scope.scopeEpoch,
          categoryTag: 'weeklyReport',
          route: 'weekly-report',
          dateKey: '2026-08-31',
        ),
        fingerprint: 'debug-fingerprint',
        scope: scope,
        categoryTag: 'weeklyReport',
        opportunityId: 'weekly_report_debug_2026-08-31',
        planVersion: 1,
        metadata: const <String, String>{'source': 'weekly_report_debug'},
      );
      final result = reconciler.reconcile(
        desiredPlan: DesiredNotificationPlan.ready(
          scope: scope,
          generatedAt: DateTime(2026, 8, 29, 20, 49),
          horizonStart: DateTime(2026, 8, 29, 20, 49),
          horizonEnd: DateTime(2026, 8, 29, 20, 51),
          notifications: <DesiredNotification>[notification],
          opportunities: const <NotificationOpportunity>[],
          diagnostics: DesiredNotificationPlanDiagnostics(
            notes: const <String>['weekly_only'],
            usedWakeUpFallback: false,
            habitReminderLoadUnavailable: false,
          ),
        ),
        manifest: manifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: logicalId,
              platformId: 60025,
              family: NotificationFamily.weeklyReport,
              kind: NotificationKind.futureWeeklyReport,
              payload: notification.payload.encode(),
              templateId: notification.templateId,
              scheduledAt: notification.intendedLocalDateTime.toUtc(),
              planVersion: 1,
              sourceFingerprint: notification.fingerprint,
            ),
          ],
        ),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification)
        ],
      );

      expect(result.operations.single.type,
          NotificationReconciliationOperationType.keep);
    });

    test('keeps when desired, manifest and OS all match', () {
      final notification = desired();
      final result = reconciler.reconcile(
        desiredPlan: plan(<DesiredNotification>[notification]),
        manifest: manifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: notification.logicalNotificationId,
              platformId: notification.platformId,
              family: notification.family,
              kind: notification.kind,
              payload: notification.payload.encode(),
              templateId: notification.templateId,
              scheduledAt: notification.intendedLocalDateTime.toUtc(),
              planVersion: notification.planVersion,
              sourceFingerprint: notification.fingerprint,
            ),
          ],
        ),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification),
        ],
      );

      expect(
        result.operations.single.type,
        NotificationReconciliationOperationType.keep,
      );
    });

    test('adopts safely when manifest is missing but OS matches desired', () {
      final notification = desired();
      final result = reconciler.reconcile(
        desiredPlan: plan(<DesiredNotification>[notification]),
        manifest: manifest(),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification),
        ],
      );

      expect(
        result.operations.single.type,
        NotificationReconciliationOperationType.adopt,
      );
    });

    test('replaces when OS entry cannot be verified exactly', () {
      final notification = desired();
      final result = reconciler.reconcile(
        desiredPlan: plan(<DesiredNotification>[notification]),
        manifest: manifest(),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification, body: 'Different body'),
        ],
      );

      expect(
        result.operations.single.type,
        NotificationReconciliationOperationType.replace,
      );
    });

    test('drops stale manifest entries when OS no longer has them', () {
      final notification = desired();
      final result = reconciler.reconcile(
        desiredPlan: plan(const <DesiredNotification>[]),
        manifest: manifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: notification.logicalNotificationId,
              platformId: notification.platformId,
              family: notification.family,
              kind: notification.kind,
              payload: notification.payload.encode(),
              templateId: notification.templateId,
              scheduledAt: notification.intendedLocalDateTime.toUtc(),
              planVersion: notification.planVersion,
              sourceFingerprint: notification.fingerprint,
            ),
          ],
        ),
      );

      expect(
        result.operations.single.type,
        NotificationReconciliationOperationType.dropManifest,
      );
    });

    test(
        'ignores owned v2 entries from another user during normal reconciliation',
        () {
      final notification = desired();
      final otherScope = NotificationScope(
        userId: 'user-b',
        scopeEpoch: 1,
        installId: 'install-a',
        locale: 'es',
      );
      final result = reconciler.reconcile(
        desiredPlan: plan(const <DesiredNotification>[]),
        manifest: manifest(),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification, pendingScope: otherScope),
        ],
      );

      expect(result.operations, isEmpty);
    });

    test('cancels orphan current-scope native entries unknown to manifest', () {
      final notification = desired();
      final result = reconciler.reconcile(
        desiredPlan: plan(const <DesiredNotification>[]),
        manifest: manifest(),
        osPendingNotifications: <NativePendingNotification>[
          pendingFor(notification),
        ],
      );

      expect(
        result.operations.single.type,
        NotificationReconciliationOperationType.cancel,
      );
    });
  });
}
