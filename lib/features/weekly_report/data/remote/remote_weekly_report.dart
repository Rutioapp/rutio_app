import '../../domain/weekly_report.dart';

const int supportedWeeklyReportMetricsPolicyVersion = 2;

class WeeklyReportPayloadException implements FormatException {
  const WeeklyReportPayloadException(this.message, [this.source]);
  @override
  final String message;
  @override
  final Object? source;
  @override
  int? get offset => null;
  @override
  String toString() => 'WeeklyReportPayloadException: $message';
}

class RemoteWeeklyReport {
  const RemoteWeeklyReport(
      {required this.schemaVersion,
      required this.metricsPolicyVersion,
      required this.contentVersion,
      required this.report,
      required this.days,
      required this.habits,
      required this.recommendations});
  final int schemaVersion;
  final int metricsPolicyVersion;
  final int contentVersion;
  final RemoteWeeklyReportHeader report;
  final List<RemoteWeeklyReportDay> days;
  final List<RemoteWeeklyReportHabit> habits;
  final List<RemoteWeeklyReportRecommendation> recommendations;

  factory RemoteWeeklyReport.fromJson(Object? value,
      {int supportedSchemaVersion = 1,
      int supportedMetricsPolicyVersion =
          supportedWeeklyReportMetricsPolicyVersion}) {
    final map = _object(value, 'payload');
    final schema = _positiveInt(map['schemaVersion'], 'schemaVersion');
    if (schema > supportedSchemaVersion)
      throw WeeklyReportPayloadException('Unsupported schemaVersion $schema.');
    final metricsPolicy =
        _positiveInt(map['metricsPolicyVersion'], 'metricsPolicyVersion');
    if (metricsPolicy > supportedMetricsPolicyVersion) {
      throw WeeklyReportPayloadException(
          'Unsupported metricsPolicyVersion $metricsPolicy.');
    }
    final report = _object(map['report'], 'report');
    final header = RemoteWeeklyReportHeader.fromJson(report);
    final days = _array(map['days'], 'days')
        .map((e) => RemoteWeeklyReportDay.fromJson(e))
        .toList(growable: false);
    final habits = _array(map['habits'], 'habits')
        .map((e) => RemoteWeeklyReportHabit.fromJson(e,
            metricsPolicyVersion: metricsPolicy))
        .toList(growable: false);
    final recommendations =
        _array(map['recommendations'] ?? const [], 'recommendations')
            .map((e) => RemoteWeeklyReportRecommendation.fromJson(e))
            .toList(growable: false);
    if (header.metricsPolicyVersion != metricsPolicy) {
      throw WeeklyReportPayloadException(
          'metricsPolicyVersion does not match report.metricsPolicyVersion.');
    }
    return RemoteWeeklyReport(
        schemaVersion: schema,
        metricsPolicyVersion: metricsPolicy,
        contentVersion: _positiveInt(map['contentVersion'], 'contentVersion'),
        report: header,
        days: days,
        habits: habits,
        recommendations: recommendations);
  }
}

class RemoteWeeklyReportHeader {
  const RemoteWeeklyReportHeader(
      {required this.id,
      required this.userId,
      required this.weekStartDate,
      required this.weekEndDate,
      required this.timezoneId,
      required this.status,
      required this.firstPartialWeek,
      required this.scheduledCount,
      required this.completedCount,
      required this.completionRate,
      this.completedRaw,
      this.scheduledQuota,
      this.rawRatio,
      this.cappedRatio,
      this.dataQuality,
      required this.bestDay,
      required this.trendKind,
      required this.trendDelta,
      required this.comparabilityReason,
      required this.schemaVersion,
      required this.metricsPolicyVersion,
      required this.contentVersion,
      required this.messageKeys,
      required this.generatedAt,
      required this.refreshedAt,
      required this.finalizedAt});
  final String id,
      userId,
      weekStartDate,
      weekEndDate,
      timezoneId,
      status,
      trendKind;
  final bool firstPartialWeek;
  final int scheduledCount,
      completedCount,
      schemaVersion,
      metricsPolicyVersion,
      contentVersion;
  final double? completionRate, trendDelta;
  final int? completedRaw, scheduledQuota;
  final double? rawRatio, cappedRatio;
  final WeeklyReportDataQuality? dataQuality;
  final String? bestDay, comparabilityReason;
  final List<String> messageKeys;
  final DateTime? generatedAt, refreshedAt, finalizedAt;
  factory RemoteWeeklyReportHeader.fromJson(Map<String, dynamic> m) {
    final policy =
        _positiveInt(m['metricsPolicyVersion'], 'report.metricsPolicyVersion');
    final header = RemoteWeeklyReportHeader(
        id: _id(m['id'], 'report.id'),
        userId: _id(m['userId'], 'report.userId'),
        weekStartDate: _dateString(m['weekStartDate'], 'weekStartDate'),
        weekEndDate: _dateString(m['weekEndDate'], 'weekEndDate'),
        timezoneId: _string(m['timezoneId'], 'timezoneId'),
        status: _enum(m['status'], const ['provisional', 'final'], 'status'),
        trendKind: _enum(
            m['trendKind'],
            const ['improved', 'stable', 'declined', 'unavailable'],
            'trendKind'),
        firstPartialWeek: _bool(m['firstPartialWeek'], 'firstPartialWeek'),
        scheduledCount: _nonNegativeInt(m['scheduledCount'], 'scheduledCount'),
        completedCount: _nonNegativeInt(m['completedCount'], 'completedCount'),
        completionRate: _rate(m['completionRate'], 'completionRate'),
        bestDay:
            m['bestDay'] == null ? null : _dateString(m['bestDay'], 'bestDay'),
        trendDelta: m['trendDelta'] == null
            ? null
            : _number(m['trendDelta'], 'trendDelta').toDouble(),
        comparabilityReason: m['comparabilityReason'] as String?,
        schemaVersion: _positiveInt(m['schemaVersion'], 'report.schemaVersion'),
        metricsPolicyVersion: policy,
        contentVersion:
            _positiveInt(m['contentVersion'], 'report.contentVersion'),
        completedRaw: policy >= 2
            ? _optionalNonNegativeInt(m['completedRaw'], 'report.completedRaw')
            : null,
        scheduledQuota: policy >= 2
            ? _optionalNonNegativeInt(
                m['scheduledQuota'], 'report.scheduledQuota')
            : null,
        rawRatio:
            policy >= 2 ? _rawRatio(m['rawRatio'], 'report.rawRatio') : null,
        cappedRatio:
            policy >= 2 ? _rate(m['cappedRatio'], 'report.cappedRatio') : null,
        dataQuality: policy >= 2
            ? _dataQuality(m['dataQuality'], 'report.dataQuality')
            : null,
        // Older payloads predate contextual copy; absence is safe and means
        // the Flutter resolver will use its neutral fallback.
        messageKeys: _stringArray(m['messageKeys'] ?? const [], 'messageKeys'),
        generatedAt: _instant(m['generatedAt'], 'generatedAt'),
        refreshedAt: _instant(m['refreshedAt'], 'refreshedAt'),
        finalizedAt: _instant(m['finalizedAt'], 'finalizedAt'));
    _validateMetricCoherence(
      policy: policy,
      completedRaw: header.completedRaw,
      scheduledQuota: header.scheduledQuota,
      rawRatio: header.rawRatio,
      cappedRatio: header.cappedRatio,
      field: 'report',
    );
    return header;
  }
}

class RemoteWeeklyReportDay {
  const RemoteWeeklyReportDay(
      {required this.date,
      required this.scheduledCount,
      required this.completedCount,
      required this.skippedCount,
      required this.completionRate,
      required this.state});
  final String date, state;
  final int scheduledCount, completedCount, skippedCount;
  final double? completionRate;
  factory RemoteWeeklyReportDay.fromJson(Object? value) {
    final m = _object(value, 'day');
    return RemoteWeeklyReportDay(
        date: _dateString(m['date'], 'day.date'),
        scheduledCount:
            _nonNegativeInt(m['scheduledCount'], 'day.scheduledCount'),
        completedCount:
            _nonNegativeInt(m['completedCount'], 'day.completedCount'),
        skippedCount: _nonNegativeInt(m['skippedCount'], 'day.skippedCount'),
        completionRate: _rate(m['completionRate'], 'day.completionRate'),
        state: _enum(
            m['state'],
            const [
              'noPlan',
              'scheduledIncomplete',
              'partial',
              'completed',
              'skipped'
            ],
            'day.state'));
  }
}

class RemoteWeeklyReportHabit {
  const RemoteWeeklyReportHabit(
      {required this.habitId,
      required this.name,
      required this.emoji,
      required this.type,
      required this.target,
      required this.familyId,
      required this.schedule,
      required this.scheduledCount,
      required this.completedCount,
      required this.skippedCount,
      required this.completionRate,
      this.completedRaw,
      this.scheduledQuota,
      this.rawRatio,
      this.cappedRatio,
      this.dataQuality,
      required this.classification,
      this.observationKey,
      required this.occurrences,
      required this.streakSnapshot});
  final String habitId, name, type;
  final String? emoji, familyId;
  final num? target;
  final Map<String, dynamic> schedule;
  final int scheduledCount, completedCount, skippedCount;
  final double? completionRate;
  final int? completedRaw, scheduledQuota;
  final double? rawRatio, cappedRatio;
  final WeeklyReportDataQuality? dataQuality;
  final String? classification;
  final String? observationKey;
  final List<Map<String, dynamic>> occurrences;
  final Map<String, dynamic>? streakSnapshot;
  factory RemoteWeeklyReportHabit.fromJson(Object? value,
      {int metricsPolicyVersion = 1}) {
    final m = _object(value, 'habit');
    final policy = metricsPolicyVersion;
    final schedule = _object(m['schedule'], 'habit.schedule');
    _validateSchedule(schedule);
    final occurrences = _array(m['occurrences'], 'habit.occurrences')
        .map((e) => _object(e, 'occurrence'))
        .toList(growable: false);
    for (final o in occurrences) {
      _dateString(o['date'], 'occurrence.date');
      _enum(o['scope'], const ['date', 'weeklyQuota'], 'occurrence.scope');
      _enum(
          o['scheduleType'],
          const ['daily', 'weekly', 'once', 'timesPerWeek'],
          'occurrence.scheduleType');
      _bool(o['scheduled'], 'occurrence.scheduled');
      _bool(o['completed'], 'occurrence.completed');
      _bool(o['skipped'], 'occurrence.skipped');
      if (o['activity'] != null) {
        _enum(o['activity'], const ['completed', 'skipped', 'neutral'],
            'occurrence.activity');
      }
      _validateOccurrenceActivity(o);
    }
    final habit = RemoteWeeklyReportHabit(
        habitId: _id(m['habitId'], 'habit.habitId'),
        name: _string(m['name'], 'habit.name'),
        emoji: m['emoji'] as String?,
        type: _enum(m['type'], const ['check', 'count'], 'habit.type'),
        target:
            m['target'] == null ? null : _number(m['target'], 'habit.target'),
        familyId: m['familyId'] as String?,
        schedule: schedule,
        scheduledCount:
            _nonNegativeInt(m['scheduledCount'], 'habit.scheduledCount'),
        completedCount:
            _nonNegativeInt(m['completedCount'], 'habit.completedCount'),
        skippedCount: _nonNegativeInt(m['skippedCount'], 'habit.skippedCount'),
        completionRate: _rate(m['completionRate'], 'habit.completionRate'),
        completedRaw: policy >= 2
            ? _optionalNonNegativeInt(m['completedRaw'], 'habit.completedRaw')
            : null,
        scheduledQuota: policy >= 2
            ? _optionalNonNegativeInt(
                m['scheduledQuota'], 'habit.scheduledQuota')
            : null,
        rawRatio:
            policy >= 2 ? _rawRatio(m['rawRatio'], 'habit.rawRatio') : null,
        cappedRatio:
            policy >= 2 ? _rate(m['cappedRatio'], 'habit.cappedRatio') : null,
        dataQuality: policy >= 2
            ? _dataQuality(m['dataQuality'], 'habit.dataQuality')
            : null,
        classification: m['classification'] == null
            ? null
            : _enum(
                m['classification'],
                const [
                  'highlighted',
                  'stable',
                  'needs_attention',
                  'unavailable'
                ],
                'habit.classification'),
        observationKey: m['observationKey'] as String?,
        occurrences: occurrences,
        streakSnapshot: m['streakSnapshot'] == null
            ? null
            : _object(m['streakSnapshot'], 'streakSnapshot'));
    _validateMetricCoherence(
      policy: policy,
      completedRaw: habit.completedRaw,
      scheduledQuota: habit.scheduledQuota,
      rawRatio: habit.rawRatio,
      cappedRatio: habit.cappedRatio,
      field: 'habit',
    );
    return habit;
  }
}

class RemoteWeeklyReportRecommendation {
  const RemoteWeeklyReportRecommendation(
      {required this.type,
      required this.reason,
      required this.habitId,
      required this.habitName,
      required this.emoji,
      required this.currentConfig,
      required this.proposedPatch,
      required this.policyVersion});
  final String type, reason;
  final String? habitId, habitName, emoji;
  final Map<String, dynamic> currentConfig, proposedPatch;
  final int policyVersion;
  factory RemoteWeeklyReportRecommendation.fromJson(Object? v) {
    final m = _object(v, 'recommendation');
    return RemoteWeeklyReportRecommendation(
        type: _string(m['type'], 'recommendation.type'),
        reason: _string(m['reason'], 'recommendation.reason'),
        habitId: m['habitId'] == null
            ? null
            : _id(m['habitId'], 'recommendation.habitId'),
        habitName: m['habitName'] == null
            ? null
            : _string(m['habitName'], 'recommendation.habitName'),
        emoji: m['emoji'] as String?,
        currentConfig: _object(
            m['currentConfig'] ?? const {}, 'recommendation.currentConfig'),
        proposedPatch: _object(
            m['proposedPatch'] ?? const {}, 'recommendation.proposedPatch'),
        policyVersion: _positiveInt(
            m['policyVersion'] ?? 1, 'recommendation.policyVersion'));
  }
}

Map<String, dynamic> _object(Object? v, String field) => v is Map
    ? Map<String, dynamic>.from(v)
    : (throw WeeklyReportPayloadException('$field must be an object.'));
List<Object?> _array(Object? v, String field) => v is List
    ? v
    : (throw WeeklyReportPayloadException('$field must be an array.'));
String _string(Object? v, String f) => v is String && v.trim().isNotEmpty
    ? v
    : (throw WeeklyReportPayloadException('$f must be a non-empty string.'));
String _id(Object? v, String f) => _string(v, f);
String _enum(Object? v, List<String> allowed, String f) {
  final s = _string(v, f);
  if (!allowed.contains(s))
    throw WeeklyReportPayloadException('Unknown $f: $s.');
  return s;
}

bool _bool(Object? v, String f) =>
    v is bool ? v : (throw WeeklyReportPayloadException('$f must be boolean.'));
num _number(Object? v, String f) => v is num && v.isFinite
    ? v
    : (throw WeeklyReportPayloadException('$f must be numeric.'));
int _positiveInt(Object? v, String f) {
  final n = _number(v, f);
  if (n != n.round() || n < 1)
    throw WeeklyReportPayloadException('$f must be a positive integer.');
  return n.toInt();
}

int _nonNegativeInt(Object? v, String f) {
  final n = _number(v, f);
  if (n != n.round() || n < 0)
    throw WeeklyReportPayloadException('$f must be a non-negative integer.');
  return n.toInt();
}

double? _rate(Object? v, String f) {
  if (v == null) return null;
  final n = _number(v, f).toDouble();
  if (n < 0 || n > 1)
    throw WeeklyReportPayloadException('$f must be between 0 and 1.');
  return n;
}

double? _rawRatio(Object? v, String f) {
  if (v == null) return null;
  final n = _number(v, f).toDouble();
  if (n < 0) {
    throw WeeklyReportPayloadException('$f must be non-negative.');
  }
  return n;
}

int? _optionalNonNegativeInt(Object? v, String f) =>
    v == null ? null : _nonNegativeInt(v, f);

WeeklyReportDataQuality? _dataQuality(Object? v, String f) {
  if (v == null) return null;
  if (v is! String || v.trim().isEmpty) {
    throw WeeklyReportPayloadException('$f must be a string.');
  }
  return WeeklyReportDataQualityX.fromWire(v);
}

void _validateMetricCoherence({
  required int policy,
  required int? completedRaw,
  required int? scheduledQuota,
  required double? rawRatio,
  required double? cappedRatio,
  required String field,
}) {
  if (policy < 2 || scheduledQuota == null || rawRatio == null) return;
  if (scheduledQuota > 0) {
    final expected =
        completedRaw == null ? null : completedRaw.toDouble() / scheduledQuota;
    if (expected != null && (expected - rawRatio).abs() > 0.0001) {
      throw WeeklyReportPayloadException(
          '$field.rawRatio is inconsistent with completedRaw/scheduledQuota.');
    }
  }
  if (cappedRatio != null && (cappedRatio < 0 || cappedRatio > 1)) {
    throw WeeklyReportPayloadException('$field.cappedRatio must be capped.');
  }
}

void _validateSchedule(Map<String, dynamic> schedule) {
  final type = schedule['type'];
  _enum(type, const ['daily', 'weekly', 'once', 'timesPerWeek'],
      'habit.schedule.type');
  if (type == 'timesPerWeek') {
    _nonNegativeInt(schedule['timesPerWeek'], 'habit.schedule.timesPerWeek');
    final times = (schedule['timesPerWeek'] as num).toInt();
    if (times < 1 || times > 6) {
      throw WeeklyReportPayloadException(
          'habit.schedule.timesPerWeek must be between 1 and 6.');
    }
    if (schedule['weekStartsOn'] != null) {
      final start = _nonNegativeInt(
          schedule['weekStartsOn'], 'habit.schedule.weekStartsOn');
      if (start < 1 || start > 7) {
        throw WeeklyReportPayloadException(
            'habit.schedule.weekStartsOn must be between 1 and 7.');
      }
    }
  }
}

void _validateOccurrenceActivity(Map<String, dynamic> occurrence) {
  final activity = occurrence['activity'];
  if (activity == null) return;
  final completed = occurrence['completed'] as bool;
  final skipped = occurrence['skipped'] as bool;
  if (activity == 'completed' && (!completed || skipped) ||
      activity == 'skipped' && (!skipped || completed) ||
      activity == 'neutral' && (completed || skipped)) {
    throw WeeklyReportPayloadException(
        'occurrence.activity is inconsistent with completion state.');
  }
}

String _dateString(Object? v, String f) {
  final s = _string(v, f);
  try {
    DateTime.parse(s);
  } catch (_) {
    throw WeeklyReportPayloadException('$f must be an ISO date.');
  }
  return s;
}

DateTime? _instant(Object? v, String f) {
  if (v == null) return null;
  final s = _string(v, f);
  try {
    return DateTime.parse(s).toUtc();
  } catch (_) {
    throw WeeklyReportPayloadException('$f must be an ISO instant.');
  }
}

List<String> _stringArray(Object? v, String f) {
  final a = _array(v, f);
  return a.map((e) => _string(e, f)).toList(growable: false);
}
