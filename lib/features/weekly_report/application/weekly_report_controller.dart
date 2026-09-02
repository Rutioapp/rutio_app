import 'package:flutter/foundation.dart';
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
    this.isScopeCurrent = _alwaysCurrent,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final WeeklyReportRepository repository;
  final Future<String?> Function() timeZoneResolver;
  final bool Function() isScopeCurrent;
  final DateTime Function() _now;
  WeeklyReportUiState _state = const WeeklyReportLoading();
  WeeklyReportUiState get state => _state;
  bool _debugActionInProgress = false;
  bool get debugActionInProgress => _debugActionInProgress;

  Future<void> load() async {
    _state = const WeeklyReportLoading();
    notifyListeners();
    try {
      final snapshot = await repository.getLatest();
      _state = snapshot == null
          ? const WeeklyReportEmpty()
          : WeeklyReportDataState(snapshot);
    } on WeeklyReportError catch (error) {
      _state = WeeklyReportFailure(error);
    } catch (error) {
      _state = WeeklyReportFailure(WeeklyReportNetworkFailure(error));
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    final current = _state;
    if (current is! WeeklyReportDataState || !current.report.isProvisional) {
      return load();
    }
    try {
      _state = WeeklyReportDataState(
        await repository.refreshProvisional(
          current.report.week.weekStartDate,
        ),
      );
      notifyListeners();
    } on WeeklyReportError {
      // Keep usable cached data visible if a refresh fails.
    }
  }

  /// Debug-only command: the repository remains authoritative and the date
  /// cannot be supplied by the caller.
  Future<void> generateCurrentDebug() async {
    if (_debugActionInProgress) return;
    final previous = _state;
    _debugActionInProgress = true;
    notifyListeners();
    try {
      _debugLog('activation start');
      final timezoneName = (await timeZoneResolver())?.trim();
      if (!isScopeCurrent()) throw const WeeklyReportStaleScope();
      if (timezoneName == null || timezoneName.isEmpty) {
        throw const WeeklyReportActivationFailure();
      }
      final localDate = _localDateIn(timezoneName, _now());
      _debugLog('timezoneId=$timezoneName localActivationDate=$localDate');
      await repository.activate(
        activationLocalDate: localDate,
        timezoneName: timezoneName,
      );
      _debugLog('activation success');
      if (!isScopeCurrent()) throw const WeeklyReportStaleScope();
      final weekStart = WeeklyReportWeek.fromDate(localDate).weekStartDate;
      _debugLog('refresh start');
      final snapshot = await repository.refreshProvisional(
        weekStart,
      );
      if (!isScopeCurrent()) throw const WeeklyReportStaleScope();
      _debugLog('refresh success');
      _state = WeeklyReportDataState(snapshot);
    } on WeeklyReportError catch (error) {
      _debugLog('failure type=${error.runtimeType}');
      _state = previous is WeeklyReportDataState
          ? previous
          : WeeklyReportFailure(error);
    } finally {
      _debugActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> refreshProvisionalDebug() async {
    final current = _state;
    if (current is! WeeklyReportDataState || !current.report.isProvisional) {
      return;
    }
    if (_debugActionInProgress) return;
    _debugActionInProgress = true;
    notifyListeners();
    try {
      _state = WeeklyReportDataState(
        await repository.refreshProvisional(current.report.week.weekStartDate),
      );
    } on WeeklyReportError {
      // Keep the valid provisional snapshot visible when refresh fails.
    } finally {
      _debugActionInProgress = false;
      notifyListeners();
    }
  }

  DateTime _localDateIn(String timezoneName, DateTime now) {
    tzdata.initializeTimeZones();
    final local = tz.TZDateTime.from(now.toUtc(), tz.getLocation(timezoneName));
    return DateTime(local.year, local.month, local.day);
  }

  static bool _alwaysCurrent() => true;

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[WEEKLY_REPORT_DEBUG] $message');
  }
}
