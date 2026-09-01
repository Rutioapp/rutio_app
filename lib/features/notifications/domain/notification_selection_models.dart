import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'notification_template_content.dart';
import 'personalized_notification_models.dart';

enum NotificationSelectionSuppressionReason {
  notificationsDisabled,
  personalizedDisabled,
  quietHours,
  invalidCatalogState,
  noEligibleTemplates,
  missingRequiredContext,
  unsupportedContext,
  frequencyLimitReached,
}

enum NotificationSelectionReason {
  comebackPriority,
  completedDayPriority,
  streakPriority,
  pendingProgressPriority,
  strongProgressPriority,
  reflectionPriority,
  morningPriority,
  consistencyPriority,
  journalPerfectDayPriority,
  journalEndOfDayPriority,
  journalHabitMilestonePriority,
  safeFallback,
}

@immutable
class NotificationSelectionContext {
  NotificationSelectionContext({
    required this.scope,
    required this.now,
    required String timezoneId,
    String? locale,
    NotificationContextTimeOfDay? timeOfDay,
    this.displayName,
    this.progressRatio,
    this.pendingCount,
    this.completedCount,
    this.totalCount,
    this.streak,
    this.inactivityDays,
    this.habitName,
    this.weekdayLabel,
    this.timeOfDayLabel,
    this.journalWrittenToday = false,
    this.journalWrittenLast24h = false,
    this.journalEntriesLast7Days = 0,
    this.journalMilestoneSignal,
    this.latestDiaryEntryAt,
    this.latestMood,
    NotificationMessageHistorySnapshot? recentMessageHistory,
  })  : timezoneId = timezoneId.trim(),
        locale = (locale ?? scope.locale).trim(),
        timeOfDay = timeOfDay ?? notificationContextTimeOfDayFromDateTime(now),
        recentMessageHistory =
            recentMessageHistory ?? NotificationMessageHistorySnapshot() {
    if (this.timezoneId.isEmpty) {
      throw ArgumentError.value(timezoneId, 'timezoneId', 'Cannot be empty.');
    }
    if (this.locale.isEmpty) {
      throw ArgumentError.value(locale, 'locale', 'Cannot be empty.');
    }
    if (progressRatio != null && (progressRatio! < 0 || progressRatio! > 1)) {
      throw ArgumentError.value(
        progressRatio,
        'progressRatio',
        'Must be between 0 and 1.',
      );
    }
  }

  factory NotificationSelectionContext.fromSnapshot(
    NotificationContextSnapshot snapshot, {
    String? displayName,
    String? habitName,
    String? weekdayLabel,
    String? timeOfDayLabel,
    String? progressLabelOverride,
  }) {
    final pendingCount = snapshot.pendingHabitsToday.length;
    final completedCount = snapshot.completedHabitsToday.length;
    final totalCount = pendingCount + completedCount;
    final inactivityDays = snapshot.lastAppOpenAt == null
        ? null
        : snapshot.calendarDate
            .difference(
              DateTime(
                snapshot.lastAppOpenAt!.year,
                snapshot.lastAppOpenAt!.month,
                snapshot.lastAppOpenAt!.day,
              ),
            )
            .inDays;

    return NotificationSelectionContext(
      scope: snapshot.scope,
      now: snapshot.now,
      timezoneId: snapshot.timezoneId,
      locale: snapshot.scope.locale,
      displayName: displayName,
      progressRatio: snapshot.progressTodayRatio?.clamp(0, 1).toDouble(),
      pendingCount: pendingCount,
      completedCount: completedCount,
      totalCount: totalCount,
      streak: snapshot.bestStreakRisk?.streakLength,
      inactivityDays: inactivityDays,
      habitName: habitName ?? snapshot.bestStreakRisk?.habitName,
      weekdayLabel: weekdayLabel,
      timeOfDayLabel: timeOfDayLabel,
      journalWrittenToday: snapshot.journalWrittenToday,
      journalWrittenLast24h: snapshot.journalWrittenLast24h,
      journalEntriesLast7Days: snapshot.journalEntriesLast7Days,
      journalMilestoneSignal: snapshot.journalMilestoneSignal,
      latestDiaryEntryAt: snapshot.latestDiaryEntryAt,
      latestMood: snapshot.latestMood,
      recentMessageHistory: snapshot.recentMessageHistory,
    ).copyWith(progressTextOverride: progressLabelOverride);
  }

  final NotificationScope scope;
  final DateTime now;
  final String timezoneId;
  final String locale;
  final NotificationContextTimeOfDay timeOfDay;
  final String? displayName;
  final double? progressRatio;
  final int? pendingCount;
  final int? completedCount;
  final int? totalCount;
  final int? streak;
  final int? inactivityDays;
  final String? habitName;
  final String? weekdayLabel;
  final String? timeOfDayLabel;
  final bool journalWrittenToday;
  final bool journalWrittenLast24h;
  final int journalEntriesLast7Days;
  final JournalMilestoneSignal? journalMilestoneSignal;
  final DateTime? latestDiaryEntryAt;
  final String? latestMood;
  final NotificationMessageHistorySnapshot recentMessageHistory;
  final String? _progressTextOverride = null;

  String? get progressText {
    if (_progressTextOverride != null &&
        _progressTextOverride!.trim().isNotEmpty) {
      return _progressTextOverride!.trim();
    }
    if (completedCount != null && totalCount != null && totalCount! > 0) {
      return '$completedCount/$totalCount';
    }
    return null;
  }

  bool get hasCompletedDay =>
      completedCount != null &&
      totalCount != null &&
      totalCount! > 0 &&
      completedCount! >= totalCount!;

  bool get hasKnownProgress => progressRatio != null;

  bool get hasInactivitySignal => inactivityDays != null;

  NotificationRenderContext toRenderContext() {
    return NotificationRenderContext(
      displayName: displayName,
      streak: streak,
      progress: progressText,
      pendingCount: pendingCount,
      completedCount: completedCount,
      totalCount: totalCount,
      habitName: habitName,
      weekday: weekdayLabel,
      timeOfDay: timeOfDayLabel,
    );
  }

  NotificationSelectionContext copyWith({
    NotificationScope? scope,
    DateTime? now,
    String? timezoneId,
    String? locale,
    NotificationContextTimeOfDay? timeOfDay,
    Object? displayName = _selectionSentinel,
    Object? progressRatio = _selectionSentinel,
    Object? pendingCount = _selectionSentinel,
    Object? completedCount = _selectionSentinel,
    Object? totalCount = _selectionSentinel,
    Object? streak = _selectionSentinel,
    Object? inactivityDays = _selectionSentinel,
    Object? habitName = _selectionSentinel,
    Object? weekdayLabel = _selectionSentinel,
    Object? timeOfDayLabel = _selectionSentinel,
    Object? journalWrittenToday = _selectionSentinel,
    Object? journalWrittenLast24h = _selectionSentinel,
    Object? journalEntriesLast7Days = _selectionSentinel,
    Object? journalMilestoneSignal = _selectionSentinel,
    Object? latestDiaryEntryAt = _selectionSentinel,
    Object? latestMood = _selectionSentinel,
    NotificationMessageHistorySnapshot? recentMessageHistory,
    Object? progressTextOverride = _selectionSentinel,
  }) {
    final next = NotificationSelectionContext(
      scope: scope ?? this.scope,
      now: now ?? this.now,
      timezoneId: timezoneId ?? this.timezoneId,
      locale: locale ?? this.locale,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      displayName: identical(displayName, _selectionSentinel)
          ? this.displayName
          : displayName as String?,
      progressRatio: identical(progressRatio, _selectionSentinel)
          ? this.progressRatio
          : progressRatio as double?,
      pendingCount: identical(pendingCount, _selectionSentinel)
          ? this.pendingCount
          : pendingCount as int?,
      completedCount: identical(completedCount, _selectionSentinel)
          ? this.completedCount
          : completedCount as int?,
      totalCount: identical(totalCount, _selectionSentinel)
          ? this.totalCount
          : totalCount as int?,
      streak:
          identical(streak, _selectionSentinel) ? this.streak : streak as int?,
      inactivityDays: identical(inactivityDays, _selectionSentinel)
          ? this.inactivityDays
          : inactivityDays as int?,
      habitName: identical(habitName, _selectionSentinel)
          ? this.habitName
          : habitName as String?,
      weekdayLabel: identical(weekdayLabel, _selectionSentinel)
          ? this.weekdayLabel
          : weekdayLabel as String?,
      timeOfDayLabel: identical(timeOfDayLabel, _selectionSentinel)
          ? this.timeOfDayLabel
          : timeOfDayLabel as String?,
      journalWrittenToday: identical(journalWrittenToday, _selectionSentinel)
          ? this.journalWrittenToday
          : journalWrittenToday as bool,
      journalWrittenLast24h: identical(
        journalWrittenLast24h,
        _selectionSentinel,
      )
          ? this.journalWrittenLast24h
          : journalWrittenLast24h as bool,
      journalEntriesLast7Days: identical(
        journalEntriesLast7Days,
        _selectionSentinel,
      )
          ? this.journalEntriesLast7Days
          : journalEntriesLast7Days as int,
      journalMilestoneSignal: identical(
        journalMilestoneSignal,
        _selectionSentinel,
      )
          ? this.journalMilestoneSignal
          : journalMilestoneSignal as JournalMilestoneSignal?,
      latestDiaryEntryAt: identical(latestDiaryEntryAt, _selectionSentinel)
          ? this.latestDiaryEntryAt
          : latestDiaryEntryAt as DateTime?,
      latestMood: identical(latestMood, _selectionSentinel)
          ? this.latestMood
          : latestMood as String?,
      recentMessageHistory: recentMessageHistory ?? this.recentMessageHistory,
    );

    return next._withProgressTextOverride(
      identical(progressTextOverride, _selectionSentinel)
          ? _progressTextOverride
          : progressTextOverride as String?,
    );
  }

  NotificationSelectionContext _withProgressTextOverride(String? value) {
    return _NotificationSelectionContextWithOverride._fromBase(this, value);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSelectionContext &&
            other.scope == scope &&
            other.now == now &&
            other.timezoneId == timezoneId &&
            other.locale == locale &&
            other.timeOfDay == timeOfDay &&
            other.displayName == displayName &&
            other.progressRatio == progressRatio &&
            other.pendingCount == pendingCount &&
            other.completedCount == completedCount &&
            other.totalCount == totalCount &&
            other.streak == streak &&
            other.inactivityDays == inactivityDays &&
            other.habitName == habitName &&
            other.weekdayLabel == weekdayLabel &&
            other.timeOfDayLabel == timeOfDayLabel &&
            other.journalWrittenToday == journalWrittenToday &&
            other.journalWrittenLast24h == journalWrittenLast24h &&
            other.journalEntriesLast7Days == journalEntriesLast7Days &&
            other.journalMilestoneSignal == journalMilestoneSignal &&
            other.latestDiaryEntryAt == latestDiaryEntryAt &&
            other.latestMood == latestMood &&
            other.recentMessageHistory == recentMessageHistory &&
            other.progressText == progressText;
  }

  @override
  int get hashCode => Object.hash(
        Object.hash(
          scope,
          now,
          timezoneId,
          locale,
          timeOfDay,
          displayName,
          progressRatio,
          pendingCount,
          completedCount,
          totalCount,
          streak,
        ),
        Object.hash(
          inactivityDays,
          habitName,
          weekdayLabel,
          timeOfDayLabel,
          journalWrittenToday,
          journalWrittenLast24h,
          journalEntriesLast7Days,
          journalMilestoneSignal,
          latestDiaryEntryAt,
          latestMood,
          recentMessageHistory,
          progressText,
        ),
      );
}

class _NotificationSelectionContextWithOverride
    extends NotificationSelectionContext {
  _NotificationSelectionContextWithOverride._fromBase(
    NotificationSelectionContext base,
    this._override,
  ) : super(
          scope: base.scope,
          now: base.now,
          timezoneId: base.timezoneId,
          locale: base.locale,
          timeOfDay: base.timeOfDay,
          displayName: base.displayName,
          progressRatio: base.progressRatio,
          pendingCount: base.pendingCount,
          completedCount: base.completedCount,
          totalCount: base.totalCount,
          streak: base.streak,
          inactivityDays: base.inactivityDays,
          habitName: base.habitName,
          weekdayLabel: base.weekdayLabel,
          timeOfDayLabel: base.timeOfDayLabel,
          journalWrittenToday: base.journalWrittenToday,
          journalWrittenLast24h: base.journalWrittenLast24h,
          journalEntriesLast7Days: base.journalEntriesLast7Days,
          journalMilestoneSignal: base.journalMilestoneSignal,
          latestDiaryEntryAt: base.latestDiaryEntryAt,
          latestMood: base.latestMood,
          recentMessageHistory: base.recentMessageHistory,
        );

  final String? _override;

  @override
  String? get progressText {
    if (_override != null && _override!.trim().isNotEmpty) {
      return _override!.trim();
    }
    return super.progressText;
  }
}

@immutable
class NotificationSelectionOpportunity {
  NotificationSelectionOpportunity({
    required this.kind,
    required this.reason,
    required this.priority,
    required List<NotificationTemplateCategory> primaryCategories,
    List<NotificationTemplateCategory> fallbackCategories =
        const <NotificationTemplateCategory>[],
    this.journalNudgeContext,
  })  : primaryCategories = UnmodifiableListView<NotificationTemplateCategory>(
          primaryCategories,
        ),
        fallbackCategories = UnmodifiableListView<NotificationTemplateCategory>(
          fallbackCategories,
        );

  final NotificationKind kind;
  final NotificationSelectionReason reason;
  final double priority;
  final List<NotificationTemplateCategory> primaryCategories;
  final List<NotificationTemplateCategory> fallbackCategories;
  final JournalNudgeContext? journalNudgeContext;

  bool matchesCategory(NotificationTemplateCategory category) {
    return primaryCategories.contains(category) ||
        fallbackCategories.contains(category);
  }

  bool isPrimaryCategory(NotificationTemplateCategory category) =>
      primaryCategories.contains(category);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationSelectionOpportunity &&
            other.kind == kind &&
            other.reason == reason &&
            other.priority == priority &&
            other.journalNudgeContext == journalNudgeContext &&
            listEquals(other.primaryCategories, primaryCategories) &&
            listEquals(other.fallbackCategories, fallbackCategories);
  }

  @override
  int get hashCode => Object.hash(
        kind,
        journalNudgeContext,
        reason,
        priority,
        Object.hashAll(primaryCategories),
        Object.hashAll(fallbackCategories),
      );
}

@immutable
class NotificationSelectionDiagnostics {
  NotificationSelectionDiagnostics({
    List<String> discoveredReasons = const <String>[],
    List<String> consideredTemplateIds = const <String>[],
    List<String> eligibleTemplateIds = const <String>[],
    List<String> blockedByMissingContext = const <String>[],
    List<String> blockedByCooldown = const <String>[],
    List<String> blockedByCategoryCooldown = const <String>[],
    List<String> blockedByFrequencyLimit = const <String>[],
    required this.usedRelaxedCategoryCooldown,
    required this.usedRelaxedTemplateCooldown,
    required this.usedEmergencyLastTemplateFallback,
  })  : discoveredReasons = UnmodifiableListView<String>(discoveredReasons),
        consideredTemplateIds =
            UnmodifiableListView<String>(consideredTemplateIds),
        eligibleTemplateIds = UnmodifiableListView<String>(eligibleTemplateIds),
        blockedByMissingContext =
            UnmodifiableListView<String>(blockedByMissingContext),
        blockedByCooldown = UnmodifiableListView<String>(blockedByCooldown),
        blockedByCategoryCooldown =
            UnmodifiableListView<String>(blockedByCategoryCooldown),
        blockedByFrequencyLimit =
            UnmodifiableListView<String>(blockedByFrequencyLimit);

  final List<String> discoveredReasons;
  final List<String> consideredTemplateIds;
  final List<String> eligibleTemplateIds;
  final List<String> blockedByMissingContext;
  final List<String> blockedByCooldown;
  final List<String> blockedByCategoryCooldown;
  final List<String> blockedByFrequencyLimit;
  final bool usedRelaxedCategoryCooldown;
  final bool usedRelaxedTemplateCooldown;
  final bool usedEmergencyLastTemplateFallback;
}

@immutable
class SelectedNotificationTemplate {
  const SelectedNotificationTemplate({
    required this.template,
    required this.kind,
    required this.category,
    required this.reason,
    required this.priorityScore,
    required this.effectiveWeight,
    required this.renderContext,
    required this.opportunity,
  });

  final NotificationTemplateDescriptor template;
  final NotificationKind kind;
  final NotificationTemplateCategory category;
  final NotificationSelectionReason reason;
  final double priorityScore;
  final double effectiveWeight;
  final NotificationRenderContext renderContext;
  final NotificationSelectionOpportunity opportunity;
}

@immutable
class NotificationSelectionResult {
  const NotificationSelectionResult._({
    this.selected,
    this.suppressionReason,
    required this.diagnostics,
  });

  factory NotificationSelectionResult.selected({
    required SelectedNotificationTemplate selected,
    required NotificationSelectionDiagnostics diagnostics,
  }) {
    return NotificationSelectionResult._(
      selected: selected,
      diagnostics: diagnostics,
    );
  }

  factory NotificationSelectionResult.suppressed({
    required NotificationSelectionSuppressionReason suppressionReason,
    required NotificationSelectionDiagnostics diagnostics,
  }) {
    return NotificationSelectionResult._(
      suppressionReason: suppressionReason,
      diagnostics: diagnostics,
    );
  }

  final SelectedNotificationTemplate? selected;
  final NotificationSelectionSuppressionReason? suppressionReason;
  final NotificationSelectionDiagnostics diagnostics;

  bool get isSelected => selected != null;
}

const Object _selectionSentinel = Object();
