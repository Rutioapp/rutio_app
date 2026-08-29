import 'package:flutter/foundation.dart';

import '../domain/desired_notification.dart';
import '../domain/notification_selection_models.dart';
import '../domain/notification_template_content.dart';
import '../domain/personalized_notification_models.dart';

abstract class NotificationHabitReminderLoadProvider {
  Future<int?> countForDay(
    NotificationScope scope, {
    required DateTime day,
  });
}

class NullNotificationHabitReminderLoadProvider
    implements NotificationHabitReminderLoadProvider {
  const NullNotificationHabitReminderLoadProvider();

  @override
  Future<int?> countForDay(
    NotificationScope scope, {
    required DateTime day,
  }) async {
    return null;
  }
}

class NotificationSchedulePolicy {
  const NotificationSchedulePolicy({
    this.horizon = const Duration(hours: 24),
    this.defaultQuietHoursStart = const NotificationClockTime(
      hour: 22,
      minute: 30,
    ),
    this.defaultQuietHoursEnd = const NotificationClockTime(
      hour: 8,
      minute: 0,
    ),
    this.fallbackWakeUpTime = const NotificationClockTime(
      hour: 8,
      minute: 0,
    ),
    this.morningOffsetFromWake = const Duration(hours: 1, minutes: 30),
    this.middayOffsetFromWake = const Duration(hours: 5),
    this.afternoonOffsetFromWake = const Duration(hours: 10),
  });

  final Duration horizon;
  final NotificationClockTime defaultQuietHoursStart;
  final NotificationClockTime defaultQuietHoursEnd;
  final NotificationClockTime fallbackWakeUpTime;
  final Duration morningOffsetFromWake;
  final Duration middayOffsetFromWake;
  final Duration afternoonOffsetFromWake;

  NotificationClockTime quietHoursStart(NotificationPreferences preferences) {
    return preferences.quietHoursStart ?? defaultQuietHoursStart;
  }

  NotificationClockTime quietHoursEnd(NotificationPreferences preferences) {
    return preferences.quietHoursEnd ?? defaultQuietHoursEnd;
  }

  int maxNotificationsPerDay(NotificationPreferences preferences) {
    switch (preferences.intensityPreset) {
      case NotificationIntensityPreset.light:
        return 1;
      case NotificationIntensityPreset.balanced:
        return preferences.generalNotificationCapPerDay.clamp(0, 2);
      case NotificationIntensityPreset.active:
        final total = preferences.generalNotificationCapPerDay +
            preferences.maxAdditionalContextualPerDay;
        return total.clamp(0, 4);
    }
  }

  int applyHabitReminderPressureAdjustment(
    int cap,
    int? reminderCount,
  ) {
    if (reminderCount == null) {
      return cap;
    }
    if (reminderCount >= 6) {
      return (cap - 2).clamp(0, cap);
    }
    if (reminderCount >= 3) {
      return (cap - 1).clamp(0, cap);
    }
    return cap;
  }

  List<NotificationOpportunity> buildOpportunities({
    required NotificationSelectionContext context,
    required NotificationPreferences preferences,
    required List<NotificationSelectionOpportunity> discoveredOpportunities,
  }) {
    final horizonStart = context.now;
    final horizonEnd = horizonStart.add(horizon);
    final wakeReference = fallbackWakeUpTime.onDate(horizonStart);
    final eveningTime = preferences.dailyAnchorTime;
    final preferredWindow = preferences.preferredGeneralWindow;
    _notifV2Log(
      'schedule policy input now=${horizonStart.toIso8601String()} '
      'horizonEnd=${horizonEnd.toIso8601String()} '
      'wakeReference=${wakeReference.toIso8601String()} '
      'dailyAnchor=${eveningTime.formatHhMm()} '
      'anchorSemantics=morning_midday_afternoon_use_fallbackWakeUpTime_evening_uses_dailyAnchor '
      'quietStart=${quietHoursStart(preferences).formatHhMm()} '
      'quietEnd=${quietHoursEnd(preferences).formatHhMm()} '
      'intensity=${preferences.intensityPreset.name}',
    );

    final definitions = <_OpportunityDefinition>[
      _OpportunityDefinition(
        slotId: 'morning',
        baseKind: NotificationKind.generalProgressNudge,
        targetTime: _addToClockTime(fallbackWakeUpTime, morningOffsetFromWake),
        window: const NotificationOpportunityWindow(
          start: NotificationClockTime(hour: 8, minute: 30),
          end: NotificationClockTime(hour: 10, minute: 30),
        ),
      ),
      _OpportunityDefinition(
        slotId: 'midday',
        baseKind: NotificationKind.generalProgressNudge,
        targetTime: _addToClockTime(fallbackWakeUpTime, middayOffsetFromWake),
        window: const NotificationOpportunityWindow(
          start: NotificationClockTime(hour: 12, minute: 0),
          end: NotificationClockTime(hour: 14, minute: 30),
        ),
      ),
      _OpportunityDefinition(
        slotId: 'afternoon',
        baseKind: NotificationKind.generalProgressNudge,
        targetTime: _addToClockTime(
          fallbackWakeUpTime,
          afternoonOffsetFromWake,
        ),
        window: const NotificationOpportunityWindow(
          start: NotificationClockTime(hour: 17, minute: 0),
          end: NotificationClockTime(hour: 19, minute: 0),
        ),
      ),
      _OpportunityDefinition(
        slotId: 'evening',
        baseKind: NotificationKind.generalDailyReflection,
        targetTime: eveningTime,
        window: NotificationOpportunityWindow(
          start: preferredWindow.start,
          end: preferredWindow.end,
        ),
      ),
    ];

    final byKind = <NotificationKind, NotificationSelectionOpportunity>{};
    for (final opportunity in discoveredOpportunities) {
      byKind[opportunity.kind] = opportunity;
    }

    final built = <NotificationOpportunity>[];
    for (final definition in definitions) {
      final intendedAt = _nextWithinHorizon(
        now: horizonStart,
        horizonEnd: horizonEnd,
        targetTime: definition.targetTime,
      );
      if (intendedAt == null) {
        _notifV2Log(
          'opportunity dropped slot=${definition.slotId} reason=outside_horizon '
          'target=${definition.targetTime.formatHhMm()}',
        );
        continue;
      }

      final effectiveSelection =
          byKind[definition.baseKind] ?? _fallbackSelectionOpportunity(context);
      final eligible = !_isInQuietHours(
        intendedAt,
        quietHoursStart(preferences),
        quietHoursEnd(preferences),
      );
      _notifV2Log(
        'opportunity built slot=${definition.slotId} '
        'intended=${intendedAt.toIso8601String()} '
        'target=${definition.targetTime.formatHhMm()} '
        'eligible=$eligible '
        'reason=${eligible ? "eligible" : "quiet_hours_policy_blocks_slot"} '
        'usesWakeReference=${definition.slotId != "evening"}',
      );
      built.add(
        NotificationOpportunity(
          opportunityId: definition.slotId,
          kind: effectiveSelection.kind,
          reason: effectiveSelection.reason,
          priority: effectiveSelection.priority,
          window: definition.window,
          intendedAtLocal: intendedAt,
          isEligible: eligible,
          usesWakeUpFallback:
              wakeReference == fallbackWakeUpTime.onDate(wakeReference),
          ineligibilityReason:
              eligible ? null : 'quiet_hours_policy_blocks_slot',
        ),
      );
    }

    built.sort(
      (left, right) => left.intendedAtLocal.compareTo(right.intendedAtLocal),
    );
    _notifV2Log(
      'schedule policy output count=${built.length} '
      'slots=${built.map((o) => o.opportunityId).join(",")}',
    );
    return built;
  }

  NotificationSelectionContext contextForOpportunity(
    NotificationSelectionContext base,
    NotificationOpportunity opportunity,
  ) {
    return base.copyWith(
      now: opportunity.intendedAtLocal,
      timeOfDay:
          notificationContextTimeOfDayFromDateTime(opportunity.intendedAtLocal),
      timeOfDayLabel: _formatHhMm(opportunity.intendedAtLocal),
    );
  }

  NotificationTimezoneSemantics timezoneSemanticsFor(
    NotificationOpportunity opportunity,
  ) {
    return opportunity.opportunityId == 'evening'
        ? NotificationTimezoneSemantics.localCalendarDay
        : NotificationTimezoneSemantics.localClockTime;
  }

  NotificationSelectionOpportunity _fallbackSelectionOpportunity(
    NotificationSelectionContext context,
  ) {
    return NotificationSelectionOpportunity(
      kind: NotificationKind.generalProgressNudge,
      reason: NotificationSelectionReason.safeFallback,
      priority:
          context.timeOfDay == NotificationContextTimeOfDay.morning ? 40 : 36,
      primaryCategories: const <NotificationTemplateCategory>[
        NotificationTemplateCategory.encouragement,
        NotificationTemplateCategory.gentleMotivation,
      ],
    );
  }
}

class _OpportunityDefinition {
  const _OpportunityDefinition({
    required this.slotId,
    required this.baseKind,
    required this.targetTime,
    required this.window,
  });

  final String slotId;
  final NotificationKind baseKind;
  final NotificationClockTime targetTime;
  final NotificationOpportunityWindow window;
}

NotificationClockTime _addToClockTime(
  NotificationClockTime base,
  Duration offset,
) {
  final totalMinutes = (base.hour * 60) + base.minute + offset.inMinutes;
  final normalizedMinutes =
      ((totalMinutes % (24 * 60)) + (24 * 60)) % (24 * 60);
  return NotificationClockTime(
    hour: normalizedMinutes ~/ 60,
    minute: normalizedMinutes % 60,
  );
}

DateTime? _nextWithinHorizon({
  required DateTime now,
  required DateTime horizonEnd,
  required NotificationClockTime targetTime,
}) {
  var candidate = targetTime.onDate(now);
  if (!candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  if (candidate.isAfter(horizonEnd)) {
    return null;
  }
  return candidate;
}

bool _isInQuietHours(
  DateTime value,
  NotificationClockTime start,
  NotificationClockTime end,
) {
  final minutesNow = value.hour * 60 + value.minute;
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

String _formatHhMm(DateTime value) {
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

void _notifV2Log(String message) {
  if (!kDebugMode) return;
  debugPrint('[NOTIF_V2] $message');
}
