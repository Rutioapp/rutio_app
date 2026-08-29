import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  NotificationScope buildScope() {
    return NotificationScope(
      userId: 'user-1',
      scopeEpoch: 1,
      installId: 'install-1',
      locale: 'es',
    );
  }

  DesiredNotification buildDesired({
    required String logicalId,
    required String templateId,
    required DateTime scheduledAt,
    String fingerprint = 'fp-1',
  }) {
    final scope = buildScope();
    return DesiredNotification(
      logicalNotificationId: logicalId,
      platformId: 20000 + logicalId.length,
      kind: NotificationKind.generalProgressNudge,
      family: NotificationFamily.personalizedGeneral,
      templateId: templateId,
      renderedTitle: 'Rutio',
      renderedBody: 'Body',
      intendedLocalDateTime: scheduledAt,
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

  DesiredNotificationPlan buildPlan(List<DesiredNotification> notifications) {
    final scope = buildScope();
    return DesiredNotificationPlan.ready(
      scope: scope,
      generatedAt: DateTime(2026, 8, 29, 9, 0),
      horizonStart: DateTime(2026, 8, 29, 9, 0),
      horizonEnd: DateTime(2026, 8, 30, 9, 0),
      notifications: notifications,
      opportunities: const <NotificationOpportunity>[],
      diagnostics: DesiredNotificationPlanDiagnostics(
        usedWakeUpFallback: true,
        habitReminderLoadUnavailable: true,
      ),
    );
  }

  NotificationScheduleManifest buildManifest({
    List<NotificationManifestEntry> entries =
        const <NotificationManifestEntry>[],
  }) {
    final scope = buildScope();
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

  group('NotificationReconciler', () {
    const reconciler = NotificationReconciler();

    test('creates when manifest is empty', () {
      final desired = buildDesired(
        logicalId: 'rutio:v2:general:generalProgressNudge:a:today:morning',
        templateId: 'template-1',
        scheduledAt: DateTime(2026, 8, 29, 9, 30),
      );
      final plan = buildPlan(<DesiredNotification>[desired]);
      final result = reconciler.reconcile(
        desiredPlan: plan,
        manifest: buildManifest(),
      );

      expect(result.operations.single.type,
          NotificationReconciliationOperationType.create);
    });

    test('keeps when desired matches manifest fingerprint', () {
      final desired = buildDesired(
        logicalId: 'rutio:v2:general:generalProgressNudge:a:today:morning',
        templateId: 'template-1',
        scheduledAt: DateTime(2026, 8, 29, 9, 30),
      );
      final result = reconciler.reconcile(
        desiredPlan: buildPlan(<DesiredNotification>[desired]),
        manifest: buildManifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: desired.logicalNotificationId,
              platformId: desired.platformId,
              family: desired.family,
              kind: desired.kind,
              payload: desired.payload.encode(),
              templateId: desired.templateId,
              scheduledAt: desired.intendedLocalDateTime.toUtc(),
              planVersion: desired.planVersion,
              sourceFingerprint: desired.fingerprint,
            ),
          ],
        ),
      );

      expect(result.operations.single.type,
          NotificationReconciliationOperationType.keep);
    });

    test('replaces when fingerprint changes', () {
      final desired = buildDesired(
        logicalId: 'rutio:v2:general:generalProgressNudge:a:today:morning',
        templateId: 'template-2',
        scheduledAt: DateTime(2026, 8, 29, 10, 0),
        fingerprint: 'fp-2',
      );
      final result = reconciler.reconcile(
        desiredPlan: buildPlan(<DesiredNotification>[desired]),
        manifest: buildManifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: desired.logicalNotificationId,
              platformId: desired.platformId,
              family: desired.family,
              kind: desired.kind,
              payload: desired.payload.encode(),
              templateId: 'template-1',
              scheduledAt: DateTime(2026, 8, 29, 9, 30).toUtc(),
              planVersion: 1,
              sourceFingerprint: 'fp-1',
            ),
          ],
        ),
      );

      expect(result.operations.single.type,
          NotificationReconciliationOperationType.replace);
    });

    test('cancels extra v2 entries but never legacy entries', () {
      final result = reconciler.reconcile(
        desiredPlan: buildPlan(const <DesiredNotification>[]),
        manifest: buildManifest(
          entries: <NotificationManifestEntry>[
            NotificationManifestEntry(
              notificationKey: 'rutio:v2:general:extra',
              platformId: 20001,
              family: NotificationFamily.personalizedGeneral,
              kind: NotificationKind.generalProgressNudge,
              payload: '{}',
              templateId: 't',
              scheduledAt: DateTime(2026, 8, 29, 9, 30).toUtc(),
              planVersion: 1,
              sourceFingerprint: 'fp',
            ),
            NotificationManifestEntry(
              notificationKey: 'legacy:daily_motivation',
              platformId: 90001,
              family: NotificationFamily.system,
              kind: NotificationKind.futureWeeklyReport,
              payload: '{}',
              templateId: 'legacy',
              scheduledAt: DateTime(2026, 8, 29, 9, 30).toUtc(),
              planVersion: 1,
              sourceFingerprint: 'legacy',
            ),
          ],
        ),
      );

      expect(result.operations.length, 1);
      expect(result.operations.single.type,
          NotificationReconciliationOperationType.cancel);
    });

    test('fails closed on scope mismatch', () {
      final desired = buildDesired(
        logicalId: 'rutio:v2:general:generalProgressNudge:a:today:morning',
        templateId: 'template-1',
        scheduledAt: DateTime(2026, 8, 29, 9, 30),
      );
      final mismatchedScope = NotificationScope(
        userId: 'user-2',
        scopeEpoch: 1,
        installId: 'install-1',
        locale: 'es',
      );
      final manifest = NotificationScheduleManifest(
        scope: mismatchedScope,
        scopeEpochAtPlanTime: 1,
        timezoneId: 'Europe/Madrid',
        lastReconciledAt: DateTime(2026, 8, 29).toUtc(),
        lastReconciledDate: DateTime(2026, 8, 29),
        entries: const <NotificationManifestEntry>[],
        platformIdIndex: const <String, int>{},
      );

      final result = reconciler.reconcile(
        desiredPlan: buildPlan(<DesiredNotification>[desired]),
        manifest: manifest,
      );

      expect(result.status, NotificationReconciliationPlanStatus.scopeMismatch);
      expect(result.operations, isEmpty);
    });
  });
}
