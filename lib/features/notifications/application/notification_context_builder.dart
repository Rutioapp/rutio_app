import 'package:flutter/foundation.dart';
import 'package:rutio/features/achievements/domain/models/habit_streak_snapshot.dart';
import 'package:rutio/features/habits/domain/habit_day_summary.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/stores/user_state_store.dart';

enum NotificationContextBuildFailureReason {
  unauthenticatedUser,
  scopeMismatch,
  scopeChangedDuringBuild,
  missingUserState,
}

enum NotificationContextQuality {
  unavailable,
  minimal,
  partial,
  rich,
}

@immutable
class NotificationContextDiagnostics {
  const NotificationContextDiagnostics({
    required this.startedScopeKey,
    required this.completedScopeKey,
    required this.hasDisplayName,
    required this.hasReliableProgress,
    required this.hasReliableStreak,
    required this.hasReliableInactivity,
    required this.hasDiarySignal,
    required this.hasMoodSignal,
    required this.hasWakeUpTime,
    required this.missingSignals,
  });

  final String? startedScopeKey;
  final String? completedScopeKey;
  final bool hasDisplayName;
  final bool hasReliableProgress;
  final bool hasReliableStreak;
  final bool hasReliableInactivity;
  final bool hasDiarySignal;
  final bool hasMoodSignal;
  final bool hasWakeUpTime;
  final List<String> missingSignals;
}

@immutable
class NotificationContextBuildResult {
  const NotificationContextBuildResult._({
    required this.quality,
    required this.diagnostics,
    this.failureReason,
    this.snapshot,
    this.selectionContext,
  });

  factory NotificationContextBuildResult.success({
    required NotificationContextQuality quality,
    required NotificationContextDiagnostics diagnostics,
    required NotificationContextSnapshot snapshot,
    required NotificationSelectionContext selectionContext,
  }) {
    return NotificationContextBuildResult._(
      quality: quality,
      diagnostics: diagnostics,
      snapshot: snapshot,
      selectionContext: selectionContext,
    );
  }

  factory NotificationContextBuildResult.failClosed({
    required NotificationContextBuildFailureReason failureReason,
    required NotificationContextDiagnostics diagnostics,
  }) {
    return NotificationContextBuildResult._(
      quality: NotificationContextQuality.unavailable,
      diagnostics: diagnostics,
      failureReason: failureReason,
    );
  }

  final NotificationContextQuality quality;
  final NotificationContextDiagnostics diagnostics;
  final NotificationContextBuildFailureReason? failureReason;
  final NotificationContextSnapshot? snapshot;
  final NotificationSelectionContext? selectionContext;

  bool get isSuccess => snapshot != null && selectionContext != null;
}

abstract class NotificationPlanningContextBuilder {
  Future<NotificationContextBuildResult> buildForScope({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  });
}

abstract class NotificationContextStateSource {
  Map<String, dynamic>? get state;
  String? get activeLocalScopeUserId;
  int get scopeEpoch;
  String? get userId;
  List<Map<String, dynamic>> get activeHabits;
  String? get displayName;
  String? get preferredLanguageCode;
  Map<String, dynamic> get notificationMetadata;
  List<DiaryEntry> get diaryEntries;

  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  });
}

class UserStateStoreNotificationContextSource
    implements NotificationContextStateSource {
  const UserStateStoreNotificationContextSource(this.store);

  final UserStateStore store;

  @override
  String? get activeLocalScopeUserId => store.activeLocalScopeUserId;

  @override
  List<Map<String, dynamic>> get activeHabits => store.activeHabits;

  @override
  String? get displayName => store.displayName;

  @override
  List<DiaryEntry> get diaryEntries => store.diaryEntries;

  @override
  Map<String, dynamic> get notificationMetadata => store.notificationMetadata;

  @override
  String? get preferredLanguageCode => store.preferredLanguageCode;

  @override
  int get scopeEpoch => store.scopeEpoch;

  @override
  Map<String, dynamic>? get state => store.state;

  @override
  String? get userId => store.userId;

  @override
  HabitStreakSnapshot habitStreakSnapshotForHabitId(
    String habitId, {
    DateTime? today,
  }) {
    return store.habitStreakSnapshotForHabitId(habitId, today: today);
  }
}

class StoreBackedNotificationContextBuilder
    implements NotificationContextProvider, NotificationPlanningContextBuilder {
  StoreBackedNotificationContextBuilder({
    required NotificationContextStateSource store,
    required NotificationInstallIdProvider installIdProvider,
    required NotificationHistoryStore historyStore,
    NotificationClock? clock,
  })  : _store = store,
        _installIdProvider = installIdProvider,
        _historyStore = historyStore,
        _clock = clock ?? const SystemNotificationClock();

  final NotificationContextStateSource _store;
  final NotificationInstallIdProvider _installIdProvider;
  final NotificationHistoryStore _historyStore;
  final NotificationClock _clock;

  Future<NotificationContextBuildResult> build({
    required NotificationTriggerReason trigger,
    required String? expectedUserId,
    int? expectedScopeEpoch,
    String? expectedScopeKey,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) async {
    final startedScope = _readScopeState();
    if (!_matchesExpectedScope(
      scope: startedScope,
      expectedUserId: expectedUserId,
      expectedScopeEpoch: expectedScopeEpoch,
      expectedScopeKey: expectedScopeKey,
    )) {
      return NotificationContextBuildResult.failClosed(
        failureReason: (expectedUserId ?? '').trim().isEmpty
            ? NotificationContextBuildFailureReason.unauthenticatedUser
            : NotificationContextBuildFailureReason.scopeMismatch,
        diagnostics: _buildDiagnostics(
          startedScope: startedScope,
          completedScope: _readScopeState(),
        ),
      );
    }

    final root = _store.state;
    if (root == null) {
      return NotificationContextBuildResult.failClosed(
        failureReason: NotificationContextBuildFailureReason.missingUserState,
        diagnostics: _buildDiagnostics(
          startedScope: startedScope,
          completedScope: _readScopeState(),
        ),
      );
    }

    final installId = await _installIdProvider.getOrCreateInstallId();
    final completedScope = _readScopeState();
    if (!_sameScope(startedScope, completedScope)) {
      return NotificationContextBuildResult.failClosed(
        failureReason:
            NotificationContextBuildFailureReason.scopeChangedDuringBuild,
        diagnostics: _buildDiagnostics(
          startedScope: startedScope,
          completedScope: completedScope,
        ),
      );
    }

    final locale = _resolveLocale();
    final now = _clock.localNow();
    final today = DateTime(now.year, now.month, now.day);
    final scope = NotificationScope(
      userId: completedScope.userId!,
      scopeEpoch: completedScope.scopeEpoch,
      installId: installId,
      locale: locale,
    );
    final history =
        await _historyStore.load(scope) ?? NotificationMessageHistorySnapshot();

    final afterHistoryScope = _readScopeState();
    if (!_sameScope(startedScope, afterHistoryScope)) {
      return NotificationContextBuildResult.failClosed(
        failureReason:
            NotificationContextBuildFailureReason.scopeChangedDuringBuild,
        diagnostics: _buildDiagnostics(
          startedScope: startedScope,
          completedScope: afterHistoryScope,
        ),
      );
    }

    final currentRoot = _store.state;
    if (currentRoot == null) {
      return NotificationContextBuildResult.failClosed(
        failureReason: NotificationContextBuildFailureReason.missingUserState,
        diagnostics: _buildDiagnostics(
          startedScope: startedScope,
          completedScope: afterHistoryScope,
        ),
      );
    }

    final userState = _map(currentRoot['userState']);
    final summary = buildHabitDaySummary(
      activeHabits: _store.activeHabits,
      history: _map(userState['history']),
      selectedDay: today,
      today: today,
    );
    final displayName = _normalizedText(_store.displayName);
    final bestStreakRisk = _bestStreakRisk(summary.pendingHabits, today: today);
    final progressRatio = summary.totalCount == 0
        ? null
        : summary.completedCount / summary.totalCount;
    final lastAppOpenAt =
        _parseDateTime(_store.notificationMetadata['lastAppOpenAt']);
    final latestDiaryEntryAt = _latestDiaryEntryAt(_store.diaryEntries);

    final snapshot = NotificationContextSnapshot(
      scope: scope,
      now: now,
      timezoneId: _clock.timezoneId(),
      calendarDate: today,
      activeHabitsSummary: summary.visibleHabits
          .map((habit) => _habitSummaryLabel(habit))
          .whereType<String>()
          .toList(growable: false),
      pendingHabitsToday: summary.pendingHabits
          .map((habit) => _habitId(habit))
          .whereType<String>()
          .toList(growable: false),
      completedHabitsToday: summary.completedHabits
          .map((habit) => _habitId(habit))
          .whereType<String>()
          .toList(growable: false),
      bestStreakRisk: bestStreakRisk,
      lastAppOpenAt: lastAppOpenAt,
      latestDiaryEntryAt: latestDiaryEntryAt,
      progressTodayRatio: progressRatio,
      recentMessageHistory: history,
      schedulingCapabilities: schedulingCapabilities,
    );

    final selectionContext = NotificationSelectionContext(
      scope: scope,
      now: now,
      timezoneId: snapshot.timezoneId,
      locale: locale,
      displayName: displayName,
      progressRatio: progressRatio,
      pendingCount: summary.pendingCount,
      completedCount: summary.completedCount,
      totalCount: summary.totalCount,
      streak: bestStreakRisk?.streakLength,
      inactivityDays: _inactivityDays(lastAppOpenAt, today),
      habitName: bestStreakRisk?.habitName,
      weekdayLabel: _weekdayLabel(today, locale),
      timeOfDayLabel: _formatHhMm(now),
      latestDiaryEntryAt: latestDiaryEntryAt,
      recentMessageHistory: history,
    );

    final diagnostics = _buildDiagnostics(
      startedScope: startedScope,
      completedScope: afterHistoryScope,
      displayName: displayName,
      progressRatio: progressRatio,
      streak: bestStreakRisk?.streakLength,
      lastAppOpenAt: lastAppOpenAt,
      latestDiaryEntryAt: latestDiaryEntryAt,
    );

    return NotificationContextBuildResult.success(
      quality: _resolveQuality(diagnostics),
      diagnostics: diagnostics,
      snapshot: snapshot,
      selectionContext: selectionContext,
    );
  }

  @override
  Future<NotificationContextBuildResult> buildForScope({
    required NotificationScope scope,
    required NotificationTriggerReason trigger,
    NotificationSchedulingCapabilities schedulingCapabilities =
        NotificationSchedulingCapabilities.unsupported,
  }) {
    return build(
      trigger: trigger,
      expectedUserId: scope.userId,
      expectedScopeEpoch: scope.scopeEpoch,
      schedulingCapabilities: schedulingCapabilities,
    );
  }

  @override
  Future<NotificationContextSnapshot> buildContext(
    NotificationScope scope, {
    required NotificationTriggerReason trigger,
  }) async {
    final result = await build(
      trigger: trigger,
      expectedUserId: scope.userId,
      expectedScopeEpoch: scope.scopeEpoch,
      schedulingCapabilities: NotificationSchedulingCapabilities.unsupported,
    );
    if (!result.isSuccess) {
      throw StateError(
        'Notification context build failed: ${result.failureReason}',
      );
    }
    return result.snapshot!;
  }

  _CurrentScopeState _readScopeState() {
    final activeScopeUserId = _normalizedText(_store.activeLocalScopeUserId);
    final storeUserId = _normalizedText(_store.userId);
    return _CurrentScopeState(
      userId: activeScopeUserId ?? storeUserId,
      activeScopeUserId: activeScopeUserId,
      storeUserId: storeUserId,
      scopeEpoch: _store.scopeEpoch,
    );
  }

  bool _matchesExpectedScope({
    required _CurrentScopeState scope,
    required String? expectedUserId,
    int? expectedScopeEpoch,
    String? expectedScopeKey,
  }) {
    final normalizedExpectedUserId = _normalizedText(expectedUserId);
    if (normalizedExpectedUserId == null || scope.userId == null) {
      return false;
    }
    if (scope.userId != normalizedExpectedUserId ||
        scope.activeScopeUserId != normalizedExpectedUserId ||
        scope.storeUserId != normalizedExpectedUserId) {
      return false;
    }
    if (expectedScopeEpoch != null && scope.scopeEpoch != expectedScopeEpoch) {
      return false;
    }
    if (expectedScopeKey != null &&
        expectedScopeKey.trim().isNotEmpty &&
        scope.scopeKey != expectedScopeKey.trim()) {
      return false;
    }
    return true;
  }

  bool _sameScope(_CurrentScopeState left, _CurrentScopeState right) {
    return left.userId == right.userId &&
        left.activeScopeUserId == right.activeScopeUserId &&
        left.storeUserId == right.storeUserId &&
        left.scopeEpoch == right.scopeEpoch;
  }

  String _resolveLocale() {
    final preferred = _normalizedText(_store.preferredLanguageCode);
    if (preferred != null) {
      return preferred;
    }
    return 'es';
  }

  NotificationStreakRisk? _bestStreakRisk(
    List<Map<String, dynamic>> pendingHabits, {
    required DateTime today,
  }) {
    NotificationStreakRisk? best;
    for (final habit in pendingHabits) {
      final habitId = _habitId(habit);
      if (habitId == null) continue;
      final snapshot = _store.habitStreakSnapshotForHabitId(
        habitId,
        today: today,
      );
      final candidate = NotificationStreakRisk(
        habitId: habitId,
        habitName: _habitSummaryLabel(habit) ?? habitId,
        streakLength: snapshot.currentStreak,
      );
      if (best == null || candidate.streakLength > best.streakLength) {
        best = candidate;
      }
    }
    return best;
  }

  NotificationContextDiagnostics _buildDiagnostics({
    required _CurrentScopeState startedScope,
    required _CurrentScopeState completedScope,
    String? displayName,
    double? progressRatio,
    int? streak,
    DateTime? lastAppOpenAt,
    DateTime? latestDiaryEntryAt,
  }) {
    final missingSignals = <String>[];
    final hasDisplayName = _normalizedText(displayName) != null;
    final hasReliableProgress = progressRatio != null;
    final hasReliableStreak = streak != null;
    final hasReliableInactivity = lastAppOpenAt != null;
    final hasDiarySignal = latestDiaryEntryAt != null;
    const hasMoodSignal = false;
    const hasWakeUpTime = false;

    if (!hasDisplayName) missingSignals.add('displayName');
    if (!hasReliableProgress) missingSignals.add('progress');
    if (!hasReliableStreak) missingSignals.add('streak');
    if (!hasReliableInactivity) missingSignals.add('inactivity');
    if (!hasDiarySignal) missingSignals.add('diary');
    if (!hasMoodSignal) missingSignals.add('mood');
    if (!hasWakeUpTime) missingSignals.add('wakeUpTime');

    return NotificationContextDiagnostics(
      startedScopeKey: startedScope.scopeKey,
      completedScopeKey: completedScope.scopeKey,
      hasDisplayName: hasDisplayName,
      hasReliableProgress: hasReliableProgress,
      hasReliableStreak: hasReliableStreak,
      hasReliableInactivity: hasReliableInactivity,
      hasDiarySignal: hasDiarySignal,
      hasMoodSignal: hasMoodSignal,
      hasWakeUpTime: hasWakeUpTime,
      missingSignals: List<String>.unmodifiable(missingSignals),
    );
  }

  NotificationContextQuality _resolveQuality(
    NotificationContextDiagnostics diagnostics,
  ) {
    final signalCount = <bool>[
      diagnostics.hasDisplayName,
      diagnostics.hasReliableProgress,
      diagnostics.hasReliableStreak,
      diagnostics.hasReliableInactivity,
      diagnostics.hasDiarySignal,
      diagnostics.hasMoodSignal,
      diagnostics.hasWakeUpTime,
    ].where((value) => value).length;
    if (signalCount >= 5) {
      return NotificationContextQuality.rich;
    }
    if (signalCount >= 2) {
      return NotificationContextQuality.partial;
    }
    return NotificationContextQuality.minimal;
  }
}

@immutable
class _CurrentScopeState {
  const _CurrentScopeState({
    required this.userId,
    required this.activeScopeUserId,
    required this.storeUserId,
    required this.scopeEpoch,
  });

  final String? userId;
  final String? activeScopeUserId;
  final String? storeUserId;
  final int scopeEpoch;

  String? get scopeKey {
    final currentUserId = userId;
    final scopeUserId = activeScopeUserId;
    if (currentUserId == null || scopeUserId == null) {
      return null;
    }
    return '$currentUserId|$scopeUserId|$scopeEpoch';
  }
}

String? _habitId(Map<String, dynamic> habit) {
  final value = _normalizedText(habit['id']);
  return value;
}

String? _habitSummaryLabel(Map<String, dynamic> habit) {
  return _normalizedText(habit['name']) ?? _normalizedText(habit['title']);
}

String? _normalizedText(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

DateTime? _parseDateTime(Object? value) {
  final normalized = _normalizedText(value);
  if (normalized == null) {
    return null;
  }
  return DateTime.tryParse(normalized)?.toLocal();
}

DateTime? _latestDiaryEntryAt(List<DiaryEntry> entries) {
  if (entries.isEmpty) {
    return null;
  }
  final latest = entries.first;
  return DateTime.fromMillisecondsSinceEpoch(latest.createdAt).toLocal();
}

int? _inactivityDays(DateTime? lastAppOpenAt, DateTime today) {
  if (lastAppOpenAt == null) {
    return null;
  }
  final lastOpenDate = DateTime(
    lastAppOpenAt.year,
    lastAppOpenAt.month,
    lastAppOpenAt.day,
  );
  return today.difference(lastOpenDate).inDays;
}

String _formatHhMm(DateTime value) {
  final hh = value.hour.toString().padLeft(2, '0');
  final mm = value.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

String _weekdayLabel(DateTime day, String locale) {
  const es = <int, String>{
    DateTime.monday: 'lunes',
    DateTime.tuesday: 'martes',
    DateTime.wednesday: 'miercoles',
    DateTime.thursday: 'jueves',
    DateTime.friday: 'viernes',
    DateTime.saturday: 'sabado',
    DateTime.sunday: 'domingo',
  };
  const en = <int, String>{
    DateTime.monday: 'monday',
    DateTime.tuesday: 'tuesday',
    DateTime.wednesday: 'wednesday',
    DateTime.thursday: 'thursday',
    DateTime.friday: 'friday',
    DateTime.saturday: 'saturday',
    DateTime.sunday: 'sunday',
  };
  final normalized = locale.toLowerCase();
  final labels = normalized.startsWith('en') ? en : es;
  return labels[day.weekday] ?? es[day.weekday] ?? 'lunes';
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}
