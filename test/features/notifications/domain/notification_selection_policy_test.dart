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
    test('discovers completed day ahead of generic fallback', () {
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
          NotificationSelectionReason.completedDayPriority);
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
}
