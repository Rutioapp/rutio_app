import '../../../data/mappers/habit_schedule_normalizer.dart';
import '../../habits/domain/metrics/habit_snapshot.dart';
import '../domain/models/onboarding_habit_configuration.dart';
import '../../../utils/family_theme.dart';

class OnboardingHabitDraftAdapterException implements Exception {
  const OnboardingHabitDraftAdapterException(this.message);

  final String message;

  @override
  String toString() => 'OnboardingHabitDraftAdapterException: $message';
}

/// The only onboarding component that knows the dynamic habit-map keys.
///
/// New writes use the current local names (`name`, `familyId`, `type`,
/// `target`, `unit`, `schedule`). Legacy aliases are accepted on read so an
/// interrupted/older draft can be recovered without copying those aliases
/// into the next persisted payload.
class OnboardingHabitDraftAdapter {
  const OnboardingHabitDraftAdapter._();

  static Map<String, dynamic> encode(OnboardingHabitConfiguration value) {
    final validation = _validateShape(value);
    if (validation != null) {
      throw OnboardingHabitDraftAdapterException(validation);
    }
    final schedule = OnboardingHabitSchedule.toCanonicalMap(value.schedule);
    final normalizedSchedule =
        HabitScheduleNormalizer.normalizeOrNull(schedule);
    if (normalizedSchedule == null) {
      throw const OnboardingHabitDraftAdapterException(
        'Schedule is not supported by onboarding.',
      );
    }

    return <String, dynamic>{
      'name': value.name.trim(),
      'emoji': value.emoji.trim(),
      if (value.primaryFamilyCode != null) 'familyId': value.primaryFamilyCode,
      'type': value.kind.key,
      if (value.isCount) ...{
        'target': value.targetValue,
        'targetCount': value.targetValue,
        if (value.unit != null) ...{
          'unit': value.unit,
          'unitLabel': value.unit,
        },
      },
      'schedule': normalizedSchedule,
      'reminderEnabled': false,
    };
  }

  static OnboardingHabitConfiguration decode(Map<String, dynamic> source) {
    final name = _readString(source, const <String>['name', 'title']);
    final emoji = _readString(source, const <String>['emoji', 'habitEmoji']);
    if (name == null || emoji == null) {
      throw const OnboardingHabitDraftAdapterException(
        'Habit draft is missing name or emoji.',
      );
    }

    final kind = HabitKindX.fromString(
      _readString(source, const <String>[
        'type',
        'habitType',
        'trackingType',
        'tracking',
      ]),
    );
    final rawType = _readString(source, const <String>[
      'type',
      'habitType',
      'trackingType',
      'tracking',
    ]);
    if (rawType != null &&
        !const <String>{'check', 'count', 'counter', 'numeric'}
            .contains(rawType.toLowerCase())) {
      throw const OnboardingHabitDraftAdapterException(
        'Habit type is not supported by onboarding.',
      );
    }

    final schedule = _decodeSchedule(source);
    final rawTarget = _readValue(source, const <String>[
      'targetValue',
      'target',
      'targetCount',
      'goal',
      'times',
    ]);
    final target = rawTarget == null ? null : _positiveInt(rawTarget);
    if (kind == HabitKind.count && target == null) {
      throw const OnboardingHabitDraftAdapterException(
        'Count habit needs a positive target.',
      );
    }

    final family = _readString(source, const <String>['familyId']);
    final unit = _readString(source, const <String>[
      'unit',
      'unitLabel',
      'counterUnit',
    ]);
    final result = OnboardingHabitConfiguration(
      name: name,
      emoji: emoji,
      primaryFamilyCode: family,
      kind: kind,
      schedule: schedule,
      targetValue: kind == HabitKind.count ? target : null,
      unit: kind == HabitKind.count ? unit : null,
    );
    final error = _validateShape(result);
    if (error != null) throw OnboardingHabitDraftAdapterException(error);
    return result;
  }

  static OnboardingHabitConfiguration? tryDecode(
    Map<String, dynamic>? source,
  ) {
    if (source == null || source.isEmpty) return null;
    try {
      return decode(source);
    } on OnboardingHabitDraftAdapterException {
      return null;
    }
  }

  static String? _validateShape(OnboardingHabitConfiguration value) {
    final name = value.name.trim();
    if (name.isEmpty) return 'Habit name is required.';
    if (name.runes.length > 40) return 'Habit name is too long.';
    if (name.runes
        .any((rune) => rune == 0xfffd || rune < 0x20 || rune == 0x7f)) {
      return 'Habit name contains invalid characters.';
    }
    if (value.emoji.trim().isEmpty) return 'Habit emoji is required.';
    if (value.primaryFamilyCode != null &&
        !FamilyTheme.order.contains(value.primaryFamilyCode)) {
      return 'Habit family is not supported.';
    }
    if (value.kind == HabitKind.count &&
        (value.targetValue == null || value.targetValue! < 1)) {
      return 'Count habit needs a positive target.';
    }
    if (value.kind == HabitKind.count && value.schedule.isTimesPerWeek) {
      return 'Count habits cannot use a flexible weekly schedule.';
    }
    if (value.kind == HabitKind.check && value.targetValue != null) {
      return 'Check habit must not contain count configuration.';
    }
    if (value.kind == HabitKind.check && value.unit != null) {
      return 'Check habit must not contain a unit.';
    }
    if (value.schedule.isWeekly && value.schedule.weekdays.isEmpty) {
      return 'Weekly schedule needs weekdays.';
    }
    if (!value.schedule.isDaily &&
        !value.schedule.isWeekly &&
        !value.schedule.isTimesPerWeek) {
      return 'Schedule is not supported by onboarding.';
    }
    return null;
  }

  static HabitSchedule _decodeSchedule(Map<String, dynamic> source) {
    final raw = source['schedule'];
    if (raw == null) {
      final routineDays = source['routineDays'];
      if (routineDays is List && routineDays.isNotEmpty) {
        return OnboardingHabitSchedule.fromCanonicalMap(<String, dynamic>{
          'type': 'weekly',
          'weekdays': routineDays,
        });
      }
      return HabitSchedule.daily();
    }
    if (raw is! Map) {
      throw const OnboardingHabitDraftAdapterException(
        'Habit schedule is not a map.',
      );
    }
    final map = Map<String, dynamic>.from(raw.cast<String, dynamic>());
    try {
      // Decode before normalizing so duplicate/invalid weekdays cannot be
      // silently collapsed by the legacy normalizer.
      final decoded = OnboardingHabitSchedule.fromCanonicalMap(map);
      final canonical = OnboardingHabitSchedule.toCanonicalMap(decoded);
      final normalized = HabitScheduleNormalizer.normalizeOrNull(canonical);
      if (normalized == null || normalized['type'] == 'once') {
        throw const FormatException(
          'Habit schedule is not supported by onboarding.',
        );
      }
      return OnboardingHabitSchedule.fromCanonicalMap(normalized);
    } on FormatException catch (error) {
      throw OnboardingHabitDraftAdapterException(error.message);
    }
  }

  static dynamic _readValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      if (source.containsKey(key)) return source[key];
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> source, List<String> keys) {
    final value = _readValue(source, keys);
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _positiveInt(dynamic value) {
    if (value is int) return value > 0 ? value : null;
    if (value is num) {
      return value.isFinite && value % 1 == 0 && value > 0
          ? value.toInt()
          : null;
    }
    final raw = value.toString().trim();
    final parsed = int.tryParse(raw);
    return parsed != null && parsed > 0 ? parsed : null;
  }
}
