import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../../notifications/domain/personalized_notification_models.dart';
import '../../notifications/application/personalized_notification_orchestrator.dart';
import '../../../services/notification_service.dart';
import '../domain/weekly_report.dart';

class WeeklyReportDebugNotificationService {
  const WeeklyReportDebugNotificationService();

  static const int _firstDebugId = 60000;
  static const int _debugRangeSize = 1000;

  Future<void> scheduleFor(
    WeeklyReport report, {
    required NotificationScope scope,
    required PersonalizedNotificationOrchestrator orchestrator,
    required String timezoneId,
  }) async {
    if (!kDebugMode) return;
    tzdata.initializeTimeZones();
    final location = tz.getLocation(timezoneId);
    final localNow = tz.TZDateTime.now(location);
    final scheduledLocal = localNow.add(const Duration(minutes: 1));
    final week = _dateOnly(report.week.weekStartDate);
    final logicalId = 'rutio:v2:debug:weekly_report_test:$week';
    final platformId = _firstDebugId + _stableHash(week) % _debugRangeSize;
    debugPrint(
      '[WEEKLY_REPORT_NOTIFICATION_TEST] request weekStart=$week '
      'scheduledLocal=${scheduledLocal.toIso8601String()} '
      'timezone=$timezoneId logicalId=$logicalId platformId=$platformId',
    );
    final result = await orchestrator.scheduleDebugWeeklyReport(
      weekStart: report.week.weekStartDate,
      scope: scope,
      timezoneId: timezoneId,
      now: () => DateTime(
        scheduledLocal.year,
        scheduledLocal.month,
        scheduledLocal.day,
        scheduledLocal.hour,
        scheduledLocal.minute,
        scheduledLocal.second,
      ).subtract(const Duration(minutes: 1)),
    );
    final pending =
        await NotificationService.instance.scheduler.pendingRequests();
    final pendingAfterReconcile =
        pending.any((request) => request.id == platformId);
    debugPrint(
      '[WEEKLY_REPORT_NOTIFICATION_TEST] pending_after_reconcile='
      '$pendingAfterReconcile platformId=$platformId',
    );
    debugPrint(
      '[WEEKLY_REPORT_NOTIFICATION_TEST] scheduledUtc='
      '${scheduledLocal.toUtc().toIso8601String()}',
    );
    if (result.reconciliationResult == null) {
      throw StateError('debug_notification_not_reconciled');
    }
  }

  static String _dateOnly(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash & 0x7fffffff;
  }
}
