import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/habits/domain/metrics/weekly_report_week.dart';
import 'package:rutio/features/weekly_report/application/weekly_report_controller.dart';
import 'package:rutio/features/weekly_report/data/weekly_report_repository.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';

class _FakeRepository implements WeeklyReportRepository {
  _FakeRepository(this.result);
  WeeklyReportSnapshot? result;
  WeeklyReportError? failure;
  WeeklyReportError? refreshFailure;
  int refreshCalls = 0;
  DateTime? refreshedWeekStart;
  WeeklyReportSnapshot? refreshResult;
  final List<String> events = [];
  int activationCalls = 0;
  DateTime? activationDate;
  String? activationTimezone;
  void Function()? activationOnSuccess;

  @override
  Future<WeeklyReportSnapshot?> getLatest() async {
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<WeeklyReportSnapshot> getById(String reportId) =>
      throw UnimplementedError();
  @override
  Future<WeeklyReportSnapshot?> getByWeekStart(DateTime weekStartDate) =>
      throw UnimplementedError();
  @override
  Future<WeeklyReportHistoryPage> getHistory(
          {DateTime? beforeWeekStart, int limit = 20}) =>
      throw UnimplementedError();
  @override
  Future<WeeklyReportSnapshot> refreshProvisional(DateTime weekStartDate) =>
      _refresh(weekStartDate);

  Future<WeeklyReportSnapshot> _refresh(DateTime weekStartDate) async {
    events.add('refresh');
    refreshCalls++;
    refreshedWeekStart = weekStartDate;
    if (refreshFailure != null) throw refreshFailure!;
    return refreshResult ?? result!;
  }

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {
    events.add('activate');
    activationCalls++;
    activationDate = activationLocalDate;
    activationTimezone = timezoneName;
    if (failure != null) throw failure!;
    activationOnSuccess?.call();
  }
}

WeeklyReport _report(
        {WeeklyReportStatus status = WeeklyReportStatus.finalized}) =>
    WeeklyReport(
      id: 'report-1',
      userId: 'user-1',
      week: WeeklyReportWeek.fromDate(DateTime(2026, 9, 1)),
      timezoneId: 'Europe/Madrid',
      status: status,
      firstPartialWeek: false,
      summary: const WeeklyReportSummary(
        scheduledCount: 3,
        completedCount: 1,
        completionRate: .42,
      ),
      days: const [],
      habits: const [],
      trend: const WeeklyReportTrend(
        kind: WeeklyReportTrendKind.unavailable,
        delta: 0,
        comparable: false,
        reason: 'not comparable',
      ),
      schemaVersion: 1,
      metricsPolicyVersion: 1,
      contentVersion: 1,
    );

void main() {
  test('publishes empty and recoverable error states', () async {
    final empty = WeeklyReportController(
      _FakeRepository(null),
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await empty.load();
    expect(empty.state, isA<WeeklyReportEmpty>());

    final errorRepository = _FakeRepository(null)
      ..failure = const WeeklyReportNetworkFailure();
    final failed = WeeklyReportController(
      errorRepository,
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await failed.load();
    expect(failed.state, isA<WeeklyReportFailure>());
  });

  test('keeps backend completion rate and denominator authoritative', () async {
    final snapshot = WeeklyReportSnapshot(
      report: _report(),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    );
    final controller = WeeklyReportController(
      _FakeRepository(snapshot),
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await controller.load();

    final state = controller.state as WeeklyReportDataState;
    expect(state.report.summary.completionRate, .42);
    expect(state.report.summary.scheduledCount, 3);
    expect(state.report.days, isEmpty);
  });

  test('generates the current Monday-Sunday week from empty', () async {
    final repository = _FakeRepository(null)
      ..refreshResult = WeeklyReportSnapshot(
        report: _report(status: WeeklyReportStatus.provisional),
        source: WeeklyReportDataSource.remoteFresh,
        cachedAt: null,
        isStale: false,
      );
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      now: () => DateTime(2026, 9, 2, 12),
    );
    await controller.load();
    await controller.generateCurrentDebug();

    expect(repository.refreshCalls, 1);
    expect(repository.activationCalls, 1);
    expect(repository.activationTimezone, 'Europe/Madrid');
    expect(repository.activationDate, DateTime(2026, 9, 2));
    expect(repository.refreshedWeekStart?.weekday, DateTime.monday);
    expect(controller.state, isA<WeeklyReportDataState>());
  });

  test('preserves a valid provisional report when debug refresh fails',
      () async {
    final repository = _FakeRepository(WeeklyReportSnapshot(
      report: _report(status: WeeklyReportStatus.provisional),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    ));
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await controller.load();
    repository.refreshFailure = const WeeklyReportNetworkFailure();
    await controller.refreshProvisionalDebug();

    expect(repository.refreshCalls, 1);
    expect(controller.state, isA<WeeklyReportDataState>());
  });

  test('does not refresh finalized reports', () async {
    final repository = _FakeRepository(WeeklyReportSnapshot(
      report: _report(),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    ));
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await controller.load();
    await controller.refreshProvisionalDebug();

    expect(repository.refreshCalls, 0);
  });

  test('does not refresh when scope changes during activation', () async {
    final repository = _FakeRepository(null)
      ..refreshResult = WeeklyReportSnapshot(
        report: _report(status: WeeklyReportStatus.provisional),
        source: WeeklyReportDataSource.remoteFresh,
        cachedAt: null,
        isStale: false,
      );
    var scopeIsCurrent = true;
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      isScopeCurrent: () => scopeIsCurrent,
    );
    repository.activationOnSuccess = () => scopeIsCurrent = false;
    await controller.load();
    await controller.generateCurrentDebug();

    expect(repository.events, ['activate']);
    expect(controller.state, isA<WeeklyReportFailure>());
  });

  test('keeps activation and exposes refresh failure for retry', () async {
    final repository = _FakeRepository(null)
      ..refreshResult = WeeklyReportSnapshot(
        report: _report(status: WeeklyReportStatus.provisional),
        source: WeeklyReportDataSource.remoteFresh,
        cachedAt: null,
        isStale: false,
      );
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
    );
    await controller.load();
    repository.refreshFailure = const WeeklyReportNetworkFailure();
    await controller.generateCurrentDebug();
    expect(controller.state, isA<WeeklyReportFailure>());
    expect(repository.activationCalls, 1);

    repository.refreshFailure = null;
    await controller.generateCurrentDebug();
    expect(controller.state, isA<WeeklyReportDataState>());
    expect(repository.activationCalls, 2);
  });
}
