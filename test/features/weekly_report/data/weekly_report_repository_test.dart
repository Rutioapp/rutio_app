import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/weekly_report/data/remote/remote_weekly_report.dart';
import 'package:rutio/features/weekly_report/data/remote/weekly_report_mapper.dart';
import 'package:rutio/features/weekly_report/data/weekly_report_repository.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'dart:async';

Map<String, dynamic> payload({String status = 'provisional', int schema = 1}) =>
    {
      'schemaVersion': schema,
      'metricsPolicyVersion': 1,
      'contentVersion': 1,
      'report': {
        'id': 'r1',
        'userId': 'u1',
        'weekStartDate': '2026-08-31',
        'weekEndDate': '2026-09-06',
        'timezoneId': 'Europe/Madrid',
        'status': status,
        'firstPartialWeek': true,
        'scheduledCount': 0,
        'completedCount': 0,
        'completionRate': null,
        'bestDay': null,
        'trendKind': 'unavailable',
        'trendDelta': null,
        'comparabilityReason': 'first_partial_week',
        'schemaVersion': 1,
        'metricsPolicyVersion': 1,
        'contentVersion': 1,
        'messageKeys': [],
        'generatedAt': '2026-09-01T10:00:00Z',
        'refreshedAt': '2026-09-01T10:00:00Z',
        'finalizedAt': status == 'final' ? '2026-09-07T10:00:00Z' : null,
      },
      'days': [
        {
          'date': '2026-08-31',
          'scheduledCount': 0,
          'completedCount': 0,
          'skippedCount': 0,
          'completionRate': null,
          'state': 'noPlan'
        },
      ],
      'habits': [
        {
          'habitId': 'h1',
          'name': 'Read',
          'emoji': '📖',
          'type': 'check',
          'target': null,
          'familyId': null,
          'schedule': {'type': 'daily'},
          'scheduledCount': 0,
          'completedCount': 0,
          'skippedCount': 0,
          'completionRate': null,
          'occurrences': [
            {
              'date': '2026-08-31',
              'scope': 'date',
              'scheduleType': 'daily',
              'scheduled': false,
              'completed': false,
              'skipped': false,
              'progress': null,
              'target': null
            }
          ],
          'streakSnapshot': null
        },
      ],
      'recommendations': [],
    };

void main() {
  test('strict DTO maps final and zero scheduled rate', () {
    final remote = RemoteWeeklyReport.fromJson(payload(status: 'final'));
    final report = mapRemoteWeeklyReport(remote);
    expect(report.status, WeeklyReportStatus.finalized);
    expect(report.summary.completionRate, isNull);
    expect(report.days.single.state, WeeklyReportDayState.noPlan);
    expect(report.habits.single.occurrences.single.scope,
        HabitOccurrenceScope.dateBound);
  });

  test('newer schema is rejected without silent fallback', () {
    expect(() => RemoteWeeklyReport.fromJson(payload(schema: 2)),
        throwsA(isA<WeeklyReportPayloadException>()));
  });

  test('cache is isolated by scope and preserves final over provisional',
      () async {
    final cache = InMemoryWeeklyReportCache();
    final provisional = RemoteWeeklyReport.fromJson(payload());
    final finalized = RemoteWeeklyReport.fromJson(payload(status: 'final'));
    await cache.write('user-a', 'r1', finalized,
        cachedAt: DateTime.utc(2026, 9, 1));
    await cache.write('user-a', 'r1', provisional,
        cachedAt: DateTime.utc(2026, 9, 2));
    expect(await cache.read('user-b', 'r1'), isNull);
    expect((await cache.read('user-a', 'r1'))!.payload.report.status, 'final');
  });

  test(
      'repository matrix A-D/K: remote, fallback, empty errors and schema safety',
      () async {
    final cache = InMemoryWeeklyReportCache();
    var scope = (userId: 'u1', epoch: 1);
    final remote = _FakeRemote(RemoteWeeklyReport.fromJson(payload()));
    final repo = SupabaseWeeklyReportRepository(
        remote: remote, cache: cache, scopeProvider: () => scope);
    final fresh = await repo.getLatest();
    expect(fresh!.source, WeeklyReportDataSource.remoteFresh);
    remote.latestError = StateError('offline');
    expect((await repo.getLatest())!.source,
        WeeklyReportDataSource.cachedProvisional);
    remote.latestValue = null;
    remote.latestError = StateError('offline');
    scope = (userId: 'u2', epoch: 2);
    await expectLater(
        repo.getLatest(), throwsA(isA<WeeklyReportNetworkFailure>()));
    remote.latestError = const WeeklyReportMalformedPayload();
    await expectLater(
        repo.getLatest(), throwsA(isA<WeeklyReportMalformedPayload>()));
    remote.latestError = const WeeklyReportUnsupportedSchema();
    await expectLater(
        repo.getLatest(), throwsA(isA<WeeklyReportUnsupportedSchema>()));
  });

  test('repository matrix E/G-I: scopes, refresh ordering and final protection',
      () async {
    var scope = (userId: 'u1', epoch: 1);
    final cache = InMemoryWeeklyReportCache();
    final remote = _FakeRemote(RemoteWeeklyReport.fromJson(payload()));
    final repo = SupabaseWeeklyReportRepository(
        remote: remote, cache: cache, scopeProvider: () => scope);
    await repo.getLatest();
    remote.refreshValue = RemoteWeeklyReport.fromJson(payload());
    final refreshed = await repo.refreshProvisional(DateTime(2026, 8, 31));
    expect(refreshed.report.summary.scheduledCount, 0);
    remote.refreshError = StateError('offline');
    await expectLater(repo.refreshProvisional(DateTime(2026, 8, 31)),
        throwsA(isA<WeeklyReportRefreshRejected>()));
    expect(await cache.read('u1', 'latest'), isNotNull);
    await cache.write(
        'u1', 'r1', RemoteWeeklyReport.fromJson(payload(status: 'final')),
        cachedAt: DateTime.now());
    remote.refreshError = null;
    remote.refreshValue = RemoteWeeklyReport.fromJson(payload(status: 'final'));
    expect((await repo.refreshProvisional(DateTime(2026, 8, 31))).report.status,
        WeeklyReportStatus.finalized);
    remote.latestError = StateError('offline');
    expect((await cache.read('u1', 'r1'))!.payload.report.status, 'final');
    scope = (userId: 'u2', epoch: 2);
    expect(await cache.read('u2', 'r1'), isNull);
  });

  test('repository matrix F: stale latest and refresh never publish or cache',
      () async {
    var scope = (userId: 'u1', epoch: 1);
    final cache = InMemoryWeeklyReportCache();
    final remote = _FakeRemote(null)
      ..latestCompleter = Completer<RemoteWeeklyReport?>();
    final repo = SupabaseWeeklyReportRepository(
        remote: remote, cache: cache, scopeProvider: () => scope);
    final pendingLatest = repo.getLatest();
    scope = (userId: 'u2', epoch: 2);
    remote.latestCompleter!.complete(RemoteWeeklyReport.fromJson(payload()));
    await expectLater(pendingLatest, throwsA(isA<WeeklyReportStaleScope>()));
    expect(await cache.read('u2', 'r1'), isNull);
    scope = (userId: 'u1', epoch: 3);
    remote.refreshCompleter = Completer<RemoteWeeklyReport?>();
    final pendingRefresh = repo.refreshProvisional(DateTime(2026, 8, 31));
    scope = (userId: 'u2', epoch: 4);
    remote.refreshCompleter!.complete(RemoteWeeklyReport.fromJson(payload()));
    await expectLater(pendingRefresh, throwsA(isA<WeeklyReportStaleScope>()));
  });

  test('repository matrix J: history clamps limit and passes cursor', () async {
    var scope = (userId: 'u1', epoch: 1);
    final remote = _FakeRemote(null)
      ..historyPages = <List<RemoteWeeklyReportHistoryItem>>[
        List<RemoteWeeklyReportHistoryItem>.generate(
            50,
            (i) => _history(
                _isoDate(DateTime(2026, 8, 31).subtract(Duration(days: i))))),
        [_history('2026-07-12')]
      ];
    final repo = SupabaseWeeklyReportRepository(
        remote: remote,
        cache: InMemoryWeeklyReportCache(),
        scopeProvider: () => scope);
    final first = await repo.getHistory(limit: 1000);
    final second = await repo.getHistory(
        beforeWeekStart: first.nextBeforeWeekStart, limit: 1);
    expect(remote.historyLimits, [50, 1]);
    expect(first.items.map((e) => e.reportId),
        isNot(contains(second.items.single.reportId)));
    expect(first.hasMore, isTrue);
  });
}

RemoteWeeklyReportHistoryItem _history(String start) =>
    RemoteWeeklyReportHistoryItem({
      'reportId': 'r-$start',
      'weekStartDate': start,
      'weekEndDate': '2026-09-06',
      'status': 'final',
      'completionRate': .5,
      'completedCount': 1,
      'scheduledCount': 2,
      'firstPartialWeek': false,
      'refreshedAt': null,
      'finalizedAt': null,
    });

String _isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class _FakeRemote implements WeeklyReportRemoteDataSource {
  _FakeRemote(this.latestValue);
  RemoteWeeklyReport? latestValue;
  RemoteWeeklyReport? refreshValue;
  Object? latestError;
  Object? refreshError;
  Object? activationError;
  int activationCalls = 0;
  Completer<RemoteWeeklyReport?>? latestCompleter;
  Completer<RemoteWeeklyReport?>? refreshCompleter;
  List<List<RemoteWeeklyReportHistoryItem>> historyPages = [];
  final List<int> historyLimits = [];
  @override
  Future<RemoteWeeklyReport?> getLatest() async {
    if (latestCompleter != null) return latestCompleter!.future;
    if (latestError != null) throw latestError!;
    return latestValue;
  }

  @override
  Future<RemoteWeeklyReport?> getById(String reportId) async => latestValue;
  @override
  Future<RemoteWeeklyReport?> getByWeekStart(DateTime weekStartDate) async =>
      latestValue;
  @override
  Future<List<RemoteWeeklyReportHistoryItem>> getHistory(
      {DateTime? beforeWeekStart, required int limit}) async {
    historyLimits.add(limit);
    return historyPages.isEmpty ? const [] : historyPages.removeAt(0);
  }

  @override
  Future<RemoteWeeklyReport?> refresh(DateTime weekStartDate) async {
    if (refreshCompleter != null) return refreshCompleter!.future;
    if (refreshError != null) throw refreshError!;
    return refreshValue ?? latestValue;
  }

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {
    activationCalls++;
    if (activationError != null) throw activationError!;
  }
}
