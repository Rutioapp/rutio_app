import 'package:flutter/foundation.dart';

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
import '../domain/weekly_report_notification_copy.dart';
import 'notification_context_builder.dart';
import 'notification_schedule_policy.dart';
import 'phase1_spacing_policy.dart';
import '../../../services/phase1_notification_timing_registry.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class PersonalizedNotificationPlanBuilder {
  PersonalizedNotificationPlanBuilder({
    required NotificationPlanningContextBuilder contextBuilder,
    required NotificationTemplateCatalog templateCatalog,
    required NotificationPlatformIdProvider platformIdProvider,
    NotificationLocalizedCopyResolver? copyResolver,
    NotificationSelectionPolicy? selectionPolicy,
    NotificationSchedulePolicy? schedulePolicy,
    NotificationHabitReminderLoadProvider? habitReminderLoadProvider,
    Phase1NotificationTimingSource? phase1TimingSource,
    Phase1SpacingPolicy? phase1SpacingPolicy,
  })  : _contextBuilder = contextBuilder,
        _templateCatalog = templateCatalog,
        _platformIdProvider = platformIdProvider,
        _copyResolver = copyResolver ?? NotificationLocalizedCopyResolver(),
        _selectionPolicy =
            selectionPolicy ?? const NotificationSelectionPolicy(),
        _schedulePolicy = schedulePolicy ?? const NotificationSchedulePolicy(),
        _habitReminderLoadProvider = habitReminderLoadProvider ??
            const NullNotificationHabitReminderLoadProvider(),
        _phase1TimingSource = phase1TimingSource ??
            const SharedPreferencesPhase1NotificationTimingSource(),
        _phase1SpacingPolicy =
            phase1SpacingPolicy ?? const Phase1SpacingPolicy();

  static const int _planVersion = 1;

  final NotificationPlanningContextBuilder _contextBuilder;
  final NotificationTemplateCatalog _templateCatalog;
  final NotificationPlatformIdProvider _platformIdProvider;
  final NotificationLocalizedCopyResolver _copyResolver;
  final NotificationSelectionPolicy _selectionPolicy;
  final NotificationSchedulePolicy _schedulePolicy;
  final NotificationHabitReminderLoadProvider _habitReminderLoadProvider;
  final Phase1NotificationTimingSource _phase1TimingSource;
  final Phase1SpacingPolicy _phase1SpacingPolicy;

  Future<DesiredNotificationPlan> buildWeeklyReportOnly({
    required NotificationScope scope,
    required NotificationSchedulingCapabilities capabilities,
    required String timezoneId,
    required String locale,
    bool masterEnabled = true,
    DateTime Function()? now,
  }) async {
    final generatedAt = (now ?? DateTime.now)();
    if (!masterEnabled || !capabilities.isAuthorized) {
      return DesiredNotificationPlan.ready(
        scope: scope,
        generatedAt: generatedAt,
        horizonStart: generatedAt,
        horizonEnd: generatedAt.add(const Duration(days: 56)),
        notifications: const <DesiredNotification>[],
        opportunities: const <NotificationOpportunity>[],
        diagnostics: DesiredNotificationPlanDiagnostics(
          notes: <String>[
            'weekly_only',
            if (!masterEnabled) 'master_disabled' else 'permission_denied'
          ],
          usedWakeUpFallback: false,
          habitReminderLoadUnavailable: false,
        ),
      );
    }
    tzdata.initializeTimeZones();
    final location = tz.getLocation(timezoneId);
    final localNow = tz.TZDateTime.from(generatedAt.toUtc(), location);
    var monday = DateTime(localNow.year, localNow.month, localNow.day)
        .subtract(Duration(days: localNow.weekday - 1));
    final notifications = <DesiredNotification>[];
    for (var i = 0; i < 8; i += 1) {
      final weekStart = monday.add(Duration(days: i * 7));
      final sunday = weekStart.add(const Duration(days: 6));
      final scheduled = DateTime(sunday.year, sunday.month, sunday.day, 20);
      final occurrence = tz.TZDateTime(
          location, scheduled.year, scheduled.month, scheduled.day, 20);
      if (!occurrence.isAfter(localNow)) continue;
      final dateKey = _dateOnly(weekStart);
      final logicalId = NotificationIdNamespace.buildNotificationKey(
        family: NotificationFamily.weeklyReport,
        kind: NotificationKind.futureWeeklyReport,
        scope: scope,
        entityRef: dateKey,
        slot: 'weekly_report',
      );
      final platformId = await _platformIdProvider.getOrAllocate(
        scope,
        family: NotificationFamily.weeklyReport,
        notificationKey: logicalId,
        timezoneId: timezoneId,
      );
      final payload = NotificationPayloadV2(
        schema: NotificationIdNamespace.payloadVersion,
        family: NotificationFamily.weeklyReport,
        kind: NotificationKind.futureWeeklyReport,
        logicalId: logicalId,
        templateId: 'weekly_report.review',
        scopeHash: scope.scopeHash,
        scopeEpoch: scope.scopeEpoch,
        categoryTag: 'weeklyReport',
        route: 'weekly-report',
        dateKey: dateKey,
      );
      final title = WeeklyReportNotificationCopy.title(locale);
      final body = WeeklyReportNotificationCopy.body(locale);
      notifications.add(DesiredNotification(
        logicalNotificationId: logicalId,
        platformId: platformId,
        kind: NotificationKind.futureWeeklyReport,
        family: NotificationFamily.weeklyReport,
        templateId: 'weekly_report.review',
        renderedTitle: title,
        renderedBody: body,
        intendedLocalDateTime: scheduled,
        timezoneSemantics: NotificationTimezoneSemantics.localCalendarDay,
        timezoneIdAtPlanTime: timezoneId,
        payload: payload,
        fingerprint: '$logicalId|$timezoneId|$dateKey|$locale',
        scope: scope,
        categoryTag: 'weeklyReport',
        opportunityId: 'weekly_report_$dateKey',
        planVersion: 1,
        metadata: const <String, String>{'source': 'weekly_report_product'},
      ));
    }
    return DesiredNotificationPlan.ready(
      scope: scope,
      generatedAt: generatedAt,
      horizonStart: generatedAt,
      horizonEnd: generatedAt.add(const Duration(days: 56)),
      notifications: notifications,
      opportunities: const <NotificationOpportunity>[],
      diagnostics: DesiredNotificationPlanDiagnostics(
        notes: const <String>['weekly_only'],
        usedWakeUpFallback: false,
        habitReminderLoadUnavailable: false,
      ),
    );
  }

  Future<DesiredNotificationPlan> buildWeeklyReportDebugOnly({
    required NotificationScope scope,
    required String timezoneId,
    required String locale,
    required DateTime weekStart,
    DateTime Function()? now,
  }) async {
    final generatedAt = (now ?? DateTime.now)();
    final scheduledAt = generatedAt.add(const Duration(minutes: 1));
    final dateKey = _dateOnly(weekStart);
    final logicalId = 'rutio:v2:debug:weekly_report_test:$dateKey';
    final payload = NotificationPayloadV2(
      schema: NotificationIdNamespace.payloadVersion,
      family: NotificationFamily.weeklyReport,
      kind: NotificationKind.futureWeeklyReport,
      logicalId: logicalId,
      templateId: 'weekly_report.review',
      scopeHash: scope.scopeHash,
      scopeEpoch: scope.scopeEpoch,
      categoryTag: 'weeklyReport',
      route: 'weekly-report',
      dateKey: dateKey,
    );
    final platformId = 60000 + _stableHash(dateKey) % 1000;
    final notification = DesiredNotification(
      logicalNotificationId: logicalId,
      platformId: platformId,
      kind: NotificationKind.futureWeeklyReport,
      family: NotificationFamily.weeklyReport,
      templateId: 'weekly_report.review',
      renderedTitle: WeeklyReportNotificationCopy.title(locale),
      renderedBody: WeeklyReportNotificationCopy.body(locale),
      intendedLocalDateTime: scheduledAt,
      timezoneSemantics: NotificationTimezoneSemantics.localCalendarDay,
      timezoneIdAtPlanTime: timezoneId,
      payload: payload,
      fingerprint: '$logicalId|$timezoneId|$dateKey|$locale|$scheduledAt',
      scope: scope,
      categoryTag: 'weeklyReport',
      opportunityId: 'weekly_report_debug_$dateKey',
      planVersion: _planVersion,
      metadata: const <String, String>{'source': 'weekly_report_debug'},
    );
    return DesiredNotificationPlan.ready(
      scope: scope,
      generatedAt: generatedAt,
      horizonStart: generatedAt,
      horizonEnd: scheduledAt,
      notifications: <DesiredNotification>[notification],
      opportunities: const <NotificationOpportunity>[],
      diagnostics: DesiredNotificationPlanDiagnostics(
        notes: const <String>['weekly_debug_only'],
        usedWakeUpFallback: false,
        habitReminderLoadUnavailable: false,
      ),
    );
  }

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash & 0x7fffffff;
  }

  Future<DesiredNotificationPlan> build({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    required NotificationPreferences preferences,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    _notifV2Log(
      'plan build start trigger=${trigger.name} '
      'master=${preferences.masterEnabled} '
      'general=${preferences.generalNotificationsEnabled} '
      'intensity=${preferences.intensityPreset.name} '
      'wake=${preferences.dailyAnchorTime.formatHhMm()} '
      'permission=${schedulingCapabilities.permissionStatus.name}',
    );
    final buildResult = await _contextBuilder.buildForScope(
      scope: scope,
      trigger: trigger,
      schedulingCapabilities: schedulingCapabilities,
    );
    final now = DateTime.now().toLocal();
    final horizonEnd = now.add(_schedulePolicy.horizon);
    if (!buildResult.isSuccess) {
      _notifV2Log(
        'context build failure reason=${buildResult.failureReason?.name ?? "unknown"} '
        'quality=${buildResult.quality.name}',
      );
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
    _notifV2Log(
      'context build success quality=${buildResult.quality.name} '
      'progress=${selectionContext.progressText ?? "n/a"} '
      'pending=${selectionContext.pendingCount ?? 0} '
      'completed=${selectionContext.completedCount ?? 0} '
      'total=${selectionContext.totalCount ?? 0} '
      'streak=${selectionContext.streak?.toString() ?? "n/a"} '
      'timeOfDay=${selectionContext.timeOfDay.name} '
      'timeOfDayLabel=${selectionContext.timeOfDayLabel ?? "n/a"} '
      'wakeUpTime=${buildResult.diagnostics.hasWakeUpTime}',
    );
    if (!preferences.masterEnabled ||
        !preferences.generalNotificationsEnabled) {
      _notifV2Log('plan skipped: personalized disabled by preferences');
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
    _notifV2Log(
      'schedule policy opportunities=${opportunities.length} '
      'quietStart=${_schedulePolicy.quietHoursStart(preferences).formatHhMm()} '
      'quietEnd=${_schedulePolicy.quietHoursEnd(preferences).formatHhMm()}',
    );
    var cap = _schedulePolicy.maxNotificationsPerDay(preferences);
    cap = _schedulePolicy.applyHabitReminderPressureAdjustment(
        cap, reminderCount);
    _notifV2Log(
      'schedule policy cap=$cap reminderCount=${reminderCount?.toString() ?? "unknown"}',
    );

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
    List<Phase1NotificationScheduleIntent> phase1Schedules;
    try {
      phase1Schedules = await _phase1TimingSource.upcomingForScope(
        // Phase 1 persists by authenticated user scope; v2's epoch/install
        // suffix is intentionally not part of this cross-system lookup.
        scopeKey: desiredScope.userId,
        now: generatedAt,
        horizonEnd: planHorizonEnd,
      );
    } catch (error) {
      phase1Schedules = const <Phase1NotificationScheduleIntent>[];
      notes.add('phase1_timing_unavailable');
      _notifV2Log(
          'phase1 timing read failed; continuing without spacing: $error');
    }
    for (final opportunity in opportunities) {
      _notifV2Log(
        'opportunity slot=${opportunity.opportunityId} '
        'intended=${opportunity.intendedAtLocal.toIso8601String()} '
        'eligible=${opportunity.isEligible} '
        'reason=${opportunity.reason.name} '
        'baseKind=${opportunity.kind.name} '
        'wakeFallback=${opportunity.usesWakeUpFallback} '
        'ineligibility=${opportunity.ineligibilityReason ?? "none"}',
      );
      if (!opportunity.isEligible || planned.length >= cap) {
        suppressedOpportunityIds.add(opportunity.opportunityId);
        _notifV2Log(
          'opportunity suppressed slot=${opportunity.opportunityId} '
          'reason=${!opportunity.isEligible ? "quiet_hours" : "cap_reached"}',
        );
        continue;
      }
      if (_phase1SpacingPolicy.conflictsWithPhase1(
        personalizedAt: opportunity.intendedAtLocal,
        phase1Schedules: phase1Schedules,
      )) {
        suppressedOpportunityIds.add(opportunity.opportunityId);
        _notifV2Log(
          'opportunity suppressed slot=${opportunity.opportunityId} '
          'reason=phase1_spacing_conflict',
        );
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
        _notifV2Log(
          'selection suppressed slot=${opportunity.opportunityId} '
          'suppression=${result.suppressionReason?.name ?? "unknown"}',
        );
        continue;
      }

      final selected = result.selected!;
      _notifV2Log(
        'selection selected slot=${opportunity.opportunityId} '
        'template=${selected.template.templateId} '
        'category=${selected.category.name} '
        'kind=${selected.kind.name} '
        'reason=${selected.reason.name}',
      );
      final rendered = _copyResolver.renderForLocale(
        template: selected.template,
        context: selected.renderContext,
        localeCode: scopedContext.locale,
      );
      final milestone = selected.opportunity.journalNudgeContext ==
              JournalNudgeContext.habitMilestone
          ? scopedContext.journalMilestoneSignal
          : null;
      final contextualDateKey = milestone?.dateKey ??
          snapshot.calendarDate.toIso8601String().split('T').first;
      final logicalId = NotificationIdNamespace.buildNotificationKey(
        family: selected.kind.family,
        kind: selected.kind,
        scope: desiredScope,
        entityRef: milestone == null
            ? 'day_${snapshot.calendarDate.toIso8601String().split('T').first}'
            : 'milestone_${milestone.eventId}',
        slot: opportunity.opportunityId,
      );
      final platformId = await _platformIdProvider.getOrAllocate(
        desiredScope,
        family: selected.kind.family,
        notificationKey: logicalId,
        timezoneId: snapshot.timezoneId,
      );
      _notifV2Log(
        'desired notification logicalId=$logicalId '
        'platformId=$platformId '
        'intended=${opportunity.intendedAtLocal.toIso8601String()}',
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
        dateKey: contextualDateKey,
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

  void _notifV2Log(String message) {
    if (!kDebugMode) return;
    debugPrint('[NOTIF_V2] $message');
  }
}

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

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
