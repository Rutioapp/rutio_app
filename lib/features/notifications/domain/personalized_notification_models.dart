import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'notification_template_content.dart';

enum NotificationFamily {
  habitReminder,
  personalizedGeneral,
  celebration,
  diary,
  weeklyReport,
  system,
}

enum NotificationKind {
  habitReminder,
  generalDayClosure,
  generalStreakRisk,
  generalDailyReflection,
  generalInactivity,
  generalProgressNudge,
  generalDiaryPrompt,
  celebrationStreak,
  futureWeeklyReport,
}

extension NotificationKindX on NotificationKind {
  NotificationFamily get family {
    switch (this) {
      case NotificationKind.habitReminder:
        return NotificationFamily.habitReminder;
      case NotificationKind.generalDayClosure:
      case NotificationKind.generalStreakRisk:
      case NotificationKind.generalDailyReflection:
      case NotificationKind.generalInactivity:
      case NotificationKind.generalProgressNudge:
      case NotificationKind.generalDiaryPrompt:
        return NotificationFamily.personalizedGeneral;
      case NotificationKind.celebrationStreak:
        return NotificationFamily.celebration;
      case NotificationKind.futureWeeklyReport:
        return NotificationFamily.weeklyReport;
    }
  }

  String get wireName {
    switch (this) {
      case NotificationKind.habitReminder:
        return 'habitReminder';
      case NotificationKind.generalDayClosure:
        return 'generalDayClosure';
      case NotificationKind.generalStreakRisk:
        return 'generalStreakRisk';
      case NotificationKind.generalDailyReflection:
        return 'generalDailyReflection';
      case NotificationKind.generalInactivity:
        return 'generalInactivity';
      case NotificationKind.generalProgressNudge:
        return 'generalProgressNudge';
      case NotificationKind.generalDiaryPrompt:
        return 'generalDiaryPrompt';
      case NotificationKind.celebrationStreak:
        return 'celebrationStreak';
      case NotificationKind.futureWeeklyReport:
        return 'futureWeeklyReport';
    }
  }
}

NotificationKind notificationKindFromWireName(String wireName) {
  final normalized = wireName.trim();
  for (final value in NotificationKind.values) {
    if (value.wireName == normalized) {
      return value;
    }
  }
  throw ArgumentError.value(
    wireName,
    'wireName',
    'Unsupported NotificationKind.',
  );
}

enum NotificationTriggerReason {
  appBootstrap,
  postLogin,
  preferencesChanged,
  habitCreated,
  habitUpdated,
  habitDeleted,
  habitArchived,
  habitReminderToggleChanged,
  dayBoundary,
  timezoneChanged,
  appResumed,
  logout,
  manualRecovery,
}

enum NotificationIntensityPreset {
  light,
  balanced,
  active,
}

enum WakeTimeSource {
  userConfigured,
  derivedFromProfile,
  derivedFromUsage,
  fallbackDefault,
  unknown,
}

enum NotificationScheduleType {
  exactDateTime,
  dailyClockTime,
}

enum NotificationSuppressionReason {
  permissionDenied,
  masterDisabled,
  familyDisabled,
  cooldownActive,
  duplicateTemplate,
  dailyCapReached,
  iosBudgetReached,
  noEligibleTemplate,
  noRelevantContext,
  scopeMismatch,
  outsideAllowedWindow,
  logoutCleanup,
}

enum NotificationSystemPermissionStatus {
  notDetermined,
  denied,
  restricted,
  permanentlyDenied,
  provisional,
  authorized,
  unknown,
}

@immutable
class NotificationSchedulingCapabilities {
  const NotificationSchedulingCapabilities({
    required this.permissionStatus,
    required this.canScheduleNewEntries,
    required this.canCancelExistingEntries,
  });

  final NotificationSystemPermissionStatus permissionStatus;
  final bool canScheduleNewEntries;
  final bool canCancelExistingEntries;

  static const unsupported = NotificationSchedulingCapabilities(
    permissionStatus: NotificationSystemPermissionStatus.unknown,
    canScheduleNewEntries: false,
    canCancelExistingEntries: false,
  );

  bool get isAuthorized =>
      permissionStatus == NotificationSystemPermissionStatus.authorized ||
      permissionStatus == NotificationSystemPermissionStatus.provisional;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSchedulingCapabilities &&
            other.permissionStatus == permissionStatus &&
            other.canScheduleNewEntries == canScheduleNewEntries &&
            other.canCancelExistingEntries == canCancelExistingEntries;
  }

  @override
  int get hashCode => Object.hash(
        permissionStatus,
        canScheduleNewEntries,
        canCancelExistingEntries,
      );
}

@immutable
class NotificationClockTime {
  const NotificationClockTime({
    required this.hour,
    required this.minute,
  })  : assert(hour >= 0 && hour <= 23, 'hour must be between 0 and 23'),
        assert(minute >= 0 && minute <= 59, 'minute must be between 0 and 59');

  factory NotificationClockTime.parse(
    String raw, {
    NotificationClockTime fallback = const NotificationClockTime(
      hour: 20,
      minute: 30,
    ),
  }) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;
    final parts = trimmed.split(':');
    if (parts.length != 2) return fallback;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return fallback;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return fallback;
    }
    return NotificationClockTime(hour: hour, minute: minute);
  }

  final int hour;
  final int minute;

  DateTime onDate(DateTime date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String formatHhMm() {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationClockTime &&
            other.hour == hour &&
            other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);
}

@immutable
class NotificationTimeWindow {
  const NotificationTimeWindow({
    required this.start,
    required this.end,
  });

  final NotificationClockTime start;
  final NotificationClockTime end;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationTimeWindow &&
            other.start == start &&
            other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

@immutable
class NotificationScope {
  NotificationScope({
    required String userId,
    required this.scopeEpoch,
    required String installId,
    required String locale,
  })  : userId = _requireNotBlank(userId, 'userId'),
        installId = _requireNotBlank(installId, 'installId'),
        locale = _requireNotBlank(locale, 'locale');

  final String userId;
  final int scopeEpoch;
  final String installId;
  final String locale;

  String get scopeKey => '$userId|$scopeEpoch|$installId';

  String get scopeHash => _compactStableToken(scopeKey);

  NotificationScope copyWith({
    String? userId,
    int? scopeEpoch,
    String? installId,
    String? locale,
  }) {
    return NotificationScope(
      userId: userId ?? this.userId,
      scopeEpoch: scopeEpoch ?? this.scopeEpoch,
      installId: installId ?? this.installId,
      locale: locale ?? this.locale,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationScope &&
            other.userId == userId &&
            other.scopeEpoch == scopeEpoch &&
            other.installId == installId &&
            other.locale == locale;
  }

  @override
  int get hashCode => Object.hash(userId, scopeEpoch, installId, locale);
}

@immutable
class NotificationPreferences {
  const NotificationPreferences({
    required this.masterEnabled,
    required this.habitRemindersEnabled,
    required this.generalNotificationsEnabled,
    required this.intensityPreset,
    required this.generalNotificationCapPerDay,
    required this.maxAdditionalContextualPerDay,
    required this.preferredGeneralWindow,
    required this.dayClosureTime,
    required this.dailyAnchorTime,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.useWakeTimeAsAnchor,
    required this.wakeTimeSource,
    required this.fallbackAnchorPolicy,
  })  : assert(generalNotificationCapPerDay >= 0),
        assert(maxAdditionalContextualPerDay >= 0);

  factory NotificationPreferences.defaults() {
    return NotificationPreferences(
      masterEnabled: true,
      habitRemindersEnabled: true,
      generalNotificationsEnabled: true,
      intensityPreset: NotificationIntensityPreset.balanced,
      generalNotificationCapPerDay: 2,
      maxAdditionalContextualPerDay: 1,
      preferredGeneralWindow: const NotificationTimeWindow(
        start: NotificationClockTime(hour: 18, minute: 0),
        end: NotificationClockTime(hour: 21, minute: 30),
      ),
      dayClosureTime: const NotificationClockTime(hour: 21, minute: 0),
      dailyAnchorTime: const NotificationClockTime(hour: 20, minute: 30),
      quietHoursStart: null,
      quietHoursEnd: null,
      useWakeTimeAsAnchor: false,
      wakeTimeSource: WakeTimeSource.fallbackDefault,
      fallbackAnchorPolicy: 'fixed_20_30_local',
    );
  }

  final bool masterEnabled;
  final bool habitRemindersEnabled;
  final bool generalNotificationsEnabled;
  final NotificationIntensityPreset intensityPreset;
  final int generalNotificationCapPerDay;
  final int maxAdditionalContextualPerDay;
  final NotificationTimeWindow preferredGeneralWindow;
  final NotificationClockTime dayClosureTime;
  final NotificationClockTime dailyAnchorTime;
  final NotificationClockTime? quietHoursStart;
  final NotificationClockTime? quietHoursEnd;
  final bool useWakeTimeAsAnchor;
  final WakeTimeSource wakeTimeSource;
  final String fallbackAnchorPolicy;

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? habitRemindersEnabled,
    bool? generalNotificationsEnabled,
    NotificationIntensityPreset? intensityPreset,
    int? generalNotificationCapPerDay,
    int? maxAdditionalContextualPerDay,
    NotificationTimeWindow? preferredGeneralWindow,
    NotificationClockTime? dayClosureTime,
    NotificationClockTime? dailyAnchorTime,
    Object? quietHoursStart = _sentinel,
    Object? quietHoursEnd = _sentinel,
    bool? useWakeTimeAsAnchor,
    WakeTimeSource? wakeTimeSource,
    String? fallbackAnchorPolicy,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      habitRemindersEnabled:
          habitRemindersEnabled ?? this.habitRemindersEnabled,
      generalNotificationsEnabled:
          generalNotificationsEnabled ?? this.generalNotificationsEnabled,
      intensityPreset: intensityPreset ?? this.intensityPreset,
      generalNotificationCapPerDay:
          generalNotificationCapPerDay ?? this.generalNotificationCapPerDay,
      maxAdditionalContextualPerDay:
          maxAdditionalContextualPerDay ?? this.maxAdditionalContextualPerDay,
      preferredGeneralWindow:
          preferredGeneralWindow ?? this.preferredGeneralWindow,
      dayClosureTime: dayClosureTime ?? this.dayClosureTime,
      dailyAnchorTime: dailyAnchorTime ?? this.dailyAnchorTime,
      quietHoursStart: identical(quietHoursStart, _sentinel)
          ? this.quietHoursStart
          : quietHoursStart as NotificationClockTime?,
      quietHoursEnd: identical(quietHoursEnd, _sentinel)
          ? this.quietHoursEnd
          : quietHoursEnd as NotificationClockTime?,
      useWakeTimeAsAnchor: useWakeTimeAsAnchor ?? this.useWakeTimeAsAnchor,
      wakeTimeSource: wakeTimeSource ?? this.wakeTimeSource,
      fallbackAnchorPolicy: fallbackAnchorPolicy ?? this.fallbackAnchorPolicy,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationPreferences &&
            other.masterEnabled == masterEnabled &&
            other.habitRemindersEnabled == habitRemindersEnabled &&
            other.generalNotificationsEnabled == generalNotificationsEnabled &&
            other.intensityPreset == intensityPreset &&
            other.generalNotificationCapPerDay ==
                generalNotificationCapPerDay &&
            other.maxAdditionalContextualPerDay ==
                maxAdditionalContextualPerDay &&
            other.preferredGeneralWindow == preferredGeneralWindow &&
            other.dayClosureTime == dayClosureTime &&
            other.dailyAnchorTime == dailyAnchorTime &&
            other.quietHoursStart == quietHoursStart &&
            other.quietHoursEnd == quietHoursEnd &&
            other.useWakeTimeAsAnchor == useWakeTimeAsAnchor &&
            other.wakeTimeSource == wakeTimeSource &&
            other.fallbackAnchorPolicy == fallbackAnchorPolicy;
  }

  @override
  int get hashCode => Object.hash(
        masterEnabled,
        habitRemindersEnabled,
        generalNotificationsEnabled,
        intensityPreset,
        generalNotificationCapPerDay,
        maxAdditionalContextualPerDay,
        preferredGeneralWindow,
        dayClosureTime,
        dailyAnchorTime,
        quietHoursStart,
        quietHoursEnd,
        useWakeTimeAsAnchor,
        wakeTimeSource,
        fallbackAnchorPolicy,
      );
}

@immutable
class NotificationDeliveryRecord {
  const NotificationDeliveryRecord({
    required this.notificationKey,
    required this.userId,
    required this.templateId,
    required this.kind,
    required this.scheduledAt,
    this.openedAt,
    this.deliveredObservedAt,
    this.dismissedObservedAt,
    this.suppressionReason,
  });

  final String notificationKey;
  final String userId;
  final String templateId;
  final NotificationKind kind;
  final DateTime scheduledAt;
  final DateTime? openedAt;
  final DateTime? deliveredObservedAt;
  final DateTime? dismissedObservedAt;
  final NotificationSuppressionReason? suppressionReason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationDeliveryRecord &&
            other.notificationKey == notificationKey &&
            other.userId == userId &&
            other.templateId == templateId &&
            other.kind == kind &&
            other.scheduledAt == scheduledAt &&
            other.openedAt == openedAt &&
            other.deliveredObservedAt == deliveredObservedAt &&
            other.dismissedObservedAt == dismissedObservedAt &&
            other.suppressionReason == suppressionReason;
  }

  @override
  int get hashCode => Object.hash(
        notificationKey,
        userId,
        templateId,
        kind,
        scheduledAt,
        openedAt,
        deliveredObservedAt,
        dismissedObservedAt,
        suppressionReason,
      );
}

@immutable
class NotificationMessageHistorySnapshot {
  NotificationMessageHistorySnapshot({
    List<NotificationDeliveryRecord> recentDeliveries =
        const <NotificationDeliveryRecord>[],
    Map<String, DateTime> lastSelectedAtByTemplateId =
        const <String, DateTime>{},
    Map<String, DateTime> lastSelectedAtByKind = const <String, DateTime>{},
    Map<String, DateTime> lastSelectedAtByCategoryTag =
        const <String, DateTime>{},
  })  : recentDeliveries =
            UnmodifiableListView<NotificationDeliveryRecord>(recentDeliveries),
        lastSelectedAtByTemplateId =
            UnmodifiableMapView<String, DateTime>(lastSelectedAtByTemplateId),
        lastSelectedAtByKind =
            UnmodifiableMapView<String, DateTime>(lastSelectedAtByKind),
        lastSelectedAtByCategoryTag =
            UnmodifiableMapView<String, DateTime>(lastSelectedAtByCategoryTag);

  final List<NotificationDeliveryRecord> recentDeliveries;
  final Map<String, DateTime> lastSelectedAtByTemplateId;
  final Map<String, DateTime> lastSelectedAtByKind;
  final Map<String, DateTime> lastSelectedAtByCategoryTag;

  NotificationMessageHistorySnapshot copyWith({
    List<NotificationDeliveryRecord>? recentDeliveries,
    Map<String, DateTime>? lastSelectedAtByTemplateId,
    Map<String, DateTime>? lastSelectedAtByKind,
    Map<String, DateTime>? lastSelectedAtByCategoryTag,
  }) {
    return NotificationMessageHistorySnapshot(
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      lastSelectedAtByTemplateId:
          lastSelectedAtByTemplateId ?? this.lastSelectedAtByTemplateId,
      lastSelectedAtByKind: lastSelectedAtByKind ?? this.lastSelectedAtByKind,
      lastSelectedAtByCategoryTag:
          lastSelectedAtByCategoryTag ?? this.lastSelectedAtByCategoryTag,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationMessageHistorySnapshot &&
            listEquals(other.recentDeliveries, recentDeliveries) &&
            mapEquals(
              other.lastSelectedAtByTemplateId,
              lastSelectedAtByTemplateId,
            ) &&
            mapEquals(other.lastSelectedAtByKind, lastSelectedAtByKind) &&
            mapEquals(
              other.lastSelectedAtByCategoryTag,
              lastSelectedAtByCategoryTag,
            );
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(recentDeliveries),
        _hashMap(lastSelectedAtByTemplateId),
        _hashMap(lastSelectedAtByKind),
        _hashMap(lastSelectedAtByCategoryTag),
      );
}

@immutable
class NotificationContextSnapshot {
  NotificationContextSnapshot({
    required this.scope,
    required this.now,
    required String timezoneId,
    required DateTime calendarDate,
    List<String> activeHabitsSummary = const <String>[],
    List<String> pendingHabitsToday = const <String>[],
    List<String> completedHabitsToday = const <String>[],
    this.bestStreakRisk,
    List<int> streakMilestonesTriggered = const <int>[],
    this.lastAppOpenAt,
    this.recentAppOpenCount7d = 0,
    this.latestDiaryEntryAt,
    this.latestMood,
    this.progressTodayRatio = 0,
    NotificationMessageHistorySnapshot? recentMessageHistory,
    required this.schedulingCapabilities,
  })  : timezoneId = _requireNotBlank(timezoneId, 'timezoneId'),
        calendarDate =
            DateTime(calendarDate.year, calendarDate.month, calendarDate.day),
        recentMessageHistory =
            recentMessageHistory ?? NotificationMessageHistorySnapshot(),
        activeHabitsSummary = UnmodifiableListView<String>(activeHabitsSummary),
        pendingHabitsToday = UnmodifiableListView<String>(pendingHabitsToday),
        completedHabitsToday =
            UnmodifiableListView<String>(completedHabitsToday),
        streakMilestonesTriggered =
            UnmodifiableListView<int>(streakMilestonesTriggered);

  final NotificationScope scope;
  final DateTime now;
  final String timezoneId;
  final DateTime calendarDate;
  final List<String> activeHabitsSummary;
  final List<String> pendingHabitsToday;
  final List<String> completedHabitsToday;
  final NotificationStreakRisk? bestStreakRisk;
  final List<int> streakMilestonesTriggered;
  final DateTime? lastAppOpenAt;
  final int recentAppOpenCount7d;
  final DateTime? latestDiaryEntryAt;
  final String? latestMood;
  final double progressTodayRatio;
  final NotificationMessageHistorySnapshot recentMessageHistory;
  final NotificationSchedulingCapabilities schedulingCapabilities;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationContextSnapshot &&
            other.scope == scope &&
            other.now == now &&
            other.timezoneId == timezoneId &&
            other.calendarDate == calendarDate &&
            listEquals(other.activeHabitsSummary, activeHabitsSummary) &&
            listEquals(other.pendingHabitsToday, pendingHabitsToday) &&
            listEquals(other.completedHabitsToday, completedHabitsToday) &&
            other.bestStreakRisk == bestStreakRisk &&
            listEquals(
              other.streakMilestonesTriggered,
              streakMilestonesTriggered,
            ) &&
            other.lastAppOpenAt == lastAppOpenAt &&
            other.recentAppOpenCount7d == recentAppOpenCount7d &&
            other.latestDiaryEntryAt == latestDiaryEntryAt &&
            other.latestMood == latestMood &&
            other.progressTodayRatio == progressTodayRatio &&
            other.recentMessageHistory == recentMessageHistory &&
            other.schedulingCapabilities == schedulingCapabilities;
  }

  @override
  int get hashCode => Object.hash(
        scope,
        now,
        timezoneId,
        calendarDate,
        Object.hashAll(activeHabitsSummary),
        Object.hashAll(pendingHabitsToday),
        Object.hashAll(completedHabitsToday),
        bestStreakRisk,
        Object.hashAll(streakMilestonesTriggered),
        lastAppOpenAt,
        recentAppOpenCount7d,
        latestDiaryEntryAt,
        latestMood,
        progressTodayRatio,
        recentMessageHistory,
        schedulingCapabilities,
      );
}

@immutable
class NotificationStreakRisk {
  const NotificationStreakRisk({
    required this.habitId,
    required this.habitName,
    required this.streakLength,
  });

  final String habitId;
  final String habitName;
  final int streakLength;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationStreakRisk &&
            other.habitId == habitId &&
            other.habitName == habitName &&
            other.streakLength == streakLength;
  }

  @override
  int get hashCode => Object.hash(habitId, habitName, streakLength);
}

@immutable
class NotificationCandidate {
  NotificationCandidate({
    required this.candidateId,
    required this.kind,
    required this.priorityScore,
    required this.baseWeight,
    required this.reasonCode,
    required this.schedulePolicy,
    Map<String, String> copyContext = const <String, String>{},
    required this.dedupeKey,
    required this.cooldownKey,
    Map<String, String> originSignals = const <String, String>{},
  })  : family = kind.family,
        copyContext = UnmodifiableMapView<String, String>(copyContext),
        originSignals = UnmodifiableMapView<String, String>(originSignals);

  final String candidateId;
  final NotificationKind kind;
  final NotificationFamily family;
  final double priorityScore;
  final int baseWeight;
  final String reasonCode;
  final NotificationScheduleSpec schedulePolicy;
  final Map<String, String> copyContext;
  final String dedupeKey;
  final String cooldownKey;
  final Map<String, String> originSignals;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationCandidate &&
            other.candidateId == candidateId &&
            other.kind == kind &&
            other.family == family &&
            other.priorityScore == priorityScore &&
            other.baseWeight == baseWeight &&
            other.reasonCode == reasonCode &&
            other.schedulePolicy == schedulePolicy &&
            mapEquals(other.copyContext, copyContext) &&
            other.dedupeKey == dedupeKey &&
            other.cooldownKey == cooldownKey &&
            mapEquals(other.originSignals, originSignals);
  }

  @override
  int get hashCode => Object.hash(
        candidateId,
        kind,
        family,
        priorityScore,
        baseWeight,
        reasonCode,
        schedulePolicy,
        _hashMap(copyContext),
        dedupeKey,
        cooldownKey,
        _hashMap(originSignals),
      );
}

@immutable
class NotificationTemplateDescriptor {
  NotificationTemplateDescriptor({
    required this.templateId,
    required this.templateKey,
    required this.localeNamespace,
    required this.category,
    List<String> variantTags = const <String>[],
    List<NotificationTemplateVariable> declaredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationTemplateVariable> requiredVariables =
        const <NotificationTemplateVariable>[],
    required this.weight,
    required this.cooldown,
    required this.maxUsesPer7d,
    required List<NotificationKind> compatibleKinds,
  })  : variantTags = UnmodifiableListView<String>(variantTags),
        declaredVariables = UnmodifiableListView<NotificationTemplateVariable>(
          declaredVariables,
        ),
        requiredVariables = UnmodifiableListView<NotificationTemplateVariable>(
          requiredVariables,
        ),
        compatibleKinds =
            UnmodifiableListView<NotificationKind>(compatibleKinds);

  final String templateId;
  final String templateKey;
  final String localeNamespace;
  final NotificationTemplateCategory category;
  final List<String> variantTags;
  final List<NotificationTemplateVariable> declaredVariables;
  final List<NotificationTemplateVariable> requiredVariables;
  final int weight;
  final Duration cooldown;
  final int maxUsesPer7d;
  final List<NotificationKind> compatibleKinds;

  bool supports(NotificationKind kind) => compatibleKinds.contains(kind);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationTemplateDescriptor &&
            other.templateId == templateId &&
            other.templateKey == templateKey &&
            other.localeNamespace == localeNamespace &&
            other.category == category &&
            listEquals(other.variantTags, variantTags) &&
            listEquals(other.declaredVariables, declaredVariables) &&
            listEquals(other.requiredVariables, requiredVariables) &&
            other.weight == weight &&
            other.cooldown == cooldown &&
            other.maxUsesPer7d == maxUsesPer7d &&
            listEquals(other.compatibleKinds, compatibleKinds);
  }

  @override
  int get hashCode => Object.hash(
        templateId,
        templateKey,
        localeNamespace,
        category,
        Object.hashAll(variantTags),
        Object.hashAll(declaredVariables),
        Object.hashAll(requiredVariables),
        weight,
        cooldown,
        maxUsesPer7d,
        Object.hashAll(compatibleKinds),
      );
}

@immutable
class NotificationScheduleSpec {
  const NotificationScheduleSpec({
    required this.scheduleType,
    this.scheduledLocalDateTime,
    this.dailyTime,
    this.timeWindow,
    required this.repeats,
    required this.anchorSource,
    required this.timezoneIdAtPlanTime,
  })  : assert(
          scheduleType != NotificationScheduleType.exactDateTime ||
              scheduledLocalDateTime != null,
          'exactDateTime schedules require scheduledLocalDateTime',
        ),
        assert(
          scheduleType != NotificationScheduleType.dailyClockTime ||
              dailyTime != null,
          'dailyClockTime schedules require dailyTime',
        );

  final NotificationScheduleType scheduleType;
  final DateTime? scheduledLocalDateTime;
  final NotificationClockTime? dailyTime;
  final NotificationTimeWindow? timeWindow;
  final bool repeats;
  final String anchorSource;
  final String timezoneIdAtPlanTime;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationScheduleSpec &&
            other.scheduleType == scheduleType &&
            other.scheduledLocalDateTime == scheduledLocalDateTime &&
            other.dailyTime == dailyTime &&
            other.timeWindow == timeWindow &&
            other.repeats == repeats &&
            other.anchorSource == anchorSource &&
            other.timezoneIdAtPlanTime == timezoneIdAtPlanTime;
  }

  @override
  int get hashCode => Object.hash(
        scheduleType,
        scheduledLocalDateTime,
        dailyTime,
        timeWindow,
        repeats,
        anchorSource,
        timezoneIdAtPlanTime,
      );
}

@immutable
class NotificationPlanEntry {
  const NotificationPlanEntry({
    required this.notificationKey,
    required this.platformId,
    required this.family,
    required this.kind,
    required this.entityRef,
    required this.payloadVersion,
    required this.payload,
    required this.templateId,
    required this.renderedTitle,
    required this.renderedBody,
    required this.scheduleSpec,
    required this.planVersion,
    required this.sourceFingerprint,
  });

  final String notificationKey;
  final int platformId;
  final NotificationFamily family;
  final NotificationKind kind;
  final String entityRef;
  final int payloadVersion;
  final String payload;
  final String templateId;
  final String renderedTitle;
  final String renderedBody;
  final NotificationScheduleSpec scheduleSpec;
  final int planVersion;
  final String sourceFingerprint;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationPlanEntry &&
            other.notificationKey == notificationKey &&
            other.platformId == platformId &&
            other.family == family &&
            other.kind == kind &&
            other.entityRef == entityRef &&
            other.payloadVersion == payloadVersion &&
            other.payload == payload &&
            other.templateId == templateId &&
            other.renderedTitle == renderedTitle &&
            other.renderedBody == renderedBody &&
            other.scheduleSpec == scheduleSpec &&
            other.planVersion == planVersion &&
            other.sourceFingerprint == sourceFingerprint;
  }

  @override
  int get hashCode => Object.hash(
        notificationKey,
        platformId,
        family,
        kind,
        entityRef,
        payloadVersion,
        payload,
        templateId,
        renderedTitle,
        renderedBody,
        scheduleSpec,
        planVersion,
        sourceFingerprint,
      );
}

@immutable
class NotificationPlan {
  NotificationPlan({
    required this.scope,
    required this.generatedAt,
    required this.windowStart,
    required this.windowEnd,
    required List<NotificationPlanEntry> entries,
    required List<NotificationSuppressedCandidate> suppressedCandidates,
    required this.planVersion,
  })  : entries = UnmodifiableListView<NotificationPlanEntry>(entries),
        suppressedCandidates =
            UnmodifiableListView<NotificationSuppressedCandidate>(
          suppressedCandidates,
        );

  final NotificationScope scope;
  final DateTime generatedAt;
  final DateTime windowStart;
  final DateTime windowEnd;
  final List<NotificationPlanEntry> entries;
  final List<NotificationSuppressedCandidate> suppressedCandidates;
  final int planVersion;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationPlan &&
            other.scope == scope &&
            other.generatedAt == generatedAt &&
            other.windowStart == windowStart &&
            other.windowEnd == windowEnd &&
            listEquals(other.entries, entries) &&
            listEquals(other.suppressedCandidates, suppressedCandidates) &&
            other.planVersion == planVersion;
  }

  @override
  int get hashCode => Object.hash(
        scope,
        generatedAt,
        windowStart,
        windowEnd,
        Object.hashAll(entries),
        Object.hashAll(suppressedCandidates),
        planVersion,
      );
}

@immutable
class NotificationSuppressedCandidate {
  const NotificationSuppressedCandidate({
    required this.candidateId,
    required this.kind,
    required this.reason,
  });

  final String candidateId;
  final NotificationKind kind;
  final NotificationSuppressionReason reason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSuppressedCandidate &&
            other.candidateId == candidateId &&
            other.kind == kind &&
            other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(candidateId, kind, reason);
}

@immutable
class NotificationManifestEntry {
  const NotificationManifestEntry({
    required this.notificationKey,
    required this.platformId,
    required this.family,
    required this.kind,
    required this.payload,
    required this.templateId,
    required this.scheduledAt,
    required this.planVersion,
    required this.sourceFingerprint,
  });

  final String notificationKey;
  final int platformId;
  final NotificationFamily family;
  final NotificationKind kind;
  final String payload;
  final String templateId;
  final DateTime scheduledAt;
  final int planVersion;
  final String sourceFingerprint;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationManifestEntry &&
            other.notificationKey == notificationKey &&
            other.platformId == platformId &&
            other.family == family &&
            other.kind == kind &&
            other.payload == payload &&
            other.templateId == templateId &&
            other.scheduledAt == scheduledAt &&
            other.planVersion == planVersion &&
            other.sourceFingerprint == sourceFingerprint;
  }

  @override
  int get hashCode => Object.hash(
        notificationKey,
        platformId,
        family,
        kind,
        payload,
        templateId,
        scheduledAt,
        planVersion,
        sourceFingerprint,
      );
}

@immutable
class NotificationScheduleManifest {
  NotificationScheduleManifest({
    required this.scope,
    required this.scopeEpochAtPlanTime,
    required String timezoneId,
    required this.lastReconciledAt,
    required DateTime lastReconciledDate,
    required List<NotificationManifestEntry> entries,
    required Map<String, int> platformIdIndex,
  })  : timezoneId = _requireNotBlank(timezoneId, 'timezoneId'),
        lastReconciledDate = DateTime(
          lastReconciledDate.year,
          lastReconciledDate.month,
          lastReconciledDate.day,
        ),
        entries = UnmodifiableListView<NotificationManifestEntry>(entries),
        platformIdIndex = UnmodifiableMapView<String, int>(platformIdIndex);

  final NotificationScope scope;
  final int scopeEpochAtPlanTime;
  final String timezoneId;
  final DateTime lastReconciledAt;
  final DateTime lastReconciledDate;
  final List<NotificationManifestEntry> entries;
  final Map<String, int> platformIdIndex;

  NotificationScheduleManifest copyWith({
    NotificationScope? scope,
    int? scopeEpochAtPlanTime,
    String? timezoneId,
    DateTime? lastReconciledAt,
    DateTime? lastReconciledDate,
    List<NotificationManifestEntry>? entries,
    Map<String, int>? platformIdIndex,
  }) {
    return NotificationScheduleManifest(
      scope: scope ?? this.scope,
      scopeEpochAtPlanTime: scopeEpochAtPlanTime ?? this.scopeEpochAtPlanTime,
      timezoneId: timezoneId ?? this.timezoneId,
      lastReconciledAt: lastReconciledAt ?? this.lastReconciledAt,
      lastReconciledDate: lastReconciledDate ?? this.lastReconciledDate,
      entries: entries ?? this.entries,
      platformIdIndex: platformIdIndex ?? this.platformIdIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationScheduleManifest &&
            other.scope == scope &&
            other.scopeEpochAtPlanTime == scopeEpochAtPlanTime &&
            other.timezoneId == timezoneId &&
            other.lastReconciledAt == lastReconciledAt &&
            other.lastReconciledDate == lastReconciledDate &&
            listEquals(other.entries, entries) &&
            mapEquals(other.platformIdIndex, platformIdIndex);
  }

  @override
  int get hashCode => Object.hash(
        scope,
        scopeEpochAtPlanTime,
        timezoneId,
        lastReconciledAt,
        lastReconciledDate,
        Object.hashAll(entries),
        _hashMap(platformIdIndex),
      );
}

String _requireNotBlank(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name cannot be empty.');
  }
  return normalized;
}

String _compactStableToken(String raw) {
  const int offset = 0x811c9dc5;
  const int prime = 0x01000193;
  var hash = offset;
  for (final codeUnit in raw.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * prime) & 0x7fffffff;
  }
  return hash.toRadixString(36).padLeft(6, '0');
}

int _hashMap<K, V>(Map<K, V> map) {
  final entries = map.entries.toList()
    ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));
  return Object.hashAll(
    entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

const Object _sentinel = Object();
