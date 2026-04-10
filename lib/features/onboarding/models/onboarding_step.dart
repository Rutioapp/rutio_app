import 'package:flutter/foundation.dart';

typedef OnboardingStepPredicate = bool Function(
  OnboardingDisplayContext context,
);

abstract final class OnboardingScreens {
  static const home = 'home';

  const OnboardingScreens._();
}

abstract final class OnboardingTargetIds {
  static const homeAddHabitFab = 'home.add_habit.fab';
  static const homeFirstHabitCheckControl = 'home_first_habit_check_control';
  static const homeFirstHabitCountControls = 'home_first_habit_count_controls';

  const OnboardingTargetIds._();
}

enum OnboardingContentType {
  message,
  cta,
}

enum OnboardingVisualType {
  avatarPlaceholder,
}

enum OnboardingStepStatus {
  unseen,
  dismissed,
  completed,
}

@immutable
class OnboardingStepProgress {
  const OnboardingStepProgress({
    this.status = OnboardingStepStatus.unseen,
    this.dismissCount = 0,
    this.lastDismissedAt,
    this.completedAt,
  });

  final OnboardingStepStatus status;
  final int dismissCount;
  final DateTime? lastDismissedAt;
  final DateTime? completedAt;

  bool get isCompleted => status == OnboardingStepStatus.completed;
  bool get isDismissed => status == OnboardingStepStatus.dismissed;
  bool get hasPersistentDismissal =>
      dismissCount > 0 || lastDismissedAt != null;

  OnboardingStepProgress markDismissed(DateTime timestamp) {
    return copyWith(
      status: OnboardingStepStatus.dismissed,
      dismissCount: dismissCount + 1,
      lastDismissedAt: timestamp,
    );
  }

  OnboardingStepProgress markCompleted(DateTime timestamp) {
    return copyWith(
      status: OnboardingStepStatus.completed,
      completedAt: timestamp,
    );
  }

  OnboardingStepProgress copyWith({
    OnboardingStepStatus? status,
    int? dismissCount,
    DateTime? lastDismissedAt,
    DateTime? completedAt,
  }) {
    return OnboardingStepProgress(
      status: status ?? this.status,
      dismissCount: dismissCount ?? this.dismissCount,
      lastDismissedAt: lastDismissedAt ?? this.lastDismissedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'dismissCount': dismissCount,
      'lastDismissedAt': lastDismissedAt?.toUtc().toIso8601String(),
      'completedAt': completedAt?.toUtc().toIso8601String(),
    };
  }

  static OnboardingStepProgress fromJson(dynamic raw) {
    if (raw is! Map) {
      return const OnboardingStepProgress();
    }

    final source = raw.cast<String, dynamic>();
    final statusName = (source['status'] ?? '').toString().trim();
    final dismissCount = source['dismissCount'] is num
        ? (source['dismissCount'] as num).toInt()
        : int.tryParse((source['dismissCount'] ?? '').toString()) ?? 0;

    return OnboardingStepProgress(
      status: OnboardingStepStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => OnboardingStepStatus.unseen,
      ),
      dismissCount: dismissCount < 0 ? 0 : dismissCount,
      lastDismissedAt: _parseTimestamp(source['lastDismissedAt']),
      completedAt: _parseTimestamp(source['completedAt']),
    );
  }

  static DateTime? _parseTimestamp(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    return DateTime.tryParse(raw)?.toUtc();
  }
}

@immutable
class OnboardingDisplayContext {
  const OnboardingDisplayContext({
    required this.screenId,
    required this.hasAnyHabits,
    this.userScopeId,
    this.availableTargetIds = const <String>{},
  });

  final String screenId;
  final bool hasAnyHabits;
  final String? userScopeId;
  final Set<String> availableTargetIds;

  String get signature {
    final normalizedScope = (userScopeId ?? '').trim().toLowerCase();
    final sortedTargets = availableTargetIds.toList()..sort();

    return [
      screenId,
      hasAnyHabits.toString(),
      normalizedScope,
      sortedTargets.join(','),
    ].join('|');
  }
}

@immutable
class OnboardingStep {
  const OnboardingStep({
    required this.id,
    required this.screenId,
    required this.message,
    required this.primaryLabel,
    this.title,
    this.dismissible = true,
    this.priority = 0,
    this.targetId,
    this.targetEntityId,
    this.contentType = OnboardingContentType.message,
    this.visualType = OnboardingVisualType.avatarPlaceholder,
    this.shouldDisplay,
  });

  final String id;
  final String screenId;
  final String? title;
  final String message;
  final String primaryLabel;
  final bool dismissible;
  final int priority;
  final String? targetId;
  final String? targetEntityId;
  final OnboardingContentType contentType;
  final OnboardingVisualType visualType;
  final OnboardingStepPredicate? shouldDisplay;

  bool isEligibleFor(OnboardingDisplayContext context) {
    if (context.screenId != screenId) {
      return false;
    }

    if (targetId != null && !context.availableTargetIds.contains(targetId)) {
      return false;
    }

    return shouldDisplay?.call(context) ?? true;
  }
}
