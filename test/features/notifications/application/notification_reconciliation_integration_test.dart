import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/application/notification_context_builder.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  test(
      'context -> plan -> reconcile -> execute -> manifest -> reconcile is idempotent',
      () async {
    final scope = NotificationScope(
      userId: 'user-1',
      scopeEpoch: 2,
      installId: 'install-1',
      locale: 'es',
    );
    final snapshot = NotificationContextSnapshot(
      scope: scope,
      now: DateTime(2026, 8, 29, 9, 0),
      timezoneId: 'Europe/Madrid',
      calendarDate: DateTime(2026, 8, 29),
      pendingHabitsToday: const <String>['habit-1', 'habit-2'],
      completedHabitsToday: const <String>['habit-3'],
      bestStreakRisk: const NotificationStreakRisk(
        habitId: 'habit-1',
        habitName: 'Leer',
        streakLength: 7,
      ),
      progressTodayRatio: 1 / 3,
      schedulingCapabilities: const NotificationSchedulingCapabilities(
        permissionStatus: NotificationSystemPermissionStatus.authorized,
        canScheduleNewEntries: true,
        canCancelExistingEntries: true,
      ),
    );
    final contextResult = NotificationContextBuildResult.success(
      quality: NotificationContextQuality.rich,
      diagnostics: const NotificationContextDiagnostics(
        startedScopeKey: 'a',
        completedScopeKey: 'a',
        hasDisplayName: true,
        hasReliableProgress: true,
        hasReliableStreak: true,
        hasReliableInactivity: false,
        hasDiarySignal: false,
        hasMoodSignal: false,
        hasWakeUpTime: false,
        missingSignals: <String>[],
      ),
      snapshot: snapshot,
      selectionContext: NotificationSelectionContext.fromSnapshot(
        snapshot,
        displayName: 'Nora',
        habitName: 'Leer',
        weekdayLabel: 'sabado',
        timeOfDayLabel: '09:00',
      ),
    );
    final builder = PersonalizedNotificationPlanBuilder(
      contextBuilder: _FixedContextBuilder(contextResult),
      templateCatalog: InMemoryNotificationTemplateCatalog(
        templates: <NotificationTemplateDescriptor>[
          NotificationTemplateDescriptor(
            templateId: 'general.encouragement.neutral_01',
            templateKey: 'generalEncouragementNeutral01',
            localeNamespace: 'personalizedNotifications',
            category: NotificationTemplateCategory.encouragement,
            eligibility: NotificationTemplateEligibility.none(),
            isFallbackCandidate: true,
            weight: 10,
            cooldown: const Duration(hours: 4),
            maxUsesPer7d: 5,
            compatibleKinds: const <NotificationKind>[
              NotificationKind.generalProgressNudge,
              NotificationKind.generalDailyReflection,
            ],
          ),
          NotificationTemplateDescriptor(
            templateId: 'general.streak.encouragement_01',
            templateKey: 'generalStreakEncouragement01',
            localeNamespace: 'personalizedNotifications',
            category: NotificationTemplateCategory.streak,
            eligibility: NotificationTemplateEligibility(
              requiresCompletedDay: false,
              requiresStreak: true,
              minStreak: 3,
              requiresDisplayName: false,
              requiresInactivity: false,
            ),
            isFallbackCandidate: false,
            declaredVariables: const <NotificationTemplateVariable>[
              NotificationTemplateVariable.streak,
            ],
            requiredVariables: const <NotificationTemplateVariable>[
              NotificationTemplateVariable.streak,
            ],
            weight: 12,
            cooldown: const Duration(hours: 4),
            maxUsesPer7d: 5,
            compatibleKinds: const <NotificationKind>[
              NotificationKind.generalStreakRisk,
            ],
          ),
        ],
      ),
      platformIdProvider: _IntegrationPlatformIdProvider(),
    );
    final plan = await builder.build(
      scope: scope,
      trigger: NotificationTriggerReason.appBootstrap,
      preferences: NotificationPreferences.defaults(),
    );
    final manifest = NotificationScheduleManifest(
      scope: scope,
      scopeEpochAtPlanTime: scope.scopeEpoch,
      timezoneId: 'Europe/Madrid',
      lastReconciledAt: DateTime(2026, 8, 29, 9, 0).toUtc(),
      lastReconciledDate: DateTime(2026, 8, 29),
      entries: const <NotificationManifestEntry>[],
      platformIdIndex: const <String, int>{},
    );
    const reconciler = NotificationReconciler();

    final firstPlan = reconciler.reconcile(
      desiredPlan: plan,
      manifest: manifest,
    );
    final firstExecution = await reconciler.execute(
      plan: firstPlan,
      manifest: manifest,
      executor: InMemoryNotificationScheduleExecutor(),
      reconciledAt: DateTime(2026, 8, 29, 9, 5),
    );
    final secondPlan = reconciler.reconcile(
      desiredPlan: plan,
      manifest: firstExecution.nextManifest,
    );

    expect(
      firstPlan.operations.any(
        (operation) =>
            operation.type == NotificationReconciliationOperationType.create,
      ),
      isTrue,
    );
    expect(
      secondPlan.operations.every(
        (operation) =>
            operation.type == NotificationReconciliationOperationType.keep,
      ),
      isTrue,
    );
  });
}

class _FixedContextBuilder implements NotificationPlanningContextBuilder {
  const _FixedContextBuilder(this.result);

  final NotificationContextBuildResult result;

  @override
  Future<NotificationContextBuildResult> buildForScope({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    return result;
  }
}

class _IntegrationPlatformIdProvider implements NotificationPlatformIdProvider {
  final Map<String, int> _platformIds = <String, int>{};

  @override
  Future<int> getOrAllocate(
    NotificationScope scope, {
    required NotificationFamily family,
    required String notificationKey,
    String timezoneId = 'unknown',
  }) async {
    return _platformIds.putIfAbsent(
      notificationKey,
      () =>
          NotificationIdNamespace.rangeForFamily(family).start +
          _platformIds.length,
    );
  }
}
