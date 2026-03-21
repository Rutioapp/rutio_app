import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/models/todo_filter.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';

class TodoDateFormatter {
  const TodoDateFormatter._();

  static String headerDate(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMMEEEEd(locale).format(value);
  }

  static String shortDate(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.MMMd(locale).format(value);
  }

  static String time(BuildContext context, DateTime value) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final use24Hour =
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false;
    return (use24Hour || locale.startsWith('es')
            ? DateFormat.Hm(locale)
            : DateFormat.jm(locale))
        .format(value);
  }

  static bool isToday(DateTime? value, DateTime now) {
    if (value == null) return false;
    return value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
  }

  static bool isYesterday(DateTime? value, DateTime now) {
    if (value == null) return false;
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return value.year == yesterday.year &&
        value.month == yesterday.month &&
        value.day == yesterday.day;
  }

  static bool isThisWeek(DateTime? value, DateTime now) {
    if (value == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final normalized = DateTime(value.year, value.month, value.day);
    return !normalized.isBefore(start) && !normalized.isAfter(end);
  }

  static bool isOverdue(TodoItem item, DateTime now) {
    if (item.isCompleted || item.dueDate == null) return false;
    final due = item.hasTime
        ? item.dueDate!
        : DateTime(
            item.dueDate!.year, item.dueDate!.month, item.dueDate!.day, 23, 59);
    return due.isBefore(now);
  }

  static bool matchesFilter(TodoItem item, TodoFilter filter, DateTime now) {
    switch (filter) {
      case TodoFilter.all:
        return true;
      case TodoFilter.pending:
        return !item.isCompleted;
      case TodoFilter.today:
        return isToday(item.dueDate, now);
      case TodoFilter.thisWeek:
        return isThisWeek(item.dueDate, now);
      case TodoFilter.completed:
        return item.isCompleted;
    }
  }

  static String? statusLabel(
      BuildContext context, TodoItem item, DateTime now) {
    if (item.dueDate == null) return null;
    final l10n = context.l10n;
    if (isOverdue(item, now)) {
      if (isYesterday(item.dueDate, now)) {
        return l10n.todoStatusOverdueYesterday;
      }
      return l10n.todoStatusOverdueDate(shortDate(context, item.dueDate!));
    }
    if (isToday(item.dueDate, now)) {
      if (item.hasTime) {
        return l10n.todoStatusTodayAt(time(context, item.dueDate!));
      }
      return l10n.todoDateTodayFormatLabel;
    }
    if (isThisWeek(item.dueDate, now)) {
      return l10n.todoStatusThisWeek;
    }
    return l10n.todoStatusOnDate(shortDate(context, item.dueDate!));
  }

  static String? completedTimeLabel(BuildContext context, TodoItem item) {
    if (!item.isCompleted || item.dueDate == null || !item.hasTime) return null;
    return time(context, item.dueDate!);
  }
}
