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
      {int supportedSchemaVersion = 1}) {
    final map = _object(value, 'payload');
    final schema = _positiveInt(map['schemaVersion'], 'schemaVersion');
    if (schema > supportedSchemaVersion)
      throw WeeklyReportPayloadException('Unsupported schemaVersion $schema.');
    final report = _object(map['report'], 'report');
    final days = _array(map['days'], 'days')
        .map((e) => RemoteWeeklyReportDay.fromJson(e))
        .toList(growable: false);
    final habits = _array(map['habits'], 'habits')
        .map((e) => RemoteWeeklyReportHabit.fromJson(e))
        .toList(growable: false);
    final recommendations =
        _array(map['recommendations'] ?? const [], 'recommendations')
            .map((e) => RemoteWeeklyReportRecommendation.fromJson(e))
            .toList(growable: false);
    return RemoteWeeklyReport(
        schemaVersion: schema,
        metricsPolicyVersion:
            _positiveInt(map['metricsPolicyVersion'], 'metricsPolicyVersion'),
        contentVersion: _positiveInt(map['contentVersion'], 'contentVersion'),
        report: RemoteWeeklyReportHeader.fromJson(report),
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
  final String? bestDay, comparabilityReason;
  final List<String> messageKeys;
  final DateTime? generatedAt, refreshedAt, finalizedAt;
  factory RemoteWeeklyReportHeader.fromJson(Map<String, dynamic> m) =>
      RemoteWeeklyReportHeader(
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
          scheduledCount:
              _nonNegativeInt(m['scheduledCount'], 'scheduledCount'),
          completedCount:
              _nonNegativeInt(m['completedCount'], 'completedCount'),
          completionRate: _rate(m['completionRate'], 'completionRate'),
          bestDay: m['bestDay'] == null
              ? null
              : _dateString(m['bestDay'], 'bestDay'),
          trendDelta: m['trendDelta'] == null
              ? null
              : _number(m['trendDelta'], 'trendDelta').toDouble(),
          comparabilityReason: m['comparabilityReason'] as String?,
          schemaVersion:
              _positiveInt(m['schemaVersion'], 'report.schemaVersion'),
          metricsPolicyVersion: _positiveInt(
              m['metricsPolicyVersion'], 'report.metricsPolicyVersion'),
          contentVersion:
              _positiveInt(m['contentVersion'], 'report.contentVersion'),
          messageKeys: _stringArray(m['messageKeys'], 'messageKeys'),
          generatedAt: _instant(m['generatedAt'], 'generatedAt'),
          refreshedAt: _instant(m['refreshedAt'], 'refreshedAt'),
          finalizedAt: _instant(m['finalizedAt'], 'finalizedAt'));
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
      required this.classification,
      required this.occurrences,
      required this.streakSnapshot});
  final String habitId, name, type;
  final String? emoji, familyId;
  final num? target;
  final Map<String, dynamic> schedule;
  final int scheduledCount, completedCount, skippedCount;
  final double? completionRate;
  final String? classification;
  final List<Map<String, dynamic>> occurrences;
  final Map<String, dynamic>? streakSnapshot;
  factory RemoteWeeklyReportHabit.fromJson(Object? value) {
    final m = _object(value, 'habit');
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
    }
    return RemoteWeeklyReportHabit(
        habitId: _id(m['habitId'], 'habit.habitId'),
        name: _string(m['name'], 'habit.name'),
        emoji: m['emoji'] as String?,
        type: _enum(m['type'], const ['check', 'count'], 'habit.type'),
        target:
            m['target'] == null ? null : _number(m['target'], 'habit.target'),
        familyId: m['familyId'] as String?,
        schedule: _object(m['schedule'], 'habit.schedule'),
        scheduledCount:
            _nonNegativeInt(m['scheduledCount'], 'habit.scheduledCount'),
        completedCount:
            _nonNegativeInt(m['completedCount'], 'habit.completedCount'),
        skippedCount: _nonNegativeInt(m['skippedCount'], 'habit.skippedCount'),
        completionRate: _rate(m['completionRate'], 'habit.completionRate'),
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
        occurrences: occurrences,
        streakSnapshot: m['streakSnapshot'] == null
            ? null
            : _object(m['streakSnapshot'], 'streakSnapshot'));
  }
}

class RemoteWeeklyReportRecommendation {
  const RemoteWeeklyReportRecommendation(
      {required this.type, required this.reason});
  final String type, reason;
  factory RemoteWeeklyReportRecommendation.fromJson(Object? v) {
    final m = _object(v, 'recommendation');
    return RemoteWeeklyReportRecommendation(
        type: _string(m['type'], 'recommendation.type'),
        reason: _string(m['reason'], 'recommendation.reason'));
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
