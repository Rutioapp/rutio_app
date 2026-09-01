import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  final policy = NotificationSelectionPolicy();

  NotificationSelectionContext buildContext({
    DateTime? now,
    NotificationContextTimeOfDay? timeOfDay,
    String? displayName,
    double? progressRatio,
    int? pendingCount,
    int? completedCount,
    int? totalCount,
    int? streak,
    int? inactivityDays,
    String? habitName,
    bool journalWrittenToday = false,
    NotificationMessageHistorySnapshot? recentMessageHistory,
    JournalMilestoneSignal? journalMilestoneSignal,
  }) {
    return NotificationSelectionContext(
      scope: NotificationScope(
        userId: 'user-1',
        scopeEpoch: 1,
        installId: 'install-1',
        locale: 'es',
      ),
      now: now ?? DateTime(2026, 8, 28, 9, 0),
      timezoneId: 'Europe/Madrid',
      timeOfDay: timeOfDay,
      displayName: displayName,
      progressRatio: progressRatio,
      pendingCount: pendingCount,
      completedCount: completedCount,
      totalCount: totalCount,
      streak: streak,
      inactivityDays: inactivityDays,
      habitName: habitName,
      weekdayLabel: 'viernes',
      timeOfDayLabel: '09:00',
      journalWrittenToday: journalWrittenToday,
      recentMessageHistory: recentMessageHistory,
      journalMilestoneSignal: journalMilestoneSignal,
    );
  }

  NotificationTemplateDescriptor buildTemplate({
    required String templateId,
    required NotificationTemplateCategory category,
    NotificationTemplateEligibility? eligibility,
    List<NotificationTemplateVariable> declaredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationTemplateVariable> requiredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationKind> compatibleKinds = const <NotificationKind>[
      NotificationKind.generalProgressNudge
    ],
  }) {
    return NotificationTemplateDescriptor(
      templateId: templateId,
      templateKey: 'generalMorningGentle01',
      localeNamespace: 'personalizedNotifications',
      category: category,
      eligibility: eligibility,
      isFallbackCandidate: false,
      variantTags: const <String>['test'],
      declaredVariables: declaredVariables,
      requiredVariables: requiredVariables,
      weight: 10,
      cooldown: const Duration(hours: 48),
      maxUsesPer7d: 3,
      compatibleKinds: compatibleKinds,
    );
  }

  group('NotificationSelectionPolicy eligibility', () {
    test('distinguishes known zero progress from missing progress', () {
      final template = buildTemplate(
        templateId: 'progress.known',
        category: NotificationTemplateCategory.gentleMotivation,
        eligibility: NotificationTemplateEligibility(
          minProgressRatio: 0.0,
          requiresCompletedDay: false,
          requiresStreak: false,
          requiresDisplayName: false,
          requiresInactivity: false,
        ),
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(progressRatio: 0.0),
        ),
        isTrue,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(progressRatio: null),
        ),
        isFalse,
      );
    });

    test('requires displayName when declared by eligibility', () {
      final template = buildTemplate(
        templateId: 'name.required',
        category: NotificationTemplateCategory.encouragement,
        eligibility: NotificationTemplateEligibility(
          requiresCompletedDay: false,
          requiresStreak: false,
          requiresDisplayName: true,
          requiresInactivity: false,
        ),
        declaredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.displayName,
        ],
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(displayName: null),
        ),
        isFalse,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(displayName: 'Nora'),
        ),
        isTrue,
      );
    });

    test('filters by morning time window', () {
      final template = buildTemplate(
        templateId: 'morning.only',
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
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context:
              buildContext(timeOfDay: NotificationContextTimeOfDay.morning),
        ),
        isTrue,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context:
              buildContext(timeOfDay: NotificationContextTimeOfDay.evening),
        ),
        isFalse,
      );
    });

    test('filters pending progress templates by pendingCount', () {
      final template = buildTemplate(
        templateId: 'pending.only',
        category: NotificationTemplateCategory.pendingProgress,
        eligibility: NotificationTemplateEligibility(
          minPendingCount: 1,
          requiresCompletedDay: false,
          requiresStreak: false,
          requiresDisplayName: false,
          requiresInactivity: false,
        ),
        declaredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.pendingCount,
        ],
        requiredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.pendingCount,
        ],
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(pendingCount: 0),
        ),
        isFalse,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(pendingCount: 2),
        ),
        isTrue,
      );
    });

    test('filters streak templates by minimum streak', () {
      final template = buildTemplate(
        templateId: 'streak.only',
        category: NotificationTemplateCategory.streak,
        eligibility: NotificationTemplateEligibility(
          requiresCompletedDay: false,
          requiresStreak: true,
          minStreak: 3,
          requiresDisplayName: false,
          requiresInactivity: false,
        ),
        declaredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.streak,
        ],
        requiredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.streak,
        ],
        compatibleKinds: const <NotificationKind>[
          NotificationKind.generalStreakRisk,
        ],
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(streak: 2),
        ),
        isFalse,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(streak: 4),
        ),
        isTrue,
      );
    });

    test('filters comeback templates by inactivity threshold', () {
      final template = buildTemplate(
        templateId: 'comeback.only',
        category: NotificationTemplateCategory.comeback,
        eligibility: NotificationTemplateEligibility(
          requiresCompletedDay: false,
          requiresStreak: false,
          requiresDisplayName: false,
          requiresInactivity: true,
          minInactivityDays: 3,
        ),
        compatibleKinds: const <NotificationKind>[
          NotificationKind.generalInactivity,
        ],
      );

      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(inactivityDays: 2),
        ),
        isFalse,
      );
      expect(
        policy.isTemplateEligible(
          template: template,
          context: buildContext(inactivityDays: 4),
        ),
        isTrue,
      );
    });
  });

  group('NotificationSelectionPolicy priority and weighting', () {
    test('discovers perfect-day journal nudge when the day is complete', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          timeOfDay: NotificationContextTimeOfDay.evening,
          progressRatio: 1.0,
          completedCount: 3,
          totalCount: 3,
          pendingCount: 0,
        ),
        NotificationPreferences.defaults(),
      );

      final journal = opportunities.where(
        (opportunity) => opportunity.kind == NotificationKind.journalNudge,
      );
      expect(journal, hasLength(1));
      expect(
          journal.single.journalNudgeContext, JournalNudgeContext.perfectDay);
      expect(journal.single.reason,
          NotificationSelectionReason.journalPerfectDayPriority);
    });

    test('does not discover journal nudges after writing today', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          timeOfDay: NotificationContextTimeOfDay.evening,
          progressRatio: 1.0,
          completedCount: 3,
          totalCount: 3,
          pendingCount: 0,
          journalWrittenToday: true,
        ),
        NotificationPreferences.defaults(),
      );

      expect(
        opportunities.where(
          (opportunity) => opportunity.kind == NotificationKind.journalNudge,
        ),
        isEmpty,
      );
    });

    test('discovers conservative end-of-day journal nudge from activity', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          completedCount: 1,
          totalCount: 3,
          pendingCount: 2,
          progressRatio: 1 / 3,
        ),
        NotificationPreferences.defaults(),
      );

      final journal = opportunities.where(
        (opportunity) => opportunity.kind == NotificationKind.journalNudge,
      );
      expect(journal, hasLength(1));
      expect(journal.single.journalNudgeContext, JournalNudgeContext.endOfDay);
    });

    test('does not discover end-of-day nudge without meaningful activity', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(totalCount: 3, pendingCount: 3, progressRatio: 0),
        NotificationPreferences.defaults(),
      );

      expect(
        opportunities.where(
          (opportunity) => opportunity.kind == NotificationKind.journalNudge,
        ),
        isEmpty,
      );
    });

    test('perfect day suppresses redundant end-of-day opportunity', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          completedCount: 3,
          totalCount: 3,
          pendingCount: 0,
          progressRatio: 1,
        ),
        NotificationPreferences.defaults(),
      );

      expect(
        opportunities.where(
          (opportunity) => opportunity.kind == NotificationKind.journalNudge,
        ),
        hasLength(1),
      );
    });
    test('discovers perfect-day journal nudge ahead of generic fallback', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          timeOfDay: NotificationContextTimeOfDay.evening,
          progressRatio: 1.0,
          completedCount: 3,
          totalCount: 3,
          pendingCount: 0,
        ),
        NotificationPreferences.defaults(),
      );

      expect(opportunities.first.reason,
          NotificationSelectionReason.journalPerfectDayPriority);
    });

    test('discovers comeback ahead of morning when inactivity is present', () {
      final opportunities = policy.discoverOpportunities(
        buildContext(
          timeOfDay: NotificationContextTimeOfDay.morning,
          inactivityDays: 5,
        ),
        NotificationPreferences.defaults(),
      );

      expect(opportunities.first.reason,
          NotificationSelectionReason.comebackPriority);
    });

    test('active intensity boosts strong progress more than light intensity',
        () {
      final template = buildTemplate(
        templateId: 'strong.progress',
        category: NotificationTemplateCategory.strongProgress,
      );
      final opportunity = NotificationSelectionOpportunity(
        kind: NotificationKind.generalProgressNudge,
        reason: NotificationSelectionReason.strongProgressPriority,
        priority: 74,
        primaryCategories: const <NotificationTemplateCategory>[
          NotificationTemplateCategory.strongProgress,
        ],
      );
      final context = buildContext(progressRatio: 0.8);

      final lightWeight = policy.contextualWeightMultiplier(
        template: template,
        opportunity: opportunity,
        context: context,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.light,
        ),
      );
      final activeWeight = policy.contextualWeightMultiplier(
        template: template,
        opportunity: opportunity,
        context: context,
        preferences: NotificationPreferences.defaults().copyWith(
          intensityPreset: NotificationIntensityPreset.active,
        ),
      );

      expect(activeWeight, greaterThan(lightWeight));
    });
  });

  group('NotificationSelectionPolicy journal frequency', () {
    NotificationSelectionOpportunity journalOpportunity() {
      return NotificationSelectionOpportunity(
        kind: NotificationKind.journalNudge,
        journalNudgeContext: JournalNudgeContext.endOfDay,
        reason: NotificationSelectionReason.journalEndOfDayPriority,
        priority: 72,
        primaryCategories: const <NotificationTemplateCategory>[
          NotificationTemplateCategory.journalNudge,
        ],
      );
    }

    NotificationTemplateDescriptor journalTemplate() {
      return buildTemplate(
        templateId: 'journal.nudge.test',
        category: NotificationTemplateCategory.journalNudge,
        compatibleKinds: const <NotificationKind>[
          NotificationKind.journalNudge,
        ],
      );
    }

    NotificationDeliveryRecord journalRecord(DateTime at) {
      return NotificationDeliveryRecord(
        notificationKey: 'journal-${at.toIso8601String()}',
        userId: 'user-1',
        templateId: 'journal.nudge.test',
        kind: NotificationKind.journalNudge,
        scheduledAt: at,
        categoryTag: NotificationTemplateCategory.journalNudge.wireName,
      );
    }

    bool blocked(
      DateTime now,
      List<DateTime> sentAt, {
      bool ignoreCategoryCooldown = false,
    }) {
      final records = sentAt.map(journalRecord).toList(growable: false);
      final history = NotificationMessageHistorySnapshot(
        recentDeliveries: records,
        lastSelectedAtByCategoryTag: records.isEmpty
            ? const <String, DateTime>{}
            : <String, DateTime>{
                NotificationTemplateCategory.journalNudge.wireName:
                    records.map((record) => record.scheduledAt).reduce(
                          (a, b) => a.isAfter(b) ? a : b,
                        ),
              },
      );
      return policy.isTemplateBlockedByCooldown(
        template: journalTemplate(),
        context: buildContext(
          now: now,
          recentMessageHistory: history,
        ),
        opportunity: journalOpportunity(),
        ignoreCategoryCooldown: ignoreCategoryCooldown,
        ignoreTemplateCooldown: false,
        allowLastTemplateFallback: false,
      );
    }

    test('enforces 48 hours inclusively across journal contexts', () {
      final now = DateTime(2026, 8, 28, 9);
      expect(blocked(now, [now.subtract(const Duration(hours: 24))]), isTrue);
      expect(
        blocked(now, [now.subtract(const Duration(hours: 47, minutes: 59))]),
        isTrue,
      );
      expect(
        blocked(now, [now.subtract(const Duration(hours: 48))]),
        isFalse,
      );
      expect(
        blocked(now, [now.subtract(const Duration(hours: 48))],
            ignoreCategoryCooldown: true),
        isFalse,
      );
    });

    test('enforces rolling cap of two and excludes expired records', () {
      final now = DateTime(2026, 8, 28, 12);
      expect(
        blocked(now, [
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 5)),
        ]),
        isTrue,
      );
      expect(
        blocked(now, [
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 7, seconds: 1)),
        ]),
        isFalse,
      );
      expect(
        blocked(now, [
          now.subtract(const Duration(days: 2)),
          now.subtract(const Duration(days: 7)),
        ]),
        isTrue,
      );
    });

    test('blocks a previous local calendar day even when cooldown is bypassed',
        () {
      final now = DateTime(2026, 9, 1, 22);
      expect(
        blocked(now, [DateTime(2026, 8, 31, 8)], ignoreCategoryCooldown: true),
        isTrue,
      );
      expect(
        blocked(now, [DateTime(2026, 8, 30, 8)], ignoreCategoryCooldown: true),
        isFalse,
      );
    });

    test('other categories do not consume journal frequency', () {
      final now = DateTime(2026, 8, 28, 12);
      final history = NotificationMessageHistorySnapshot(
        recentDeliveries: <NotificationDeliveryRecord>[
          NotificationDeliveryRecord(
            notificationKey: 'generic-1',
            userId: 'user-1',
            templateId: 'general.reflection',
            kind: NotificationKind.generalDailyReflection,
            scheduledAt: now.subtract(const Duration(hours: 1)),
            categoryTag: NotificationTemplateCategory.reflection.wireName,
          ),
        ],
      );
      expect(
        policy.isTemplateBlockedByCooldown(
          template: journalTemplate(),
          context: buildContext(
            now: now,
            recentMessageHistory: history,
          ),
          opportunity: journalOpportunity(),
          ignoreCategoryCooldown: false,
          ignoreTemplateCooldown: false,
          allowLastTemplateFallback: false,
        ),
        isFalse,
      );
    });
  });

  group('NotificationSelectionPolicy habit milestones', () {
    JournalMilestoneSignal milestone({
      int value = 7,
      DateTime? sentAt,
    }) {
      final at = sentAt ?? DateTime(2026, 8, 28, 8);
      return JournalMilestoneSignal(
        habitId: 'habit-1',
        milestone: value,
        dateKey: '2026-08-28',
        sentAt: at,
      );
    }

    List<NotificationSelectionOpportunity> discover({
      required DateTime now,
      JournalMilestoneSignal? signal,
      bool journalWrittenToday = false,
      int? completedCount,
      int? totalCount,
    }) {
      return policy.discoverOpportunities(
        buildContext(
          now: now,
          journalMilestoneSignal: signal,
          journalWrittenToday: journalWrittenToday,
          completedCount: completedCount,
          totalCount: totalCount,
          pendingCount: totalCount == null || completedCount == null
              ? null
              : totalCount - completedCount,
          progressRatio: completedCount == null || totalCount == null
              ? null
              : completedCount / totalCount,
        ),
        NotificationPreferences.defaults(),
      );
    }

    test('accepts only supported milestones with a timestamp', () {
      for (final value in <int>[7, 14, 30]) {
        final opportunities = discover(
          now: DateTime(2026, 8, 28, 10),
          signal: milestone(value: value),
        );
        expect(
          opportunities.where(
            (item) =>
                item.journalNudgeContext == JournalNudgeContext.habitMilestone,
          ),
          hasLength(1),
        );
      }
      expect(
        discover(
          now: DateTime(2026, 8, 28, 10),
          signal: milestone(value: 6),
        ).where((item) => item.kind == NotificationKind.journalNudge),
        isEmpty,
      );
    });

    test('opens the inclusive one-to-three hour contextual window', () {
      final sentAt = DateTime(2026, 8, 28, 8);
      expect(
        discover(
                now: sentAt.add(const Duration(minutes: 59)),
                signal: milestone(sentAt: sentAt))
            .where((item) => item.kind == NotificationKind.journalNudge),
        isEmpty,
      );
      expect(
        discover(
                now: sentAt.add(const Duration(hours: 1)),
                signal: milestone(sentAt: sentAt))
            .where((item) => item.kind == NotificationKind.journalNudge),
        hasLength(1),
      );
      expect(
        discover(
                now: sentAt.add(const Duration(hours: 3)),
                signal: milestone(sentAt: sentAt))
            .where((item) => item.kind == NotificationKind.journalNudge),
        hasLength(1),
      );
      expect(
        discover(
                now: sentAt.add(const Duration(hours: 3, minutes: 1)),
                signal: milestone(sentAt: sentAt))
            .where((item) => item.kind == NotificationKind.journalNudge),
        isEmpty,
      );
    });

    test('milestone outranks perfect day and end of day', () {
      final opportunities = discover(
        now: DateTime(2026, 8, 28, 10),
        signal: milestone(),
        completedCount: 3,
        totalCount: 3,
      );

      final journal = opportunities
          .where(
            (item) => item.kind == NotificationKind.journalNudge,
          )
          .toList();
      expect(journal, hasLength(1));
      expect(journal.single.journalNudgeContext,
          JournalNudgeContext.habitMilestone);
      expect(journal.single.priority, greaterThan(94));
    });

    test('journal guard blocks milestone before it reaches selection', () {
      final opportunities = discover(
        now: DateTime(2026, 8, 28, 10),
        signal: milestone(),
        journalWrittenToday: true,
      );
      expect(
        opportunities
            .where((item) => item.kind == NotificationKind.journalNudge),
        isEmpty,
      );
    });
  });
}
