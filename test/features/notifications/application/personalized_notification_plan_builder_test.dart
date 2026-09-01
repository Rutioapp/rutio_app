import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/application/notification_context_builder.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:rutio/services/phase1_notification_timing_registry.dart';

void main() {
  NotificationScope buildScope() {
    return NotificationScope(
      userId: 'user-1',
      scopeEpoch: 2,
      installId: 'install-1',
      locale: 'es',
    );
  }

  NotificationContextBuildResult buildContextResult({
    DateTime? now,
    int pendingCount = 2,
    int completedCount = 1,
    int totalCount = 3,
    int? streak = 5,
  }) {
    final scope = buildScope();
    final currentTime = now ?? DateTime(2026, 8, 29, 9, 0);
    final snapshot = NotificationContextSnapshot(
      scope: scope,
      now: currentTime,
      timezoneId: 'Europe/Madrid',
      calendarDate: DateTime(2026, 8, 29),
      pendingHabitsToday:
          List<String>.generate(pendingCount, (index) => 'p$index'),
      completedHabitsToday:
          List<String>.generate(completedCount, (index) => 'c$index'),
      progressTodayRatio: totalCount == 0 ? null : completedCount / totalCount,
      bestStreakRisk: streak == null
          ? null
          : NotificationStreakRisk(
              habitId: 'habit-1',
              habitName: 'Leer',
              streakLength: streak,
            ),
      schedulingCapabilities: const NotificationSchedulingCapabilities(
        permissionStatus: NotificationSystemPermissionStatus.authorized,
        canScheduleNewEntries: true,
        canCancelExistingEntries: true,
      ),
    );
    final selectionContext = NotificationSelectionContext.fromSnapshot(
      snapshot,
      displayName: 'Nora',
      habitName: 'Leer',
      weekdayLabel: 'sabado',
      timeOfDayLabel: '09:00',
    );
    return NotificationContextBuildResult.success(
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
      selectionContext: selectionContext,
    );
  }

  group('PersonalizedNotificationPlanBuilder', () {
    test('returns personalizedDisabled plan without creating desired entries',
        () async {
      final builder = PersonalizedNotificationPlanBuilder(
        contextBuilder: _FakePlanningContextBuilder(buildContextResult()),
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[
            _fallbackTemplate('general.encouragement.neutral_01'),
          ],
        ),
        platformIdProvider: _FakePlatformIdProvider(),
      );

      final plan = await builder.build(
        scope: buildScope(),
        trigger: NotificationTriggerReason.appBootstrap,
        preferences: NotificationPreferences.defaults().copyWith(
          generalNotificationsEnabled: false,
        ),
      );

      expect(plan.status, DesiredNotificationPlanStatus.personalizedDisabled);
      expect(plan.notifications, isEmpty);
    });

    test('builds deterministic desired notifications within cap and horizon',
        () async {
      final catalog = InMemoryNotificationTemplateCatalog(
        templates: <NotificationTemplateDescriptor>[
          _fallbackTemplate('general.encouragement.neutral_01'),
          _streakTemplate('general.streak.encouragement_01'),
          _morningTemplate('general.morning.gentle_01'),
        ],
      );
      final builder = PersonalizedNotificationPlanBuilder(
        contextBuilder: _FakePlanningContextBuilder(buildContextResult()),
        templateCatalog: catalog,
        platformIdProvider: _FakePlatformIdProvider(),
        habitReminderLoadProvider:
            const _FixedHabitReminderLoadProvider(reminderCount: 0),
      );

      final first = await builder.build(
        scope: buildScope(),
        trigger: NotificationTriggerReason.appBootstrap,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.balanced,
        ),
      );
      final second = await builder.build(
        scope: buildScope(),
        trigger: NotificationTriggerReason.appBootstrap,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.balanced,
        ),
      );

      expect(
          first.status,
          anyOf(
            DesiredNotificationPlanStatus.ready,
            DesiredNotificationPlanStatus.empty,
          ));
      expect(first.notifications.length, lessThanOrEqualTo(2));
      expect(
        first.notifications.every(
          (notification) =>
              notification.intendedLocalDateTime
                  .difference(first.generatedAt) <=
              const Duration(hours: 24),
        ),
        isTrue,
      );
      expect(
        first.notifications.map((notification) => notification.fingerprint),
        second.notifications.map((notification) => notification.fingerprint),
      );
    });

    test('reduces planned notifications when habit reminder load is high',
        () async {
      final builder = PersonalizedNotificationPlanBuilder(
        contextBuilder: _FakePlanningContextBuilder(buildContextResult()),
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[
            _fallbackTemplate('general.encouragement.neutral_01'),
            _streakTemplate('general.streak.encouragement_01'),
            _morningTemplate('general.morning.gentle_01'),
          ],
        ),
        platformIdProvider: _FakePlatformIdProvider(),
        habitReminderLoadProvider:
            const _FixedHabitReminderLoadProvider(reminderCount: 6),
      );

      final plan = await builder.build(
        scope: buildScope(),
        trigger: NotificationTriggerReason.appBootstrap,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.active,
          maxAdditionalContextualPerDay: 2,
        ),
      );

      expect(plan.notifications.length, lessThanOrEqualTo(2));
      expect(plan.diagnostics.detectedHabitReminderCount, 6);
    });

    test('drops a conflicting Phase 1 opportunity without consuming the cap',
        () async {
      final builder = PersonalizedNotificationPlanBuilder(
        contextBuilder: _FakePlanningContextBuilder(
          buildContextResult(now: DateTime(2026, 8, 29, 8, 0)),
        ),
        templateCatalog: InMemoryNotificationTemplateCatalog(
          templates: <NotificationTemplateDescriptor>[
            _fallbackTemplate('general.encouragement.neutral_01'),
            _streakTemplate('general.streak.encouragement_01'),
            _morningTemplate('general.morning.gentle_01'),
          ],
        ),
        platformIdProvider: _FakePlatformIdProvider(),
        phase1TimingSource: _FixedPhase1TimingSource(
          <Phase1NotificationScheduleIntent>[
            Phase1NotificationScheduleIntent(
              logicalId: 'habit_reminder:habit-1',
              platformId: 10001,
              kind: Phase1NotificationTimingKind.habitReminder,
              scheduledFor: DateTime(2026, 8, 29, 9, 45),
              isUserConfigured: true,
            ),
          ],
        ),
      );

      final plan = await builder.build(
        scope: buildScope(),
        trigger: NotificationTriggerReason.appBootstrap,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.balanced,
        ),
      );

      expect(plan.notifications, hasLength(2));
      expect(plan.opportunities.first.selectedLogicalNotificationId, isNull);
      expect(plan.diagnostics.suppressedOpportunityIds, contains('morning'));
    });
  });
}

class _FixedPhase1TimingSource implements Phase1NotificationTimingSource {
  const _FixedPhase1TimingSource(this.entries);

  final List<Phase1NotificationScheduleIntent> entries;

  @override
  Future<List<Phase1NotificationScheduleIntent>> upcomingForScope({
    String? scopeKey,
    DateTime? now,
    DateTime? horizonEnd,
  }) async =>
      entries;
}

class _FakePlanningContextBuilder
    implements NotificationPlanningContextBuilder {
  _FakePlanningContextBuilder(this.result);

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

class _FakePlatformIdProvider implements NotificationPlatformIdProvider {
  final Map<String, int> _ids = <String, int>{};

  @override
  Future<int> getOrAllocate(
    NotificationScope scope, {
    required NotificationFamily family,
    required String notificationKey,
    String timezoneId = 'unknown',
  }) async {
    return _ids.putIfAbsent(
      notificationKey,
      () => NotificationIdNamespace.rangeForFamily(family).start + _ids.length,
    );
  }
}

class _FixedHabitReminderLoadProvider
    implements NotificationHabitReminderLoadProvider {
  const _FixedHabitReminderLoadProvider({
    required this.reminderCount,
  });

  final int reminderCount;

  @override
  Future<int?> countForDay(
    NotificationScope scope, {
    required DateTime day,
  }) async {
    return reminderCount;
  }
}

NotificationTemplateDescriptor _fallbackTemplate(String templateId) {
  return NotificationTemplateDescriptor(
    templateId: templateId,
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
  );
}

NotificationTemplateDescriptor _streakTemplate(String templateId) {
  return NotificationTemplateDescriptor(
    templateId: templateId,
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
  );
}

NotificationTemplateDescriptor _morningTemplate(String templateId) {
  return NotificationTemplateDescriptor(
    templateId: templateId,
    templateKey: 'generalMorningGentle01',
    localeNamespace: 'personalizedNotifications',
    category: NotificationTemplateCategory.morning,
    eligibility: NotificationTemplateEligibility(
      allowedTimesOfDay: const <NotificationContextTimeOfDay>[
        NotificationContextTimeOfDay.morning,
      ],
      requiresCompletedDay: false,
      requiresStreak: false,
      requiresDisplayName: false,
      requiresInactivity: false,
    ),
    isFallbackCandidate: true,
    weight: 11,
    cooldown: const Duration(hours: 4),
    maxUsesPer7d: 5,
    compatibleKinds: const <NotificationKind>[
      NotificationKind.generalProgressNudge,
    ],
  );
}
