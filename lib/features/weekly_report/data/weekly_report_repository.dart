import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/rutio_supabase_client.dart';
import '../domain/weekly_report.dart';
import '../../habits/domain/metrics/weekly_report_week.dart';
import 'remote/remote_weekly_report.dart';
import 'remote/weekly_report_mapper.dart';

typedef WeeklyReportScope = ({String userId, int epoch});
typedef WeeklyReportScopeProvider = WeeklyReportScope? Function();
const int weeklyReportCacheSchemaVersion = 1;

sealed class WeeklyReportError implements Exception {
  const WeeklyReportError(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}

class WeeklyReportNotFound extends WeeklyReportError {
  const WeeklyReportNotFound() : super('Weekly Report not generated yet.');
}

class WeeklyReportUnavailable extends WeeklyReportError {
  const WeeklyReportUnavailable([Object? cause])
      : super('Weekly Report is unavailable offline.', cause: cause);
}

class WeeklyReportUnauthorized extends WeeklyReportError {
  const WeeklyReportUnauthorized([Object? cause])
      : super('Weekly Report access is unauthorized.', cause: cause);
}

class WeeklyReportUnsupportedSchema extends WeeklyReportError {
  const WeeklyReportUnsupportedSchema([Object? cause])
      : super('Weekly Report schema is not supported.', cause: cause);
}

class WeeklyReportMalformedPayload extends WeeklyReportError {
  const WeeklyReportMalformedPayload([Object? cause])
      : super('Weekly Report payload is malformed.', cause: cause);
}

class WeeklyReportNetworkFailure extends WeeklyReportError {
  const WeeklyReportNetworkFailure([Object? cause])
      : super('Weekly Report could not be loaded.', cause: cause);
}

class WeeklyReportRefreshRejected extends WeeklyReportError {
  const WeeklyReportRefreshRejected([Object? cause])
      : super('Weekly Report refresh was rejected.', cause: cause);
}

class WeeklyReportActivationFailure extends WeeklyReportError {
  const WeeklyReportActivationFailure([Object? cause])
      : super('Weekly Report activation failed.', cause: cause);
}

class WeeklyReportStaleScope extends WeeklyReportError {
  const WeeklyReportStaleScope()
      : super('Discarded stale Weekly Report result.');
}

abstract interface class WeeklyReportRemoteDataSource {
  Future<RemoteWeeklyReport?> getLatest();
  Future<RemoteWeeklyReport?> getById(String reportId);
  Future<List<RemoteWeeklyReportHistoryItem>> getHistory(
      {DateTime? beforeWeekStart, required int limit});
  Future<RemoteWeeklyReport?> refresh(DateTime weekStartDate);
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  });
}

class RemoteWeeklyReportHistoryItem {
  const RemoteWeeklyReportHistoryItem(this.json);
  final Map<String, dynamic> json;
  WeeklyReportHistoryItem toDomain() {
    DateTime date(String k) => DateTime.parse(json[k] as String).toLocal();
    final status = json['status'] as String;
    if (status != 'provisional' && status != 'final')
      throw const WeeklyReportMalformedPayload();
    final rate = json['completionRate'];
    return WeeklyReportHistoryItem(
        reportId: json['reportId'] as String,
        week: WeeklyReportWeekFactory.fromDates(
            date('weekStartDate'), date('weekEndDate')),
        status: status == 'final'
            ? WeeklyReportStatus.finalized
            : WeeklyReportStatus.provisional,
        completionRate: (rate as num?)?.toDouble(),
        completedCount: (json['completedCount'] as num).toInt(),
        scheduledCount: (json['scheduledCount'] as num).toInt(),
        firstPartialWeek: json['firstPartialWeek'] as bool,
        refreshedAt: json['refreshedAt'] == null
            ? null
            : DateTime.parse(json['refreshedAt'] as String).toUtc(),
        finalizedAt: json['finalizedAt'] == null
            ? null
            : DateTime.parse(json['finalizedAt'] as String).toUtc());
  }
}

// Kept local to avoid exposing transport date construction in the domain port.
class WeeklyReportWeekFactory {
  static WeeklyReportWeek fromDates(DateTime start, DateTime end) =>
      WeeklyReportWeek(weekStartDate: start, weekEndDate: end);
}

class SupabaseWeeklyReportRemoteDataSource
    implements WeeklyReportRemoteDataSource {
  SupabaseWeeklyReportRemoteDataSource(
      {SupabaseClient? client, this.supportedSchemaVersion = 1})
      : _client = client ?? RutioSupabaseClient.instance;
  final SupabaseClient _client;
  final int supportedSchemaVersion;
  Future<RemoteWeeklyReport?> _parse(Object? raw) async {
    if (raw == null) return null;
    try {
      return RemoteWeeklyReport.fromJson(raw,
          supportedSchemaVersion: supportedSchemaVersion);
    } on WeeklyReportPayloadException catch (e) {
      if (e.message.startsWith('Unsupported'))
        throw WeeklyReportUnsupportedSchema(e);
      throw WeeklyReportMalformedPayload(e);
    }
  }

  @override
  Future<RemoteWeeklyReport?> getLatest() async =>
      _parse(await _client.rpc('get_my_latest_weekly_report'));
  @override
  Future<RemoteWeeklyReport?> getById(String reportId) async =>
      _parse(await _client
          .rpc('get_my_weekly_report', params: {'p_report_id': reportId}));
  @override
  Future<List<RemoteWeeklyReportHistoryItem>> getHistory(
      {DateTime? beforeWeekStart, required int limit}) async {
    final raw = await _client.rpc('list_my_weekly_reports', params: {
      'p_before_week_start':
          beforeWeekStart == null ? null : _isoDate(beforeWeekStart),
      'p_limit': limit
    });
    if (raw is! List) throw const WeeklyReportMalformedPayload();
    return raw
        .map((e) => RemoteWeeklyReportHistoryItem(
            Map<String, dynamic>.from((e as Map).cast<String, dynamic>())))
        .toList(growable: false);
  }

  @override
  Future<RemoteWeeklyReport?> refresh(DateTime weekStartDate) async =>
      _parse(await _client.rpc('refresh_my_weekly_report',
          params: {'p_week_start_date': _isoDate(weekStartDate)}));

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {
    await _client.rpc(
      'activate_weekly_report',
      params: {
        'p_activation_local_date': _isoDate(activationLocalDate),
        'p_timezone_name': timezoneName,
      },
    );
  }
}

abstract interface class WeeklyReportCache {
  Future<WeeklyReportCacheEntry?> read(String scopeKey, String reportId);
  Future<void> write(
      String scopeKey, String reportId, RemoteWeeklyReport payload,
      {required DateTime cachedAt});
}

class WeeklyReportCacheEntry {
  const WeeklyReportCacheEntry(this.payload, this.cachedAt);
  final RemoteWeeklyReport payload;
  final DateTime cachedAt;
}

class SharedPreferencesWeeklyReportCache implements WeeklyReportCache {
  SharedPreferencesWeeklyReportCache(this._preferences);
  final SharedPreferences _preferences;
  String _key(String scope, String id) =>
      'weekly_report_v1_${Uri.encodeComponent(scope)}_${Uri.encodeComponent(id)}';
  @override
  Future<WeeklyReportCacheEntry?> read(String scopeKey, String reportId) async {
    final raw = _preferences.getString(_key(scopeKey, reportId));
    if (raw == null) return null;
    try {
      final m = jsonDecode(raw);
      if (m is! Map ||
          m['cacheSchemaVersion'] != weeklyReportCacheSchemaVersion) {
        await _preferences.remove(_key(scopeKey, reportId));
        return null;
      }
      return WeeklyReportCacheEntry(RemoteWeeklyReport.fromJson(m['payload']),
          DateTime.parse(m['cachedAt'] as String).toUtc());
    } catch (_) {
      await _preferences.remove(_key(scopeKey, reportId));
      return null;
    }
  }

  @override
  Future<void> write(
      String scopeKey, String reportId, RemoteWeeklyReport payload,
      {required DateTime cachedAt}) async {
    final existing = await read(scopeKey, reportId);
    if (existing != null &&
        reportId != 'latest' &&
        _cacheMustKeep(existing.payload, payload)) return;
    await _preferences.setString(
        _key(scopeKey, reportId),
        jsonEncode({
          'cacheSchemaVersion': weeklyReportCacheSchemaVersion,
          'cachedAt': cachedAt.toUtc().toIso8601String(),
          'payload': _payloadJson(payload)
        }));
  }

  bool _cacheMustKeep(RemoteWeeklyReport old, RemoteWeeklyReport next) {
    if (old.report.status == 'final') return true;
    return old.report.status == 'provisional' &&
        next.report.status == 'provisional' &&
        old.report.refreshedAt != null &&
        next.report.refreshedAt != null &&
        !next.report.refreshedAt!.isAfter(old.report.refreshedAt!);
  }
}

class InMemoryWeeklyReportCache implements WeeklyReportCache {
  final Map<String, WeeklyReportCacheEntry> _entries = {};
  @override
  Future<WeeklyReportCacheEntry?> read(String scope, String id) async =>
      _entries['$scope/$id'];
  @override
  Future<void> write(String scope, String id, RemoteWeeklyReport payload,
      {required DateTime cachedAt}) async {
    final old = _entries['$scope/$id'];
    if (old != null && id != 'latest' && old.payload.report.status == 'final') {
      return;
    }
    if (old != null &&
        id != 'latest' &&
        old.payload.report.status == 'provisional' &&
        payload.report.status == 'provisional' &&
        old.payload.report.refreshedAt != null &&
        payload.report.refreshedAt != null &&
        !payload.report.refreshedAt!.isAfter(old.payload.report.refreshedAt!))
      return;
    _entries['$scope/$id'] = WeeklyReportCacheEntry(payload, cachedAt);
  }
}

class SupabaseWeeklyReportRepository implements WeeklyReportRepository {
  SupabaseWeeklyReportRepository(
      {required this.remote,
      required this.cache,
      required this.scopeProvider,
      DateTime Function()? now})
      : _now = now ?? DateTime.now;
  final WeeklyReportRemoteDataSource remote;
  final WeeklyReportCache cache;
  final WeeklyReportScopeProvider scopeProvider;
  final DateTime Function() _now;
  @override
  Future<WeeklyReportSnapshot?> getLatest() async {
    final scope = _scope();
    final cached = await _cachedLatest(scope);
    try {
      final payload = await remote.getLatest();
      if (!_isCurrent(scope)) throw const WeeklyReportStaleScope();
      if (payload == null) return null;
      await _save(scope, payload);
      return WeeklyReportSnapshot(
          report: mapRemoteWeeklyReport(payload),
          source: WeeklyReportDataSource.remoteFresh,
          cachedAt: null,
          isStale: false);
    } on WeeklyReportError {
      rethrow;
    } catch (e) {
      if (cached != null) return cached;
      throw _network(e);
    }
  }

  @override
  Future<WeeklyReportSnapshot> getById(String reportId) async {
    final scope = _scope();
    final cached = await cache.read(scope.userId, reportId);
    try {
      final payload = await remote.getById(reportId);
      if (!_isCurrent(scope)) throw const WeeklyReportStaleScope();
      if (payload == null) throw const WeeklyReportNotFound();
      await _save(scope, payload);
      return _fresh(payload);
    } catch (e) {
      if (e is WeeklyReportError &&
          e is! WeeklyReportNetworkFailure &&
          e is! WeeklyReportNotFound) rethrow;
      if (cached != null) return _cached(cached);
      if (e is WeeklyReportNotFound) rethrow;
      throw _network(e);
    }
  }

  @override
  Future<WeeklyReportHistoryPage> getHistory(
      {DateTime? beforeWeekStart, int limit = 20}) async {
    final scope = _scope();
    try {
      final effectiveLimit = limit.clamp(1, 50);
      final items = await remote.getHistory(
          beforeWeekStart: beforeWeekStart, limit: effectiveLimit);
      if (!_isCurrent(scope)) throw const WeeklyReportStaleScope();
      final domains = items.map((e) => e.toDomain()).toList(growable: false);
      return WeeklyReportHistoryPage(
          items: domains,
          nextBeforeWeekStart: domains.length == effectiveLimit
              ? domains.last.week.weekStartDate
              : null);
    } catch (e) {
      if (e is WeeklyReportError) rethrow;
      throw _network(e);
    }
  }

  @override
  Future<WeeklyReportSnapshot> refreshProvisional(
      DateTime weekStartDate) async {
    final scope = _scope();
    try {
      final payload = await remote.refresh(weekStartDate);
      if (!_isCurrent(scope)) throw const WeeklyReportStaleScope();
      if (payload == null) throw const WeeklyReportNotFound();
      await _save(scope, payload);
      return _fresh(payload);
    } on WeeklyReportError {
      rethrow;
    } catch (e) {
      throw WeeklyReportRefreshRejected(e);
    }
  }

  @override
  Future<void> activate({
    required DateTime activationLocalDate,
    required String timezoneName,
  }) async {
    final scope = _scope();
    try {
      await remote.activate(
        activationLocalDate: activationLocalDate,
        timezoneName: timezoneName,
      );
      if (!_isCurrent(scope)) throw const WeeklyReportStaleScope();
    } on WeeklyReportError {
      rethrow;
    } catch (error) {
      throw WeeklyReportActivationFailure(error);
    }
  }

  WeeklyReportScope _scope() =>
      scopeProvider() ?? (throw const WeeklyReportUnauthorized());
  bool _isCurrent(WeeklyReportScope s) =>
      scopeProvider()?.userId == s.userId && scopeProvider()?.epoch == s.epoch;
  Future<WeeklyReportSnapshot?> _cachedLatest(WeeklyReportScope s) async {
    final entries = <WeeklyReportCacheEntry>[];
    for (final id in const ['latest']) {
      final e = await cache.read(s.userId, id);
      if (e != null && e.payload.report.userId == s.userId) entries.add(e);
    }
    if (entries.isEmpty) return null;
    return _cached(entries.single);
  }

  Future<void> _save(WeeklyReportScope s, RemoteWeeklyReport p) async {
    if (!_isCurrent(s)) throw const WeeklyReportStaleScope();
    if (p.report.userId != s.userId) {
      throw const WeeklyReportUnauthorized();
    }
    final id = p.report.id;
    final old = await cache.read(s.userId, id);
    if (old != null && id != 'latest' && old.payload.report.status == 'final') {
      return;
    }
    if (old != null &&
        old.payload.report.status == 'provisional' &&
        p.report.status == 'provisional' &&
        old.payload.report.refreshedAt != null &&
        p.report.refreshedAt != null &&
        !p.report.refreshedAt!.isAfter(old.payload.report.refreshedAt!)) {
      return;
    }
    await cache.write(s.userId, id, p, cachedAt: _now().toUtc());
    await cache.write(s.userId, 'latest', p, cachedAt: _now().toUtc());
  }

  WeeklyReportSnapshot _fresh(RemoteWeeklyReport p) => WeeklyReportSnapshot(
      report: mapRemoteWeeklyReport(p),
      source: WeeklyReportDataSource.remoteFresh,
      cachedAt: null,
      isStale: false);
  WeeklyReportSnapshot _cached(WeeklyReportCacheEntry e) =>
      WeeklyReportSnapshot(
          report: mapRemoteWeeklyReport(e.payload),
          source: e.payload.report.status == 'final'
              ? WeeklyReportDataSource.cachedFinal
              : WeeklyReportDataSource.cachedProvisional,
          cachedAt: e.cachedAt,
          isStale: true);
  WeeklyReportNetworkFailure _network(Object e) =>
      WeeklyReportNetworkFailure(e);
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
Map<String, dynamic> _payloadJson(RemoteWeeklyReport p) => {
      'schemaVersion': p.schemaVersion,
      'metricsPolicyVersion': p.metricsPolicyVersion,
      'contentVersion': p.contentVersion,
      'report': {
        'id': p.report.id,
        'userId': p.report.userId,
        'weekStartDate': p.report.weekStartDate,
        'weekEndDate': p.report.weekEndDate,
        'timezoneId': p.report.timezoneId,
        'status': p.report.status,
        'firstPartialWeek': p.report.firstPartialWeek,
        'scheduledCount': p.report.scheduledCount,
        'completedCount': p.report.completedCount,
        'completionRate': p.report.completionRate,
        'bestDay': p.report.bestDay,
        'trendKind': p.report.trendKind,
        'trendDelta': p.report.trendDelta,
        'comparabilityReason': p.report.comparabilityReason,
        'schemaVersion': p.report.schemaVersion,
        'metricsPolicyVersion': p.report.metricsPolicyVersion,
        'contentVersion': p.report.contentVersion,
        'messageKeys': p.report.messageKeys,
        'generatedAt': p.report.generatedAt?.toIso8601String(),
        'refreshedAt': p.report.refreshedAt?.toIso8601String(),
        'finalizedAt': p.report.finalizedAt?.toIso8601String(),
      },
      'days': p.days
          .map((d) => {
                'date': d.date.substring(0, 10),
                'scheduledCount': d.scheduledCount,
                'completedCount': d.completedCount,
                'skippedCount': d.skippedCount,
                'completionRate': d.completionRate,
                'state': d.state
              })
          .toList(),
      'habits': p.habits
          .map((h) => {
                'habitId': h.habitId,
                'name': h.name,
                'emoji': h.emoji,
                'type': h.type,
                'target': h.target,
                'familyId': h.familyId,
                'schedule': h.schedule,
                'scheduledCount': h.scheduledCount,
                'completedCount': h.completedCount,
                'skippedCount': h.skippedCount,
                'completionRate': h.completionRate,
                'occurrences': h.occurrences,
                'streakSnapshot': h.streakSnapshot
              })
          .toList(),
      'recommendations': p.recommendations
          .map((r) => {
                'type': r.type,
                'reason': r.reason,
                'habitId': r.habitId,
                'habitName': r.habitName,
                'emoji': r.emoji,
                'currentConfig': r.currentConfig,
                'proposedPatch': r.proposedPatch,
                'policyVersion': r.policyVersion,
              })
          .toList(),
    };
