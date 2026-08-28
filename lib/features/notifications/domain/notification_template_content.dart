import 'dart:collection';

import 'package:flutter/foundation.dart';

enum NotificationTemplateCategory {
  morning,
  gentleMotivation,
  pendingProgress,
  strongProgress,
  completedDay,
  streak,
  comeback,
  reflection,
  consistency,
  encouragement,
}

extension NotificationTemplateCategoryX on NotificationTemplateCategory {
  String get wireName {
    switch (this) {
      case NotificationTemplateCategory.morning:
        return 'morning';
      case NotificationTemplateCategory.gentleMotivation:
        return 'gentleMotivation';
      case NotificationTemplateCategory.pendingProgress:
        return 'pendingProgress';
      case NotificationTemplateCategory.strongProgress:
        return 'strongProgress';
      case NotificationTemplateCategory.completedDay:
        return 'completedDay';
      case NotificationTemplateCategory.streak:
        return 'streak';
      case NotificationTemplateCategory.comeback:
        return 'comeback';
      case NotificationTemplateCategory.reflection:
        return 'reflection';
      case NotificationTemplateCategory.consistency:
        return 'consistency';
      case NotificationTemplateCategory.encouragement:
        return 'encouragement';
    }
  }
}

NotificationTemplateCategory notificationTemplateCategoryFromWireName(
  String wireName,
) {
  final normalized = wireName.trim();
  for (final value in NotificationTemplateCategory.values) {
    if (value.wireName == normalized) {
      return value;
    }
  }
  throw ArgumentError.value(
    wireName,
    'wireName',
    'Unsupported NotificationTemplateCategory.',
  );
}

enum NotificationTemplateVariable {
  displayName,
  streak,
  progress,
  pendingCount,
  completedCount,
  totalCount,
  habitName,
  weekday,
  timeOfDay,
}

extension NotificationTemplateVariableX on NotificationTemplateVariable {
  String get wireName {
    switch (this) {
      case NotificationTemplateVariable.displayName:
        return 'displayName';
      case NotificationTemplateVariable.streak:
        return 'streak';
      case NotificationTemplateVariable.progress:
        return 'progress';
      case NotificationTemplateVariable.pendingCount:
        return 'pendingCount';
      case NotificationTemplateVariable.completedCount:
        return 'completedCount';
      case NotificationTemplateVariable.totalCount:
        return 'totalCount';
      case NotificationTemplateVariable.habitName:
        return 'habitName';
      case NotificationTemplateVariable.weekday:
        return 'weekday';
      case NotificationTemplateVariable.timeOfDay:
        return 'timeOfDay';
    }
  }
}

NotificationTemplateVariable notificationTemplateVariableFromWireName(
  String wireName,
) {
  final normalized = wireName.trim();
  for (final value in NotificationTemplateVariable.values) {
    if (value.wireName == normalized) {
      return value;
    }
  }
  throw ArgumentError.value(
    wireName,
    'wireName',
    'Unsupported NotificationTemplateVariable.',
  );
}

@immutable
class NotificationRenderContext {
  const NotificationRenderContext({
    this.displayName,
    this.streak,
    this.progress,
    this.pendingCount,
    this.completedCount,
    this.totalCount,
    this.habitName,
    this.weekday,
    this.timeOfDay,
  });

  final String? displayName;
  final int? streak;
  final String? progress;
  final int? pendingCount;
  final int? completedCount;
  final int? totalCount;
  final String? habitName;
  final String? weekday;
  final String? timeOfDay;

  List<NotificationTemplateVariable> missingRequired(
    Iterable<NotificationTemplateVariable> requiredVariables,
  ) {
    return requiredVariables
        .where((variable) => !hasValueFor(variable))
        .toList(growable: false);
  }

  bool hasValueFor(NotificationTemplateVariable variable) {
    switch (variable) {
      case NotificationTemplateVariable.displayName:
        return _hasText(displayName);
      case NotificationTemplateVariable.streak:
        return streak != null;
      case NotificationTemplateVariable.progress:
        return _hasText(progress);
      case NotificationTemplateVariable.pendingCount:
        return pendingCount != null;
      case NotificationTemplateVariable.completedCount:
        return completedCount != null;
      case NotificationTemplateVariable.totalCount:
        return totalCount != null;
      case NotificationTemplateVariable.habitName:
        return _hasText(habitName);
      case NotificationTemplateVariable.weekday:
        return _hasText(weekday);
      case NotificationTemplateVariable.timeOfDay:
        return _hasText(timeOfDay);
    }
  }

  String? stringValue(NotificationTemplateVariable variable) {
    switch (variable) {
      case NotificationTemplateVariable.displayName:
        return _normalizedText(displayName);
      case NotificationTemplateVariable.progress:
        return _normalizedText(progress);
      case NotificationTemplateVariable.habitName:
        return _normalizedText(habitName);
      case NotificationTemplateVariable.weekday:
        return _normalizedText(weekday);
      case NotificationTemplateVariable.timeOfDay:
        return _normalizedText(timeOfDay);
      case NotificationTemplateVariable.streak:
        return streak?.toString();
      case NotificationTemplateVariable.pendingCount:
        return pendingCount?.toString();
      case NotificationTemplateVariable.completedCount:
        return completedCount?.toString();
      case NotificationTemplateVariable.totalCount:
        return totalCount?.toString();
    }
  }

  int? intValue(NotificationTemplateVariable variable) {
    switch (variable) {
      case NotificationTemplateVariable.streak:
        return streak;
      case NotificationTemplateVariable.pendingCount:
        return pendingCount;
      case NotificationTemplateVariable.completedCount:
        return completedCount;
      case NotificationTemplateVariable.totalCount:
        return totalCount;
      case NotificationTemplateVariable.displayName:
      case NotificationTemplateVariable.progress:
      case NotificationTemplateVariable.habitName:
      case NotificationTemplateVariable.weekday:
      case NotificationTemplateVariable.timeOfDay:
        return null;
    }
  }

  Map<NotificationTemplateVariable, String> resolveValues(
    Iterable<NotificationTemplateVariable> variables,
  ) {
    final values = <NotificationTemplateVariable, String>{};
    for (final variable in variables) {
      final value = stringValue(variable);
      if (value != null) {
        values[variable] = value;
      }
    }
    return UnmodifiableMapView<NotificationTemplateVariable, String>(values);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NotificationRenderContext &&
            other.displayName == displayName &&
            other.streak == streak &&
            other.progress == progress &&
            other.pendingCount == pendingCount &&
            other.completedCount == completedCount &&
            other.totalCount == totalCount &&
            other.habitName == habitName &&
            other.weekday == weekday &&
            other.timeOfDay == timeOfDay;
  }

  @override
  int get hashCode => Object.hash(
        displayName,
        streak,
        progress,
        pendingCount,
        completedCount,
        totalCount,
        habitName,
        weekday,
        timeOfDay,
      );
}

@immutable
class RenderedNotificationContent {
  RenderedNotificationContent({
    required this.templateId,
    required this.templateKey,
    required this.locale,
    required this.category,
    required String title,
    required String body,
    Map<NotificationTemplateVariable, String> resolvedVariables =
        const <NotificationTemplateVariable, String>{},
  })  : title = title.trim(),
        body = body.trim(),
        resolvedVariables =
            UnmodifiableMapView<NotificationTemplateVariable, String>(
          resolvedVariables,
        ) {
    if (this.title.isEmpty) {
      throw ArgumentError.value(title, 'title', 'title cannot be empty.');
    }
    if (this.body.isEmpty) {
      throw ArgumentError.value(body, 'body', 'body cannot be empty.');
    }
  }

  final String templateId;
  final String templateKey;
  final String locale;
  final NotificationTemplateCategory category;
  final String title;
  final String body;
  final Map<NotificationTemplateVariable, String> resolvedVariables;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RenderedNotificationContent &&
            other.templateId == templateId &&
            other.templateKey == templateKey &&
            other.locale == locale &&
            other.category == category &&
            other.title == title &&
            other.body == body &&
            mapEquals(other.resolvedVariables, resolvedVariables);
  }

  @override
  int get hashCode => Object.hash(
        templateId,
        templateKey,
        locale,
        category,
        title,
        body,
        Object.hashAll(
          resolvedVariables.entries.map(
            (entry) => Object.hash(entry.key, entry.value),
          ),
        ),
      );
}

bool _hasText(String? value) => _normalizedText(value) != null;

String? _normalizedText(String? value) {
  if (value == null) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  return normalized;
}
