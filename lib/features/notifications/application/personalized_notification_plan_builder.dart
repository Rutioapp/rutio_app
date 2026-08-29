import '../domain/desired_notification.dart';
import '../domain/notification_message_catalog.dart';
import '../domain/notification_payload.dart';
import '../domain/notification_random_source.dart';
import '../domain/notification_selection_engine.dart';
import '../domain/notification_selection_policy.dart';
import '../domain/notification_template_content.dart';
import '../domain/personalized_notification_ids.dart';
import '../domain/personalized_notification_models.dart';
import '../domain/personalized_notification_ports.dart';
import 'notification_context_builder.dart';
import 'notification_schedule_policy.dart';

class PersonalizedNotificationPlanBuilder {
  PersonalizedNotificationPlanBuilder({
    required NotificationPlanningContextBuilder contextBuilder,
    required NotificationTemplateCatalog templateCatalog,
    required NotificationPlatformIdProvider platformIdProvider,
    NotificationLocalizedCopyResolver? copyResolver,
    NotificationSelectionPolicy? selectionPolicy,
    NotificationSchedulePolicy? schedulePolicy,
    NotificationHabitReminderLoadProvider? habitReminderLoadProvider,
  })  : _contextBuilder = contextBuilder,
        _templateCatalog = templateCatalog,
        _platformIdProvider = platformIdProvider,
        _copyResolver = copyResolver ?? NotificationLocalizedCopyResolver(),
        _selectionPolicy =
            selectionPolicy ?? const NotificationSelectionPolicy(),
        _schedulePolicy = schedulePolicy ?? const NotificationSchedulePolicy(),
        _habitReminderLoadProvider = habitReminderLoadProvider ??
            const NullNotificationHabitReminderLoadProvider();

  static const int _planVersion = 1;

  final NotificationPlanningContextBuilder _contextBuilder;
  final NotificationTemplateCatalog _templateCatalog;
  final NotificationPlatformIdProvider _platformIdProvider;
  final NotificationLocalizedCopyResolver _copyResolver;
  final NotificationSelectionPolicy _selectionPolicy;
  final NotificationSchedulePolicy _schedulePolicy;
  final NotificationHabitReminderLoadProvider _habitReminderLoadProvider;

  Future<DesiredNotificationPlan> build({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    required NotificationPreferences preferences,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    final buildResult = await _contextBuilder.buildForScope(
      scope: scope,
      trigger: trigger,
      schedulingCapabilities: schedulingCapabilities,
    );
    final now = DateTime.now().toLocal();
    final horizonEnd = now.add(_schedulePolicy.horizon);
    if (!buildResult.isSuccess) {
      return DesiredNotificationPlan.contextFailure(
        generatedAt: now,
        horizonStart: now,
        horizonEnd: horizonEnd,
        diagnostics: DesiredNotificationPlanDiagnostics(
          notes: <String>[
            'context_build_failed:${buildResult.failureReason}',
          ],
          usedWakeUpFallback: true,
          habitReminderLoadUnavailable: true,
        ),
        reason: '${buildResult.failureReason}',
      );
    }

    final snapshot = buildResult.snapshot!;
    final selectionContext = buildResult.selectionContext!;
    final generatedAt = snapshot.now;
    final desiredScope = snapshot.scope;
    final planHorizonEnd = generatedAt.add(_schedulePolicy.horizon);
    if (!preferences.masterEnabled ||
        !preferences.generalNotificationsEnabled) {
      return DesiredNotificationPlan.personalizedDisabled(
        scope: desiredScope,
        generatedAt: generatedAt,
        horizonStart: generatedAt,
        horizonEnd: planHorizonEnd,
        diagnostics: DesiredNotificationPlanDiagnostics(
          notes: const <String>['personalized_disabled'],
          usedWakeUpFallback: true,
          habitReminderLoadUnavailable: true,
        ),
      );
    }

    final reminderCount = await _habitReminderLoadProvider.countForDay(
      desiredScope,
      day: snapshot.calendarDate,
    );
    final discovered = _selectionPolicy.discoverOpportunities(
      selectionContext,
      preferences,
    );
    var opportunities = _schedulePolicy.buildOpportunities(
      context: selectionContext,
      preferences: preferences,
      discoveredOpportunities: discovered,
    );
    var cap = _schedulePolicy.maxNotificationsPerDay(preferences);
    cap = _schedulePolicy.applyHabitReminderPressureAdjustment(
        cap, reminderCount);

    final selectedTemplateIds = <String>[];
    final suppressedOpportunityIds = <String>[];
    final notes = <String>[];
    if (reminderCount == null) {
      notes.add('habit_reminder_load_unavailable');
    } else {
      notes.add('habit_reminder_count=$reminderCount');
    }

    final planned = <DesiredNotification>[];
    var rollingHistory = selectionContext.recentMessageHistory;
    for (final opportunity in opportunities) {
      if (!opportunity.isEligible || planned.length >= cap) {
        suppressedOpportunityIds.add(opportunity.opportunityId);
        continue;
      }
      final scopedContext = _schedulePolicy.contextForOpportunity(
        selectionContext.copyWith(recentMessageHistory: rollingHistory),
        opportunity,
      );
      final engine = NotificationSelectionEngine(
        templateCatalog: _templateCatalog,
        randomSource: SeededNotificationRandomSource(
          _stableSeed(
            '${desiredScope.scopeKey}|${opportunity.opportunityId}|'
            '${opportunity.intendedAtLocal.toIso8601String()}',
          ),
        ),
        policy: _selectionPolicy,
      );
      final result = await engine.selectTemplate(
        context: scopedContext,
        preferences: preferences,
      );
      if (!result.isSelected) {
        suppressedOpportunityIds.add(opportunity.opportunityId);
        continue;
      }

      final selected = result.selected!;
      final rendered = _copyResolver.renderForLocale(
        template: selected.template,
        context: selected.renderContext,
        localeCode: scopedContext.locale,
      );
      final logicalId = NotificationIdNamespace.buildNotificationKey(
        family: selected.kind.family,
        kind: selected.kind,
        scope: desiredScope,
        entityRef:
            'day_${snapshot.calendarDate.toIso8601String().split('T').first}',
        slot: opportunity.opportunityId,
      );
      final platformId = await _platformIdProvider.getOrAllocate(
        desiredScope,
        family: selected.kind.family,
        notificationKey: logicalId,
        timezoneId: snapshot.timezoneId,
      );
      final payload = NotificationPayloadV2(
        schema: NotificationIdNamespace.payloadVersion,
        family: selected.kind.family,
        kind: selected.kind,
        logicalId: logicalId,
        templateId: selected.template.templateId,
        scopeHash: desiredScope.scopeHash,
        scopeEpoch: desiredScope.scopeEpoch,
        categoryTag: selected.category.wireName,
      );
      final fingerprint = _fingerprintFor(
        logicalId: logicalId,
        templateId: selected.template.templateId,
        intendedAtLocal: opportunity.intendedAtLocal,
        title: rendered.title,
        body: rendered.body,
        payload: payload,
        scope: desiredScope,
      );
      planned.add(
        DesiredNotification(
          logicalNotificationId: logicalId,
          platformId: platformId,
          kind: selected.kind,
          family: selected.kind.family,
          templateId: selected.template.templateId,
          renderedTitle: rendered.title,
          renderedBody: rendered.body,
          intendedLocalDateTime: opportunity.intendedAtLocal,
          timezoneSemantics: _schedulePolicy.timezoneSemanticsFor(opportunity),
          timezoneIdAtPlanTime: snapshot.timezoneId,
          payload: payload,
          fingerprint: fingerprint,
          scope: desiredScope,
          categoryTag: selected.category.wireName,
          opportunityId: opportunity.opportunityId,
          planVersion: _planVersion,
          metadata: <String, String>{
            'reason': selected.reason.name,
            'locale': rendered.locale,
          },
        ),
      );
      selectedTemplateIds.add(selected.template.templateId);
      rollingHistory = _appendSyntheticHistory(
        rollingHistory,
        planned.last,
      );
    }

    opportunities = opportunities.map((opportunity) {
      final match = planned.where(
        (notification) =>
            notification.opportunityId == opportunity.opportunityId,
      );
      if (match.isEmpty) {
        return opportunity;
      }
      return opportunity.copyWith(
        selectedLogicalNotificationId: match.first.logicalNotificationId,
      );
    }).toList(growable: false);

    return DesiredNotificationPlan.ready(
      scope: desiredScope,
      generatedAt: generatedAt,
      horizonStart: generatedAt,
      horizonEnd: planHorizonEnd,
      notifications: planned,
      opportunities: opportunities,
      diagnostics: DesiredNotificationPlanDiagnostics(
        notes: notes,
        selectedTemplateIds: selectedTemplateIds,
        suppressedOpportunityIds: suppressedOpportunityIds,
        usedWakeUpFallback: true,
        habitReminderLoadUnavailable: reminderCount == null,
        detectedHabitReminderCount: reminderCount,
      ),
    );
  }
}

NotificationMessageHistorySnapshot _appendSyntheticHistory(
  NotificationMessageHistorySnapshot history,
  DesiredNotification notification,
) {
  final record = NotificationDeliveryRecord(
    notificationKey: notification.logicalNotificationId,
    userId: notification.scope.userId,
    templateId: notification.templateId,
    kind: notification.kind,
    scheduledAt: notification.intendedLocalDateTime,
    categoryTag: notification.categoryTag,
  );
  final deliveries = <NotificationDeliveryRecord>[
    record,
    ...history.recentDeliveries,
  ];
  final byTemplate =
      Map<String, DateTime>.from(history.lastSelectedAtByTemplateId)
        ..[notification.templateId] = notification.intendedLocalDateTime;
  final byKind = Map<String, DateTime>.from(history.lastSelectedAtByKind)
    ..[notification.kind.wireName] = notification.intendedLocalDateTime;
  final byCategory =
      Map<String, DateTime>.from(history.lastSelectedAtByCategoryTag)
        ..[notification.categoryTag] = notification.intendedLocalDateTime;
  return NotificationMessageHistorySnapshot(
    recentDeliveries: deliveries,
    lastSelectedAtByTemplateId: byTemplate,
    lastSelectedAtByKind: byKind,
    lastSelectedAtByCategoryTag: byCategory,
  );
}

String _fingerprintFor({
  required String logicalId,
  required String templateId,
  required DateTime intendedAtLocal,
  required String title,
  required String body,
  required NotificationPayloadV2 payload,
  required NotificationScope scope,
}) {
  final source = <String>[
    logicalId,
    templateId,
    intendedAtLocal.toIso8601String(),
    title,
    body,
    payload.encode(),
    scope.scopeKey,
  ].join('|');
  return _stableSeed(source).toRadixString(16).padLeft(8, '0');
}

int _stableSeed(String value) {
  const int offset = 0x811c9dc5;
  const int prime = 0x01000193;
  var hash = offset;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * prime) & 0x7fffffff;
  }
  return hash & 0x7fffffff;
}
