import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'notification_payload.dart';
import 'notification_selection_models.dart';
import 'personalized_notification_models.dart';

enum NotificationTimezoneSemantics {
  localClockTime,
  localCalendarDay,
}

enum DesiredNotificationPlanStatus {
  ready,
  empty,
  personalizedDisabled,
  contextFailure,
  notBuilt,
}

@immutable
class NotificationOpportunityWindow {
  const NotificationOpportunityWindow({
    required this.start,
    required this.end,
  });

  final NotificationClockTime start;
  final NotificationClockTime end;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationOpportunityWindow &&
            other.start == start &&
            other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class NotificationOpportunity {
  const NotificationOpportunity({
    required this.opportunityId,
    required this.kind,
    required this.reason,
    required this.priority,
    required this.window,
    required this.intendedAtLocal,
    required this.isEligible,
    required this.usesWakeUpFallback,
    this.selectedLogicalNotificationId,
    this.ineligibilityReason,
  });

  final String opportunityId;
  final NotificationKind kind;
  final NotificationSelectionReason reason;
  final double priority;
  final NotificationOpportunityWindow window;
  final DateTime intendedAtLocal;
  final bool isEligible;
  final bool usesWakeUpFallback;
  final String? selectedLogicalNotificationId;
  final String? ineligibilityReason;

  NotificationOpportunity copyWith({
    String? selectedLogicalNotificationId,
    bool? isEligible,
    String? ineligibilityReason,
  }) {
    return NotificationOpportunity(
      opportunityId: opportunityId,
      kind: kind,
      reason: reason,
      priority: priority,
      window: window,
      intendedAtLocal: intendedAtLocal,
      isEligible: isEligible ?? this.isEligible,
      usesWakeUpFallback: usesWakeUpFallback,
      selectedLogicalNotificationId:
          selectedLogicalNotificationId ?? this.selectedLogicalNotificationId,
      ineligibilityReason: ineligibilityReason ?? this.ineligibilityReason,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationOpportunity &&
            other.opportunityId == opportunityId &&
            other.kind == kind &&
            other.reason == reason &&
            other.priority == priority &&
            other.window == window &&
            other.intendedAtLocal == intendedAtLocal &&
            other.isEligible == isEligible &&
            other.usesWakeUpFallback == usesWakeUpFallback &&
            other.selectedLogicalNotificationId ==
                selectedLogicalNotificationId &&
            other.ineligibilityReason == ineligibilityReason;
  }

  @override
  int get hashCode => Object.hash(
        opportunityId,
        kind,
        reason,
        priority,
        window,
        intendedAtLocal,
        isEligible,
        usesWakeUpFallback,
        selectedLogicalNotificationId,
        ineligibilityReason,
      );
}

@immutable
class DesiredNotification {
  DesiredNotification({
    required this.logicalNotificationId,
    required this.platformId,
    required this.kind,
    required this.family,
    required this.templateId,
    required this.renderedTitle,
    required this.renderedBody,
    required this.intendedLocalDateTime,
    required this.timezoneSemantics,
    required this.timezoneIdAtPlanTime,
    required this.payload,
    required this.fingerprint,
    required this.scope,
    required this.categoryTag,
    required this.opportunityId,
    required this.planVersion,
    required Map<String, String> metadata,
  }) : metadata = Map<String, String>.unmodifiable(metadata);

  final String logicalNotificationId;
  final int platformId;
  final NotificationKind kind;
  final NotificationFamily family;
  final String templateId;
  final String renderedTitle;
  final String renderedBody;
  final DateTime intendedLocalDateTime;
  final NotificationTimezoneSemantics timezoneSemantics;
  final String timezoneIdAtPlanTime;
  final NotificationPayloadV2 payload;
  final String fingerprint;
  final NotificationScope scope;
  final String categoryTag;
  final String opportunityId;
  final int planVersion;
  final Map<String, String> metadata;

  DesiredNotification copyWith({
    String? logicalNotificationId,
    int? platformId,
    NotificationKind? kind,
    NotificationFamily? family,
    String? templateId,
    String? renderedTitle,
    String? renderedBody,
    DateTime? intendedLocalDateTime,
    NotificationTimezoneSemantics? timezoneSemantics,
    String? timezoneIdAtPlanTime,
    NotificationPayloadV2? payload,
    String? fingerprint,
    NotificationScope? scope,
    String? categoryTag,
    String? opportunityId,
    int? planVersion,
    Map<String, String>? metadata,
  }) {
    return DesiredNotification(
      logicalNotificationId:
          logicalNotificationId ?? this.logicalNotificationId,
      platformId: platformId ?? this.platformId,
      kind: kind ?? this.kind,
      family: family ?? this.family,
      templateId: templateId ?? this.templateId,
      renderedTitle: renderedTitle ?? this.renderedTitle,
      renderedBody: renderedBody ?? this.renderedBody,
      intendedLocalDateTime:
          intendedLocalDateTime ?? this.intendedLocalDateTime,
      timezoneSemantics: timezoneSemantics ?? this.timezoneSemantics,
      timezoneIdAtPlanTime: timezoneIdAtPlanTime ?? this.timezoneIdAtPlanTime,
      payload: payload ?? this.payload,
      fingerprint: fingerprint ?? this.fingerprint,
      scope: scope ?? this.scope,
      categoryTag: categoryTag ?? this.categoryTag,
      opportunityId: opportunityId ?? this.opportunityId,
      planVersion: planVersion ?? this.planVersion,
      metadata: metadata ?? this.metadata,
    );
  }
}

@immutable
class DesiredNotificationPlanDiagnostics {
  DesiredNotificationPlanDiagnostics({
    List<String> notes = const <String>[],
    List<String> selectedTemplateIds = const <String>[],
    List<String> suppressedOpportunityIds = const <String>[],
    required this.usedWakeUpFallback,
    required this.habitReminderLoadUnavailable,
    this.detectedHabitReminderCount,
  })  : notes = UnmodifiableListView<String>(notes),
        selectedTemplateIds = UnmodifiableListView<String>(selectedTemplateIds),
        suppressedOpportunityIds =
            UnmodifiableListView<String>(suppressedOpportunityIds);

  final List<String> notes;
  final List<String> selectedTemplateIds;
  final List<String> suppressedOpportunityIds;
  final bool usedWakeUpFallback;
  final bool habitReminderLoadUnavailable;
  final int? detectedHabitReminderCount;
}

@immutable
class DesiredNotificationPlan {
  DesiredNotificationPlan._({
    required this.status,
    required this.scope,
    required this.generatedAt,
    required this.horizonStart,
    required this.horizonEnd,
    required List<DesiredNotification> notifications,
    required List<NotificationOpportunity> opportunities,
    required this.diagnostics,
    this.contextFailureReason,
  })  : notifications =
            UnmodifiableListView<DesiredNotification>(notifications),
        opportunities = UnmodifiableListView<NotificationOpportunity>(
          opportunities,
        );

  factory DesiredNotificationPlan.ready({
    required NotificationScope scope,
    required DateTime generatedAt,
    required DateTime horizonStart,
    required DateTime horizonEnd,
    required List<DesiredNotification> notifications,
    required List<NotificationOpportunity> opportunities,
    required DesiredNotificationPlanDiagnostics diagnostics,
  }) {
    return DesiredNotificationPlan._(
      status: notifications.isEmpty
          ? DesiredNotificationPlanStatus.empty
          : DesiredNotificationPlanStatus.ready,
      scope: scope,
      generatedAt: generatedAt,
      horizonStart: horizonStart,
      horizonEnd: horizonEnd,
      notifications: notifications,
      opportunities: opportunities,
      diagnostics: diagnostics,
    );
  }

  factory DesiredNotificationPlan.personalizedDisabled({
    required NotificationScope scope,
    required DateTime generatedAt,
    required DateTime horizonStart,
    required DateTime horizonEnd,
    required DesiredNotificationPlanDiagnostics diagnostics,
  }) {
    return DesiredNotificationPlan._(
      status: DesiredNotificationPlanStatus.personalizedDisabled,
      scope: scope,
      generatedAt: generatedAt,
      horizonStart: horizonStart,
      horizonEnd: horizonEnd,
      notifications: const <DesiredNotification>[],
      opportunities: const <NotificationOpportunity>[],
      diagnostics: diagnostics,
    );
  }

  factory DesiredNotificationPlan.contextFailure({
    required DateTime generatedAt,
    required DateTime horizonStart,
    required DateTime horizonEnd,
    required DesiredNotificationPlanDiagnostics diagnostics,
    required String reason,
  }) {
    return DesiredNotificationPlan._(
      status: DesiredNotificationPlanStatus.contextFailure,
      scope: null,
      generatedAt: generatedAt,
      horizonStart: horizonStart,
      horizonEnd: horizonEnd,
      notifications: const <DesiredNotification>[],
      opportunities: const <NotificationOpportunity>[],
      diagnostics: diagnostics,
      contextFailureReason: reason,
    );
  }

  final DesiredNotificationPlanStatus status;
  final NotificationScope? scope;
  final DateTime generatedAt;
  final DateTime horizonStart;
  final DateTime horizonEnd;
  final List<DesiredNotification> notifications;
  final List<NotificationOpportunity> opportunities;
  final DesiredNotificationPlanDiagnostics diagnostics;
  final String? contextFailureReason;

  bool get isExecutable =>
      status != DesiredNotificationPlanStatus.contextFailure;
}
