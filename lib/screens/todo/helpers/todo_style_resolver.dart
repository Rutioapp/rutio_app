import 'package:flutter/material.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/models/todo_filter.dart';
import 'package:rutio/screens/todo/models/todo_priority.dart';
import 'package:rutio/screens/todo/models/todo_type.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/utils/family_theme.dart';

class TodoStyleResolver {
  static const Color backgroundTop = Color(0xFFDDE9F2);
  static const Color backgroundMid = Color(0xFFECE5D7);
  static const Color backgroundBottom = Color(0xFFF4ECDC);
  static const Color sheetChrome = Color(0xFFB8BEC5);
  static const Color shell = Color(0xFFF3ECDE);
  static const Color surface = Color(0xFFF9F4EC);
  static const Color surfaceMuted = Color(0xFFF2EBE0);
  static const Color stroke = Color(0xFFF0E3D3);
  static const Color divider = Color(0x33BF9B73);
  static const Color accent = Color(0xFF5B2F18);
  static const Color accentSoft = Color(0xFFB78048);
  static const Color textPrimary = Color(0xFF4A2B1E);
  static const Color textMuted = Color(0xFF8E7A67);
  static const Color section = Color(0xFFC28A52);
  static const Color progressTrack = Color(0xFFE6DDD0);
  static const Color progressValue = Color(0xFF7EA57F);
  static const Color success = Color(0xFFA9BC99);
  static const Color warning = Color(0xFFC57C57);
  static const Color warningSoft = Color(0xFFF6E4DD);
  static const Color neutralChip = Color(0xFFF0E7DA);
  static const Color neutralChipText = Color(0xFF8B755F);
  static const Color shadow = Color(0x12000000);
  static const Color personal = Color(0xFFC89769);
  static const Color urgent = Color(0xFFCF5C42);

  static const List<String> categoryIds = <String>[
    FamilyTheme.mind,
    FamilyTheme.spirit,
    FamilyTheme.body,
    FamilyTheme.emotional,
    FamilyTheme.social,
    FamilyTheme.discipline,
    'personal',
    FamilyTheme.professional,
  ];

  static LinearGradient backgroundGradient() {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[backgroundTop, backgroundMid, backgroundBottom],
      stops: <double>[0.0, 0.40, 1.0],
    );
  }

  static TextStyle screenTitleStyle(BuildContext context) {
    return AppTextStyles.welcomeTitle.copyWith(
      fontSize: 28,
      height: 1.04,
      color: textPrimary,
    );
  }

  static TextStyle dateStyle(BuildContext context) {
    return AppTextStyles.fieldInput.copyWith(
      fontSize: 15,
      color: accentSoft,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle sectionStyle(BuildContext context) {
    return AppTextStyles.fieldLabel.copyWith(
      fontSize: 13,
      color: section,
      letterSpacing: 1.35,
    );
  }

  static TextStyle cardTitleStyle(BuildContext context) {
    return AppTextStyles.fieldInput.copyWith(
      fontSize: 16,
      color: textPrimary,
      fontWeight: FontWeight.w500,
      height: 1.2,
    );
  }

  static TextStyle mutedBodyStyle(BuildContext context) {
    return AppTextStyles.fieldInput.copyWith(
      fontSize: 13,
      color: textMuted,
      fontWeight: FontWeight.w500,
    );
  }

  static Color categoryColor(String categoryId) {
    if (categoryId == 'personal') {
      return personal;
    }
    return FamilyTheme.colorOf(categoryId);
  }

  static Color categoryBackground(String categoryId) {
    return categoryColor(categoryId).withValues(alpha: 0.14);
  }

  static String categoryName(BuildContext context, String categoryId) {
    if (categoryId == 'personal') {
      return context.l10n.familyPersonalName;
    }
    return context.l10n.familyName(categoryId);
  }

  static String priorityLabel(AppLocalizations l10n, TodoPriority priority) {
    switch (priority) {
      case TodoPriority.none:
        return l10n.todoPriorityNone;
      case TodoPriority.normal:
        return l10n.todoPriorityNormal;
      case TodoPriority.high:
        return l10n.todoPriorityHigh;
      case TodoPriority.urgent:
        return l10n.todoPriorityUrgent;
    }
  }

  static String priorityBadgeLabel(
      AppLocalizations l10n, TodoPriority priority) {
    switch (priority) {
      case TodoPriority.none:
        return l10n.todoPriorityNone;
      case TodoPriority.normal:
        return l10n.todoPriorityNormal;
      case TodoPriority.high:
        return l10n.todoPriorityHighBadge;
      case TodoPriority.urgent:
        return l10n.todoPriorityUrgentBadge;
    }
  }

  static Color priorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.none:
        return neutralChipText;
      case TodoPriority.normal:
        return const Color(0xFF56775B);
      case TodoPriority.high:
        return warning;
      case TodoPriority.urgent:
        return urgent;
    }
  }

  static Color priorityBackground(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.none:
        return neutralChip;
      case TodoPriority.normal:
        return const Color(0xFFE2EAD8);
      case TodoPriority.high:
        return const Color(0xFFF6E4DD);
      case TodoPriority.urgent:
        return const Color(0xFFFFF2EF);
    }
  }

  static String filterLabel(AppLocalizations l10n, TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return l10n.todoFilterAll;
      case TodoFilter.pending:
        return l10n.todoFilterPending;
      case TodoFilter.today:
        return l10n.todoFilterToday;
      case TodoFilter.thisWeek:
        return l10n.todoFilterThisWeek;
      case TodoFilter.completed:
        return l10n.todoFilterCompleted;
    }
  }

  static String typeLabel(AppLocalizations l10n, TodoType type) {
    switch (type) {
      case TodoType.free:
        return l10n.todoTypeFree;
      case TodoType.linkedHabit:
        return l10n.todoTypeLinkedHabit;
    }
  }
}
