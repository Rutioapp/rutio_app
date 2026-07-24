class HabitScheduleNormalizer {
  const HabitScheduleNormalizer._();

  static const Map<String, dynamic> daily = <String, dynamic>{'type': 'daily'};

  static Map<String, dynamic> normalize(dynamic raw) {
    return normalizeOrNull(raw) ?? Map<String, dynamic>.from(daily);
  }

  static Map<String, dynamic>? normalizeOrNull(dynamic raw) {
    if (raw is! Map) return null;

    final source = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    final type = (source['type'] ?? '').toString().trim();

    switch (type) {
      case 'weekly':
        final weekdays = normalizeWeekdays(source['weekdays']);
        if (weekdays.isEmpty) return null;
        return <String, dynamic>{
          'type': 'weekly',
          'weekdays': weekdays,
        };
      case 'once':
        final date = _normalizeIsoDate(source['date']);
        if (date == null) return null;
        return <String, dynamic>{'type': 'once', 'date': date};
      case 'timesPerWeek':
        final target = _positiveInt(
          source['timesPerWeek'] ??
              source['timesPerWeekTarget'] ??
              source['goal'] ??
              source['times'],
        );
        if (target == null) return null;

        final output = <String, dynamic>{
          'type': 'timesPerWeek',
          'timesPerWeek': target,
        };
        final weekStartsOn = _weekday(source['weekStartsOn']);
        if (weekStartsOn != null) output['weekStartsOn'] = weekStartsOn;
        return output;
      case 'daily':
        return Map<String, dynamic>.from(daily);
      default:
        return null;
    }
  }

  static List<int> normalizeWeekdays(dynamic rawWeekdays) {
    if (rawWeekdays is! List) return const <int>[];

    final days = <int>{};
    for (final value in rawWeekdays) {
      final day = _weekday(value);
      if (day != null) days.add(day);
    }
    final sorted = days.toList()..sort();
    return sorted;
  }

  static int? _weekday(dynamic value) {
    final parsed = _int(value);
    if (parsed == null || parsed < 1 || parsed > 7) return null;
    return parsed;
  }

  static int? _positiveInt(dynamic value) {
    final parsed = _int(value);
    if (parsed == null || parsed < 1) return null;
    return parsed;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) {
      if (value.isNaN || value.isInfinite) return null;
      if (value % 1 != 0) return null;
      return value.toInt();
    }
    final raw = (value ?? '').toString().trim();
    if (!RegExp(r'^-?\d+$').hasMatch(raw)) return null;
    return int.tryParse(raw);
  }

  static String? _normalizeIsoDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    final normalized = [
      parsed.year.toString().padLeft(4, '0'),
      parsed.month.toString().padLeft(2, '0'),
      parsed.day.toString().padLeft(2, '0'),
    ].join('-');
    return normalized == raw ? raw : null;
  }
}
