import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rutio/features/habits/domain/metrics/habit_occurrence_result.dart';
import 'package:rutio/features/habits/domain/metrics/habit_snapshot.dart';
import 'package:rutio/features/weekly_report/data/remote/remote_weekly_report.dart';
import 'package:rutio/features/weekly_report/data/remote/weekly_report_mapper.dart';
import 'package:rutio/features/weekly_report/data/weekly_report_repository.dart';
import 'package:rutio/features/weekly_report/domain/weekly_report.dart';

Map<String, dynamic> _payload({
  int policy = 2,
  String status = 'provisional',
  String reportId = 'r1',
  String refreshedAt = '2026-09-01T10:00:00Z',
  int completedCount = 3,
  int scheduledCount = 3,
  int? completedRaw = 4,
  int? scheduledQuota = 3,
  double? rawRatio = 4 / 3,
  double? cappedRatio = 1,
  String? dataQuality = 'verified',
  List<Map<String, dynamic>>? occurrences,
}) {
  final flexible = policy >= 2;
  final report = <String, dynamic>{
    'id': reportId,
    'userId': 'u1',
    'weekStartDate': '2026-08-31',
    'weekEndDate': '2026-09-06',
    'timezoneId': 'Europe/Madrid',
    'status': status,
    'firstPartialWeek': false,
    'scheduledCount': scheduledCount,
    'completedCount': completedCount,
    'completionRate':
        scheduledCount == 0 ? null : completedCount / scheduledCount,
    'bestDay': null,
    'trendKind': 'unavailable',
    'trendDelta': null,
    'comparabilityReason': null,
    'schemaVersion': 1,
    'metricsPolicyVersion': policy,
    'contentVersion': 1,
    'messageKeys': <String>[],
    'generatedAt': '2026-09-01T09:00:00Z',
    'refreshedAt': refreshedAt,
    'finalizedAt': status == 'final' ? '2026-09-07T10:00:00Z' : null,
    if (flexible) ...{
      'completedRaw': completedRaw,
      'scheduledQuota': scheduledQuota,
      'rawRatio': rawRatio,
      'cappedRatio': cappedRatio,
      'dataQuality': dataQuality,
    },
  };
  final habit = <String, dynamic>{
    'habitId': 'h1',
    'name': 'Read',
    'emoji': '📖',
    'type': 'check',
    'target': null,
    'familyId': null,
    'schedule': flexible
        ? {'type': 'timesPerWeek', 'timesPerWeek': 3, 'weekStartsOn': 1}
        : {'type': 'daily'},
    'scheduledCount': scheduledCount,
    'completedCount': completedCount,
    'skippedCount': 1,
    'completionRate':
        scheduledCount == 0 ? null : completedCount / scheduledCount,
    'classification': 'stable',
    'observationKey': null,
    'occurrences': occurrences ??
        [
          {
            'date': '2026-09-01',
            'scope': flexible ? 'weeklyQuota' : 'date',
            'scheduleType': flexible ? 'timesPerWeek' : 'daily',
            'scheduled': false,
            'completed': false,
            'skipped': false,
            'progress': null,
            'target': null,
          }
        ],
    'streakSnapshot': null,
    if (flexible) ...{
      'completedRaw': completedRaw,
      'scheduledQuota': scheduledQuota,
      'rawRatio': rawRatio,
      'cappedRatio': cappedRatio,
      'dataQuality': dataQuality,
    },
  };
  return {
    'schemaVersion': 1,
    'metricsPolicyVersion': policy,
    'contentVersion': 1,
    'report': report,
    'days': [
      {
        'date': '2026-09-01',
        'scheduledCount': 0,
        'completedCount': 0,
        'skippedCount': 0,
        'completionRate': null,
        'state': 'noPlan',
      }
    ],
    'habits': [habit],
    'recommendations': <Map<String, dynamic>>[],
  };
}

Map<String, dynamic> _history({required int policy, String? quality}) => {
      'reportId': policy == 1 ? 'legacy' : 'v2',
      'weekStartDate': policy == 1 ? '2026-08-24' : '2026-08-31',
      'weekEndDate': policy == 1 ? '2026-08-30' : '2026-09-06',
      'status': 'final',
      'completionRate': policy == 1 ? 1.0 : 1.0,
      'completedCount': policy == 1 ? 3 : 3,
      'scheduledCount': 3,
      if (policy >= 2) ...{
        'metricsPolicyVersion': 2,
        'completedRaw': 4,
        'scheduledQuota': 3,
        'rawRatio': 4 / 3,
        'cappedRatio': 1.0,
        'dataQuality': quality ?? 'verified',
      },
      'firstPartialWeek': false,
      'refreshedAt': null,
      'finalizedAt': null,
    };

void main() {
  test('legacy policy falls back without inventing historical over-target data',
      () {
    final report = mapRemoteWeeklyReport(
      RemoteWeeklyReport.fromJson(_payload(
        policy: 1,
        completedCount: 3,
        completedRaw: null,
        scheduledQuota: null,
        rawRatio: null,
        cappedRatio: null,
        dataQuality: null,
      )),
    );

    expect(report.summary.completedRaw, 3);
    expect(report.summary.scheduledQuota, 3);
    expect(report.summary.rawRatio, 1);
    expect(report.summary.cappedRatio, 1);
    expect(report.summary.dataQuality, WeeklyReportDataQuality.legacy);
    expect(report.habits.single.dataQuality, WeeklyReportDataQuality.legacy);
  });

  test('v2 preserves 2/3 and 4/3 independently from legacy fields', () {
    final twoOfThree = mapRemoteWeeklyReport(RemoteWeeklyReport.fromJson(
      _payload(
        completedCount: 2,
        completedRaw: 2,
        scheduledQuota: 3,
        rawRatio: 2 / 3,
        cappedRatio: 2 / 3,
      ),
    ));
    final fourOfThree = mapRemoteWeeklyReport(RemoteWeeklyReport.fromJson(
      _payload(),
    ));

    expect(twoOfThree.summary.completedRaw, 2);
    expect(twoOfThree.summary.scheduledQuota, 3);
    expect(twoOfThree.summary.rawRatio, closeTo(2 / 3, 0.000001));
    expect(twoOfThree.summary.cappedRatio, closeTo(2 / 3, 0.000001));
    expect(fourOfThree.summary.completedRaw, 4);
    expect(fourOfThree.summary.completedCount, 3);
    expect(fourOfThree.summary.rawRatio, closeTo(4 / 3, 0.000001));
    expect(fourOfThree.summary.cappedRatio, 1);
  });

  test(
      'v2 preserves timesPerWeek and typed completed, skipped, neutral activity',
      () {
    final report = mapRemoteWeeklyReport(RemoteWeeklyReport.fromJson(
      _payload(
        occurrences: [
          {
            'date': '2026-09-01',
            'scope': 'weeklyQuota',
            'scheduleType': 'timesPerWeek',
            'scheduled': false,
            'completed': true,
            'skipped': false,
            'activity': 'completed',
            'progress': null,
            'target': null,
          },
          {
            'date': '2026-09-02',
            'scope': 'weeklyQuota',
            'scheduleType': 'timesPerWeek',
            'scheduled': false,
            'completed': false,
            'skipped': true,
            'activity': 'skipped',
            'progress': null,
            'target': null,
          },
          {
            'date': '2026-09-03',
            'scope': 'weeklyQuota',
            'scheduleType': 'timesPerWeek',
            'scheduled': false,
            'completed': false,
            'skipped': false,
            'activity': 'neutral',
            'progress': null,
            'target': null,
          },
        ],
      ),
    ));

    expect(report.habits.single.schedule.type, HabitScheduleType.timesPerWeek);
    expect(report.habits.single.schedule.timesPerWeek, 3);
    expect(report.habits.single.occurrences[0].activity,
        HabitOccurrenceActivity.completed);
    expect(report.habits.single.occurrences[1].activity,
        HabitOccurrenceActivity.skipped);
    expect(report.habits.single.occurrences[1].scheduled, isFalse);
    expect(report.habits.single.occurrences[2].activity,
        HabitOccurrenceActivity.neutral);
  });

  test('unknown quality is safe and unknown policy is rejected', () {
    final unknownQuality = _payload(dataQuality: 'future_quality');
    final qualityReport =
        mapRemoteWeeklyReport(RemoteWeeklyReport.fromJson(unknownQuality));
    expect(qualityReport.summary.dataQuality,
        WeeklyReportDataQuality.unverifiable);

    final unknownPolicy = _payload()..['metricsPolicyVersion'] = 999;
    (unknownPolicy['report'] as Map<String, dynamic>)['metricsPolicyVersion'] =
        999;
    expect(() => RemoteWeeklyReport.fromJson(unknownPolicy),
        throwsA(isA<WeeklyReportPayloadException>()));

    expect(() => RemoteWeeklyReport.fromJson(_payload(cappedRatio: 1.1)),
        throwsA(isA<WeeklyReportPayloadException>()));
  });

  test('unverifiable v2 may omit exact metrics without inventing values', () {
    final report = mapRemoteWeeklyReport(RemoteWeeklyReport.fromJson(_payload(
      completedRaw: null,
      scheduledQuota: null,
      rawRatio: null,
      cappedRatio: null,
      dataQuality: 'unverifiable',
    )));
    expect(report.summary.dataQuality, WeeklyReportDataQuality.unverifiable);
    expect(report.summary.completedRaw, isNull);
    expect(report.summary.rawRatio, isNull);
    expect(report.summary.cappedRatio, isNull);
  });

  test('history maps legacy and v2 versions in one page', () {
    final items = [
      RemoteWeeklyReportHistoryItem(_history(policy: 1)).toDomain(),
      RemoteWeeklyReportHistoryItem(_history(policy: 2)).toDomain(),
    ];
    expect(items[0].dataQuality, WeeklyReportDataQuality.legacy);
    expect(items[0].completedRaw, 3);
    expect(items[1].dataQuality, WeeklyReportDataQuality.verified);
    expect(items[1].metricsPolicyVersion, 2);
    expect(items[1].completedRaw, 4);
    expect(items[1].rawRatio, closeTo(4 / 3, 0.000001));
  });

  test('repository history preserves mixed policy metadata', () async {
    final remote = _FakeRemote()
      ..historyValues = [
        RemoteWeeklyReportHistoryItem(_history(policy: 1)),
        RemoteWeeklyReportHistoryItem(_history(policy: 2)),
      ];
    final repository = SupabaseWeeklyReportRepository(
      remote: remote,
      cache: InMemoryWeeklyReportCache(),
      scopeProvider: () => (userId: 'u1', epoch: 1),
    );

    final page = await repository.getHistory();
    expect(page.items.map((item) => item.metricsPolicyVersion), [1, 2]);
    expect(page.items.last.completedRaw, 4);
  });

  test('SharedPreferences cache round-trips v2 raw/capped/activity fields',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = SharedPreferencesWeeklyReportCache(preferences);
    final payload = RemoteWeeklyReport.fromJson(_payload());

    await cache.write('u1', 'r1', payload,
        cachedAt: DateTime.utc(2026, 9, 1, 12));
    final cached = await cache.read('u1', 'r1');
    final report = mapRemoteWeeklyReport(cached!.payload);

    expect(report.summary.completedRaw, 4);
    expect(report.summary.scheduledQuota, 3);
    expect(report.summary.rawRatio, closeTo(4 / 3, 0.000001));
    expect(report.summary.cappedRatio, 1);
    expect(report.summary.dataQuality, WeeklyReportDataQuality.verified);
    expect(report.habits.single.occurrences.single.activity,
        HabitOccurrenceActivity.neutral);
  });

  test('legacy cache remains readable offline with legacy quality', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = SharedPreferencesWeeklyReportCache(preferences);
    final payload = RemoteWeeklyReport.fromJson(_payload(
      policy: 1,
      completedCount: 3,
      completedRaw: null,
      scheduledQuota: null,
      rawRatio: null,
      cappedRatio: null,
      dataQuality: null,
    ));

    await cache.write('u1', 'legacy', payload,
        cachedAt: DateTime.utc(2026, 8, 31));
    final cached = await cache.read('u1', 'legacy');
    final report = mapRemoteWeeklyReport(cached!.payload);
    expect(report.status, WeeklyReportStatus.provisional);
    expect(report.summary.dataQuality, WeeklyReportDataQuality.legacy);
    expect(report.summary.completedRaw, 3);
  });

  test('repository latest v2 and by-id legacy both map correctly', () async {
    final remote = _FakeRemote(
      latestValue: RemoteWeeklyReport.fromJson(_payload()),
      byIdValue: RemoteWeeklyReport.fromJson(
          _payload(policy: 1, reportId: 'legacy-report')),
    );
    final repository = SupabaseWeeklyReportRepository(
      remote: remote,
      cache: InMemoryWeeklyReportCache(),
      scopeProvider: () => (userId: 'u1', epoch: 1),
    );

    final latest = await repository.getLatest();
    final byId = await repository.getById('legacy-report');
    expect(latest!.report.summary.completedRaw, 4);
    expect(byId.report.summary.dataQuality, WeeklyReportDataQuality.legacy);
  });

  test('provisional v1 cache can refresh to v2 and final v1 stays immutable',
      () async {
    final cache = InMemoryWeeklyReportCache();
    final remote = _FakeRemote(
      byIdValue: RemoteWeeklyReport.fromJson(_payload(
        policy: 1,
        completedCount: 3,
        completedRaw: null,
        scheduledQuota: null,
        rawRatio: null,
        cappedRatio: null,
        dataQuality: null,
        refreshedAt: '2026-09-01T10:00:00Z',
      )),
    );
    final repository = SupabaseWeeklyReportRepository(
      remote: remote,
      cache: cache,
      scopeProvider: () => (userId: 'u1', epoch: 1),
    );

    await repository.getById('r1');
    remote.refreshValue = RemoteWeeklyReport.fromJson(_payload(
      completedCount: 3,
      refreshedAt: '2026-09-02T10:00:00Z',
    ));
    final refreshed =
        await repository.refreshProvisional(DateTime(2026, 8, 31));
    expect(refreshed.report.summary.completedRaw, 4);
    expect((await cache.read('u1', 'r1'))!.payload.metricsPolicyVersion, 2);

    remote.byIdValue = RemoteWeeklyReport.fromJson(_payload(
      status: 'final',
      policy: 1,
      completedCount: 3,
      completedRaw: null,
      scheduledQuota: null,
      rawRatio: null,
      cappedRatio: null,
      dataQuality: null,
    ));
    await repository.getById('r1');
    remote.byIdValue = RemoteWeeklyReport.fromJson(_payload(
      status: 'final',
      completedCount: 3,
      refreshedAt: '2026-09-08T10:00:00Z',
    ));
    final immutable = await repository.getById('r1');
    expect(immutable.report.status, WeeklyReportStatus.finalized);
    expect(immutable.report.metricsPolicyVersion, 1);
    expect(
        immutable.report.summary.dataQuality, WeeklyReportDataQuality.legacy);
  });
}

class _FakeRemote implements WeeklyReportRemoteDataSource {
  _FakeRemote({this.latestValue, this.byIdValue});

  RemoteWeeklyReport? latestValue;
  RemoteWeeklyReport? byIdValue;
  RemoteWeeklyReport? refreshValue;
  List<RemoteWeeklyReportHistoryItem> historyValues = const [];

  @override
  Future<RemoteWeeklyReport?> getLatest() async => latestValue;

  @override
  Future<RemoteWeeklyReport?> getById(String reportId) async => byIdValue;

  @override
  Future<RemoteWeeklyReport?> getByWeekStart(DateTime weekStartDate) async =>
      byIdValue;

  @override
  Future<List<RemoteWeeklyReportHistoryItem>> getHistory(
          {DateTime? beforeWeekStart, required int limit}) async =>
      historyValues;

  @override
  Future<RemoteWeeklyReport?> refresh(DateTime weekStartDate) async =>
      refreshValue;

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {}
}
