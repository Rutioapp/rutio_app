import 'package:flutter/foundation.dart';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../domain/weekly_report.dart';

/// Performs the product activation once per stable authenticated scope. The
/// server RPC remains idempotent and updates the future-automation timezone.
class WeeklyReportActivationService {
  WeeklyReportActivationService({required this.repository});

  final WeeklyReportRepository repository;
  String? _completedKey;
  Future<void>? _inFlight;

  Future<void> ensureActivated({
    required String userId,
    required int scopeEpoch,
    required Future<String?> Function() timezoneResolver,
    DateTime Function()? now,
  }) {
    final key = '$userId|$scopeEpoch';
    if (_completedKey == key) return Future<void>.value();
    return _inFlight ??= _activate(
      key: key,
      timezoneResolver: timezoneResolver,
      now: now ?? DateTime.now,
    ).whenComplete(() => _inFlight = null);
  }

  Future<void> _activate({
    required String key,
    required Future<String?> Function() timezoneResolver,
    required DateTime Function() now,
  }) async {
    final timezone = (await timezoneResolver())?.trim();
    if (timezone == null || timezone.isEmpty) return;
    tzdata.initializeTimeZones();
    final localNow =
        tz.TZDateTime.from(now().toUtc(), tz.getLocation(timezone));
    // The RPC contract needs today's local calendar date, not Monday.
    final activationDate =
        DateTime(localNow.year, localNow.month, localNow.day);
    await repository.activate(
      activationLocalDate: activationDate,
      timezoneName: timezone,
    );
    _completedKey = key;
    if (kDebugMode) {
      debugPrint(
          '[WEEKLY_REPORT_AUTOMATION] activated timezone=$timezone date=$activationDate');
    }
  }
}
