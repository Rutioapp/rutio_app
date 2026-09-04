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
  WeeklyReportSnapshot? exactWeekResult;
  int exactWeekCalls = 0;

  @override
  Future<WeeklyReportSnapshot?> getLatest() async {
    if (failure != null) throw failure!;
    return result;
  }

  @override
  Future<WeeklyReportSnapshot> getById(String reportId) =>
      throw UnimplementedError();
  @override
  Future<WeeklyReportSnapshot?> getByWeekStart(DateTime weekStartDate) async {
    exactWeekCalls++;
    return exactWeekResult;
  }

  @override
  Future<WeeklyReportHistoryPage> getHistory(
          {DateTime? beforeWeekStart, int limit = 20}) =>
      throw UnimplementedError();
  @override
  Future<WeeklyReportSnapshot> refreshProvisional(DateTime weekStartDate) =>
      _refresh(weekStartDate);

  Future<WeeklyReportSnapshot> _refresh(DateTime weekStartDate) async {
    refreshCalls++;
    refreshedWeekStart = weekStartDate;
    if (refreshFailure != null) throw refreshFailure!;
    return refreshResult ?? result!;
  }

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {}
}

WeeklyReport _report({
  WeeklyReportStatus status = WeeklyReportStatus.finalized,
  DateTime? weekDate,
}) =>
    WeeklyReport(
      id: 'report-1',
      userId: 'user-1',
      week: WeeklyReportWeek.fromDate(weekDate ?? DateTime(2026, 9, 1)),
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

  test('refreshes an existing current provisional report on open once',
      () async {
    final current = WeeklyReportSnapshot(
      report: _report(status: WeeklyReportStatus.provisional),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    );
    final repository = _FakeRepository(current)..refreshResult = current;
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      refreshCurrentOnLoad: true,
      now: () => DateTime(2026, 9, 4, 12),
    );

    await controller.load();

    expect(repository.refreshCalls, 1);
    expect(repository.exactWeekCalls, 0);
    expect(controller.state, isA<WeeklyReportDataState>());
  });

  test('generates current week when latest is a previous final report',
      () async {
    final current = WeeklyReportSnapshot(
      report: _report(status: WeeklyReportStatus.provisional),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    );
    final repository = _FakeRepository(WeeklyReportSnapshot(
      report: _report(weekDate: DateTime(2026, 8, 24)),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    ))
      ..refreshResult = current;
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      refreshCurrentOnLoad: true,
      now: () => DateTime(2026, 9, 4, 12),
    );

    await controller.load();

    expect(repository.exactWeekCalls, 1);
    expect(repository.refreshCalls, 1);
    expect((controller.state as WeeklyReportDataState).report.isProvisional,
        isTrue);
  });

  test('generates current week when no current report exists', () async {
    final current = WeeklyReportSnapshot(
      report: _report(status: WeeklyReportStatus.provisional),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    );
    final repository = _FakeRepository(null)..refreshResult = current;
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      refreshCurrentOnLoad: true,
      now: () => DateTime(2026, 9, 4, 12),
    );

    await controller.load();

    expect(repository.exactWeekCalls, 1);
    expect(repository.refreshCalls, 1);
    expect((controller.state as WeeklyReportDataState).report.isProvisional,
        isTrue);
  });

  test('does not refresh a current final report', () async {
    final repository = _FakeRepository(WeeklyReportSnapshot(
      report: _report(),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false,
    ));
    final controller = WeeklyReportController(
      repository,
      timeZoneResolver: () async => 'Europe/Madrid',
      refreshCurrentOnLoad: true,
      now: () => DateTime(2026, 9, 4, 12),
    );

    await controller.load();
    await controller.refreshCurrentWeek();

    expect(repository.refreshCalls, 0);
  });

  test('preserves a valid provisional report when refresh fails', () async {
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
    await controller.refreshCurrentWeek();

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
    await controller.refreshCurrentWeek();

    expect(repository.refreshCalls, 0);
  });
}
