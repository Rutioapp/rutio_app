import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateUtils;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

import '../data/weekly_report_repository.dart';
import '../domain/weekly_report.dart';
import '../../habits/domain/metrics/weekly_report_week.dart';

sealed class WeeklyReportUiState {
  const WeeklyReportUiState();
}

class WeeklyReportLoading extends WeeklyReportUiState {
  const WeeklyReportLoading();
}

class WeeklyReportEmpty extends WeeklyReportUiState {
  const WeeklyReportEmpty();
}

class WeeklyReportFailure extends WeeklyReportUiState {
  const WeeklyReportFailure(this.error);
  final WeeklyReportError error;
}

class WeeklyReportDataState extends WeeklyReportUiState {
  const WeeklyReportDataState(this.snapshot);
  final WeeklyReportSnapshot snapshot;
  WeeklyReport get report => snapshot.report;
}

class WeeklyReportController extends ChangeNotifier {
  WeeklyReportController(
    this.repository, {
    required this.timeZoneResolver,
    this.refreshCurrentOnLoad = false,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WeeklyReportRepository repository;
  final Future<String?> Function() timeZoneResolver;
  final bool refreshCurrentOnLoad;
  final DateTime Function() _now;
  WeeklyReportUiState _state = const WeeklyReportLoading();
  WeeklyReportUiState get state => _state;
  String? _loadedReportId;
  bool _operationInProgress = false;

  Future<void> load({String? reportId}) async {
    if (_operationInProgress) return;
    _operationInProgress = true;
    _loadedReportId = reportId;
    _state = const WeeklyReportLoading();
    notifyListeners();
    try {
      final snapshot = reportId == null && refreshCurrentOnLoad
          ? await _loadCurrentWeek()
          : reportId == null
              ? await repository.getLatest()
              : await repository.getById(reportId);
      _state = snapshot == null
          ? const WeeklyReportEmpty()
          : WeeklyReportDataState(snapshot);
    } on WeeklyReportError catch (error) {
      _state = WeeklyReportFailure(error);
    } catch (error) {
      _state = WeeklyReportFailure(WeeklyReportNetworkFailure(error));
    } finally {
      _operationInProgress = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => refreshCurrentWeek();

  Future<void> refreshCurrentWeek() async {
    if (_operationInProgress) return;
    final current = _state;
    if (current is! WeeklyReportDataState) {
      return load(reportId: _loadedReportId);
    }
    if (_loadedReportId != null || !current.report.isProvisional) {
      return;
    }
    final timezone = (await timeZoneResolver())?.trim();
    if (timezone == null ||
        timezone.isEmpty ||
        !_isCurrentWeek(current.report.week.weekStartDate, timezone)) {
      return;
    }
    final localDate = _localDateIn(timezone, _now());
    _operationInProgress = true;
    _logRefreshRequest(
      current.report,
      localDate: localDate,
      timezone: timezone,
      statusBefore: current.report.status.name,
    );
    try {
      final snapshot = await repository.refreshProvisional(
        current.report.week.weekStartDate,
      );
      _state = WeeklyReportDataState(snapshot);
      _logRefreshResult(snapshot);
      notifyListeners();
    } on WeeklyReportError catch (error) {
      _logRefreshFailure(current.report, error);
      // Keep usable cached data visible if a refresh fails.
    } finally {
      _operationInProgress = false;
    }
  }

  Future<WeeklyReportSnapshot?> _loadCurrentWeek() async {
    final latest = await repository.getLatest();
    final timezone = (await timeZoneResolver())?.trim();
    if (timezone == null || timezone.isEmpty) return latest;
    final localDate = _localDateIn(timezone, _now());
    final weekStart = WeeklyReportWeek.fromDate(localDate).weekStartDate;
    final latestIsCurrent = latest != null &&
        DateUtils.dateOnly(latest.report.week.weekStartDate) ==
            DateUtils.dateOnly(weekStart);
    var current =
        latestIsCurrent ? latest : await repository.getByWeekStart(weekStart);
    if (current == null) {
      _logRefreshRequest(
        null,
        reportId: 'none',
        weekStartDate: weekStart,
        localDate: localDate,
        timezone: timezone,
        statusBefore: 'absent',
      );
      current = await repository.refreshProvisional(weekStart);
      _logRefreshResult(current);
      return current;
    }
    if (!current.report.isProvisional) return current;
    _logRefreshRequest(
      current.report,
      localDate: localDate,
      timezone: timezone,
      statusBefore: current.report.status.name,
    );
    try {
      final refreshed = await repository.refreshProvisional(weekStart);
      _logRefreshResult(refreshed);
      return refreshed;
    } on WeeklyReportError catch (error) {
      _logRefreshFailure(current.report, error);
      return current;
    }
  }

  DateTime _localDateIn(String timezoneName, DateTime now) {
    tzdata.initializeTimeZones();
    final local = tz.TZDateTime.from(now.toUtc(), tz.getLocation(timezoneName));
    return DateTime(local.year, local.month, local.day);
  }

  bool _isCurrentWeek(DateTime weekStart, String timezoneName) {
    tzdata.initializeTimeZones();
    final local =
        tz.TZDateTime.from(_now().toUtc(), tz.getLocation(timezoneName));
    final monday = DateTime(local.year, local.month, local.day)
        .subtract(Duration(days: local.weekday - 1));
    return DateUtils.dateOnly(weekStart) == DateUtils.dateOnly(monday);
  }

  void _logRefreshRequest(
    WeeklyReport? report, {
    String? reportId,
    DateTime? weekStartDate,
    DateTime? localDate,
    required String? timezone,
    required String statusBefore,
  }) {
    if (!kDebugMode) return;
    debugPrint(
      '[WEEKLY_REPORT_REFRESH] reportId=${report?.id ?? reportId ?? 'unknown'} '
      'weekStartDate=${_dateOnly(weekStartDate ?? report?.week.weekStartDate)} '
      'localDate=${_dateOnly(localDate)} timezone=${timezone ?? 'unknown'} '
      'statusBefore=$statusBefore refresh requested',
    );
  }

  void _logRefreshResult(WeeklyReportSnapshot snapshot) {
    if (!kDebugMode) return;
    debugPrint(
      '[WEEKLY_REPORT_REFRESH] reportId=${snapshot.report.id} '
      'refresh result status=${snapshot.report.status.name} '
      'completedCount=${snapshot.report.summary.completedCount} '
      'scheduledCount=${snapshot.report.summary.scheduledCount} '
      'days=${snapshot.report.days.length} habits=${snapshot.report.habits.length} '
      'source=${snapshot.source.name}',
    );
    for (final day in snapshot.report.days) {
      debugPrint(
        '[WEEKLY_REPORT_REFRESH] date=${_dateOnly(day.date)} '
        'scheduled=${day.scheduledCount} completed=${day.completedCount} '
        'skipped=${day.skippedCount} state=${day.state.name}',
      );
    }
  }

  void _logRefreshFailure(WeeklyReport report, WeeklyReportError error) {
    if (!kDebugMode) return;
    debugPrint(
      '[WEEKLY_REPORT_REFRESH] reportId=${report.id} '
      'refresh result status=failed error=${error.runtimeType}',
    );
  }

  String _dateOnly(DateTime? date) => date == null
      ? 'unknown'
      : '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
}
