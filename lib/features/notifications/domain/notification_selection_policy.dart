import 'notification_selection_models.dart';
import 'notification_template_content.dart';
import 'personalized_notification_models.dart';

class NotificationSelectionPolicy {
  const NotificationSelectionPolicy();

  static const Duration categoryCooldown = Duration(hours: 24);
  static const Duration recentSelectionWindow = Duration(hours: 6);

  NotificationSelectionSuppressionReason? upfrontSuppressionReason({
    required NotificationSelectionContext context,
    required NotificationPreferences preferences,
  }) {
    if (!preferences.masterEnabled) {
      return NotificationSelectionSuppressionReason.notificationsDisabled;
    }
    if (!preferences.generalNotificationsEnabled) {
      return NotificationSelectionSuppressionReason.personalizedDisabled;
    }
    if (_isInQuietHours(context.now, preferences)) {
      return NotificationSelectionSuppressionReason.quietHours;
    }
    return null;
  }

  List<NotificationSelectionOpportunity> discoverOpportunities(
    NotificationSelectionContext context,
    NotificationPreferences preferences,
  ) {
    final opportunities = <NotificationSelectionOpportunity>[];

    if ((context.inactivityDays ?? -1) >= 3) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalInactivity,
          reason: NotificationSelectionReason.comebackPriority,
          priority: 100,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.comeback,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.encouragement,
            NotificationTemplateCategory.gentleMotivation,
          ],
        ),
      );
    }

    if (context.hasCompletedDay) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalDayClosure,
          reason: NotificationSelectionReason.completedDayPriority,
          priority: 92,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.completedDay,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.reflection,
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    if ((context.streak ?? 0) >= 3) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalStreakRisk,
          reason: NotificationSelectionReason.streakPriority,
          priority: 88,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.streak,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.consistency,
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    if ((context.pendingCount ?? 0) > 0) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalDayClosure,
          reason: NotificationSelectionReason.pendingProgressPriority,
          priority: 78 + (context.pendingCount!.clamp(0, 3) * 2),
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.pendingProgress,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.gentleMotivation,
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    if ((context.progressRatio ?? -1) >= 0.6 &&
        (context.progressRatio ?? 0) < 1) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalProgressNudge,
          reason: NotificationSelectionReason.strongProgressPriority,
          priority: 74,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.strongProgress,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.consistency,
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    if ((context.progressRatio ?? 0) > 0 && (context.progressRatio ?? 1) < 1) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalProgressNudge,
          reason: NotificationSelectionReason.consistencyPriority,
          priority: 68,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.consistency,
            NotificationTemplateCategory.encouragement,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.gentleMotivation,
          ],
        ),
      );
    }

    if (context.timeOfDay == NotificationContextTimeOfDay.evening ||
        context.timeOfDay == NotificationContextTimeOfDay.night) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalDailyReflection,
          reason: NotificationSelectionReason.reflectionPriority,
          priority: context.latestDiaryEntryAt == null ? 64 : 56,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.reflection,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    if (context.timeOfDay == NotificationContextTimeOfDay.morning) {
      opportunities.add(
        NotificationSelectionOpportunity(
          kind: NotificationKind.generalProgressNudge,
          reason: NotificationSelectionReason.morningPriority,
          priority: 60,
          primaryCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.morning,
          ],
          fallbackCategories: const <NotificationTemplateCategory>[
            NotificationTemplateCategory.gentleMotivation,
            NotificationTemplateCategory.encouragement,
          ],
        ),
      );
    }

    opportunities.add(
      NotificationSelectionOpportunity(
        kind: NotificationKind.generalProgressNudge,
        reason: NotificationSelectionReason.safeFallback,
        priority: _fallbackPriorityFor(preferences.intensityPreset),
        primaryCategories: const <NotificationTemplateCategory>[
          NotificationTemplateCategory.encouragement,
          NotificationTemplateCategory.gentleMotivation,
        ],
        fallbackCategories:
            context.timeOfDay == NotificationContextTimeOfDay.morning
                ? const <NotificationTemplateCategory>[
                    NotificationTemplateCategory.morning,
                  ]
                : const <NotificationTemplateCategory>[],
      ),
    );

    return opportunities;
  }

  bool isTemplateEligible({
    required NotificationTemplateDescriptor template,
    required NotificationSelectionContext context,
  }) {
    final eligibility = template.eligibility;
    if (eligibility.allowedTimesOfDay.isNotEmpty &&
        !eligibility.allowedTimesOfDay.contains(context.timeOfDay)) {
      return false;
    }
    if (eligibility.minProgressRatio != null &&
        (context.progressRatio == null ||
            context.progressRatio! < eligibility.minProgressRatio!)) {
      return false;
    }
    if (eligibility.maxProgressRatio != null &&
        (context.progressRatio == null ||
            context.progressRatio! > eligibility.maxProgressRatio!)) {
      return false;
    }
    if (eligibility.minPendingCount != null &&
        (context.pendingCount == null ||
            context.pendingCount! < eligibility.minPendingCount!)) {
      return false;
    }
    if (eligibility.maxPendingCount != null &&
        (context.pendingCount == null ||
            context.pendingCount! > eligibility.maxPendingCount!)) {
      return false;
    }
    if (eligibility.minCompletedCount != null &&
        (context.completedCount == null ||
            context.completedCount! < eligibility.minCompletedCount!)) {
      return false;
    }
    if (eligibility.minTotalCount != null &&
        (context.totalCount == null ||
            context.totalCount! < eligibility.minTotalCount!)) {
      return false;
    }
    if (eligibility.requiresCompletedDay && !context.hasCompletedDay) {
      return false;
    }
    if (eligibility.requiresStreak && context.streak == null) {
      return false;
    }
    if (eligibility.minStreak != null &&
        (context.streak == null || context.streak! < eligibility.minStreak!)) {
      return false;
    }
    if (eligibility.requiresDisplayName && !_hasText(context.displayName)) {
      return false;
    }
    if (eligibility.requiresInactivity && context.inactivityDays == null) {
      return false;
    }
    if (eligibility.minInactivityDays != null &&
        (context.inactivityDays == null ||
            context.inactivityDays! < eligibility.minInactivityDays!)) {
      return false;
    }

    final renderContext = context.toRenderContext();
    return template.requiredVariables
        .every((variable) => renderContext.hasValueFor(variable));
  }

  double contextualWeightMultiplier({
    required NotificationTemplateDescriptor template,
    required NotificationSelectionOpportunity opportunity,
    required NotificationSelectionContext context,
    required NotificationPreferences preferences,
  }) {
    var multiplier =
        opportunity.isPrimaryCategory(template.category) ? 1.25 : 0.9;

    switch (preferences.intensityPreset) {
      case NotificationIntensityPreset.light:
        if (template.category == NotificationTemplateCategory.strongProgress ||
            template.category == NotificationTemplateCategory.streak) {
          multiplier *= 0.92;
        }
      case NotificationIntensityPreset.balanced:
        multiplier *= 1.0;
      case NotificationIntensityPreset.active:
        if (template.category == NotificationTemplateCategory.strongProgress ||
            template.category == NotificationTemplateCategory.streak ||
            template.category == NotificationTemplateCategory.comeback) {
          multiplier *= 1.15;
        }
    }

    if (context.hasCompletedDay &&
        template.category == NotificationTemplateCategory.completedDay) {
      multiplier *= 1.2;
    }
    if ((context.inactivityDays ?? 0) >= 3 &&
        template.category == NotificationTemplateCategory.comeback) {
      multiplier *= 1.25;
    }
    if ((context.progressRatio ?? 0) >= 0.75 &&
        template.category == NotificationTemplateCategory.strongProgress) {
      multiplier *= 1.15;
    }
    if ((context.streak ?? 0) >= 7 &&
        template.category == NotificationTemplateCategory.streak) {
      multiplier *= 1.1;
    }
    return multiplier;
  }

  double antiRepeatPenalty({
    required NotificationTemplateDescriptor template,
    required NotificationSelectionContext context,
    required NotificationSelectionOpportunity opportunity,
  }) {
    final recent = context.recentMessageHistory.recentDeliveries;
    if (recent.isEmpty) {
      return 1.0;
    }

    var penalty = 1.0;
    final recentCategories = recent
        .take(3)
        .map((record) => record.categoryTag)
        .whereType<String>()
        .toList(growable: false);
    final sameCategoryCount = recentCategories
        .where((category) => category == template.category.wireName)
        .length;
    if (sameCategoryCount >= 2) {
      penalty *= 0.55;
    } else if (sameCategoryCount == 1) {
      penalty *= 0.8;
    }

    if (recent.first.kind == opportunity.kind) {
      penalty *= 0.85;
    }

    final usesIn7d = recent.where((record) {
      return record.templateId == template.templateId &&
          context.now.difference(record.scheduledAt) <= const Duration(days: 7);
    }).length;
    if (usesIn7d > 0) {
      penalty *= 1 - (usesIn7d * 0.12).clamp(0, 0.36);
    }

    return penalty.clamp(0.1, 1.0);
  }

  bool isTemplateBlockedByCooldown({
    required NotificationTemplateDescriptor template,
    required NotificationSelectionContext context,
    required NotificationSelectionOpportunity opportunity,
    required bool ignoreCategoryCooldown,
    required bool ignoreTemplateCooldown,
    required bool allowLastTemplateFallback,
  }) {
    final lastTemplateAt = context
        .recentMessageHistory.lastSelectedAtByTemplateId[template.templateId];
    if (!ignoreTemplateCooldown &&
        lastTemplateAt != null &&
        context.now.difference(lastTemplateAt) < template.cooldown) {
      return true;
    }

    final lastRecord = context.recentMessageHistory.recentDeliveries.isEmpty
        ? null
        : context.recentMessageHistory.recentDeliveries.first;
    if (!allowLastTemplateFallback &&
        lastRecord != null &&
        lastRecord.templateId == template.templateId &&
        context.now.difference(lastRecord.scheduledAt) <
            recentSelectionWindow) {
      return true;
    }

    final categoryKey = template.category.wireName;
    final lastCategoryAt =
        context.recentMessageHistory.lastSelectedAtByCategoryTag[categoryKey];
    if (!ignoreCategoryCooldown &&
        lastCategoryAt != null &&
        context.now.difference(lastCategoryAt) < categoryCooldown) {
      return true;
    }

    final usesIn7d =
        context.recentMessageHistory.recentDeliveries.where((record) {
      return record.templateId == template.templateId &&
          context.now.difference(record.scheduledAt) <= const Duration(days: 7);
    }).length;
    if (usesIn7d >= template.maxUsesPer7d) {
      return true;
    }

    return false;
  }

  NotificationSelectionSuppressionReason suppressionReasonForEmptyCatalog({
    required NotificationSelectionContext context,
    required List<NotificationSelectionOpportunity> opportunities,
  }) {
    if (opportunities.isEmpty) {
      return NotificationSelectionSuppressionReason.unsupportedContext;
    }
    if (!_hasAnyRenderSignal(context)) {
      return NotificationSelectionSuppressionReason.missingRequiredContext;
    }
    return NotificationSelectionSuppressionReason.noEligibleTemplates;
  }
}

double _fallbackPriorityFor(NotificationIntensityPreset preset) {
  switch (preset) {
    case NotificationIntensityPreset.light:
      return 34;
    case NotificationIntensityPreset.balanced:
      return 40;
    case NotificationIntensityPreset.active:
      return 46;
  }
}

bool _isInQuietHours(DateTime now, NotificationPreferences preferences) {
  final start = preferences.quietHoursStart;
  final end = preferences.quietHoursEnd;
  if (start == null || end == null) {
    return false;
  }

  final minutesNow = now.hour * 60 + now.minute;
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;

  if (startMinutes == endMinutes) {
    return true;
  }
  if (startMinutes < endMinutes) {
    return minutesNow >= startMinutes && minutesNow < endMinutes;
  }
  return minutesNow >= startMinutes || minutesNow < endMinutes;
}

bool _hasAnyRenderSignal(NotificationSelectionContext context) {
  return _hasText(context.displayName) ||
      context.progressRatio != null ||
      context.pendingCount != null ||
      context.completedCount != null ||
      context.totalCount != null ||
      context.streak != null ||
      context.inactivityDays != null ||
      _hasText(context.habitName) ||
      _hasText(context.weekdayLabel) ||
      _hasText(context.timeOfDayLabel);
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
