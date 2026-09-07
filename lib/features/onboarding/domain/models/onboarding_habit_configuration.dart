import 'package:flutter/foundation.dart';

import '../../../../features/habits/domain/metrics/habit_snapshot.dart';
import '../../../../utils/family_theme.dart';
import 'onboarding_recommendation.dart';

/// Typed, side-effect-free configuration edited by the onboarding Habit step.
///
/// This is deliberately not a persisted habit entity: it has no id, progress,
/// history, sync metadata or notification state. The draft adapter is the only
/// place where it becomes a dynamic local map.
@immutable
class OnboardingHabitConfiguration {
  const OnboardingHabitConfiguration({
    required this.name,
    required this.emoji,
    required this.primaryFamilyCode,
    required this.kind,
    required this.schedule,
    this.targetValue,
    this.unit,
  });

  factory OnboardingHabitConfiguration.custom({String? familyCode}) {
    final family = _validFamily(familyCode);
    return OnboardingHabitConfiguration(
      name: '',
      emoji: FamilyTheme.emojiOf(family),
      primaryFamilyCode: family,
      kind: HabitKind.check,
      schedule: HabitSchedule.daily(),
    );
  }

  factory OnboardingHabitConfiguration.fromRecommendation(
    OnboardingRecommendation recommendation, {
    required String locale,
  }) {
    final rawType = recommendation.habitType.trim().toLowerCase();
    if (!const <String>{'check', 'count', 'counter', 'numeric'}
        .contains(rawType)) {
      throw const FormatException('Recommendation has an unsupported type.');
    }
    final kind = HabitKindX.fromString(recommendation.habitType);
    final schedule = OnboardingHabitSchedule.fromCanonicalMap(
      recommendation.initialScheduleSnapshot,
    );
    final target = recommendation.targetValue;
    if (kind == HabitKind.count &&
        (target == null ||
            target.isNaN ||
            target.isInfinite ||
            target % 1 != 0 ||
            target < 1)) {
      throw const FormatException('Count recommendation has no valid target.');
    }
    final family = _validFamily(recommendation.primaryFamilyCode);
    if (family == null) {
      throw const FormatException(
          'Recommendation has no valid primary family.');
    }
    if (recommendation.nameFor(locale).trim().isEmpty ||
        recommendation.emoji.trim().isEmpty) {
      throw const FormatException('Recommendation has incomplete identity.');
    }
    return OnboardingHabitConfiguration(
      name: recommendation.nameFor(locale).trim(),
      emoji: recommendation.emoji.trim(),
      primaryFamilyCode: family,
      kind: kind,
      schedule: schedule,
      targetValue: kind == HabitKind.count ? target!.toInt() : null,
      unit: kind == HabitKind.count ? _trimToNull(recommendation.unit) : null,
    );
  }

  final String name;
  final String emoji;
  final String? primaryFamilyCode;
  final HabitKind kind;
  final HabitSchedule schedule;
  final int? targetValue;
  final String? unit;

  bool get isCheck => kind == HabitKind.check;
  bool get isCount => kind == HabitKind.count;

  OnboardingHabitConfiguration copyWith({
    String? name,
    String? emoji,
    Object? primaryFamilyCode = _unset,
    HabitKind? kind,
    HabitSchedule? schedule,
    Object? targetValue = _unset,
    Object? unit = _unset,
  }) {
    return OnboardingHabitConfiguration(
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      primaryFamilyCode: identical(primaryFamilyCode, _unset)
          ? this.primaryFamilyCode
          : primaryFamilyCode as String?,
      kind: kind ?? this.kind,
      schedule: schedule ?? this.schedule,
      targetValue: identical(targetValue, _unset)
          ? this.targetValue
          : targetValue as int?,
      unit: identical(unit, _unset) ? this.unit : unit as String?,
    );
  }

  static const Object _unset = Object();

  static String? _validFamily(String? value) {
    final normalized = value?.trim();
    if (normalized == null || !FamilyTheme.order.contains(normalized)) {
      return null;
    }
    return normalized;
  }

  static String? _trimToNull(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

/// A strict view of the canonical schedule contract supported by onboarding.
/// The stored value remains the real [HabitSchedule], not a parallel schedule
/// enum or a map assembled by presentation code.
class OnboardingHabitSchedule {
  const OnboardingHabitSchedule._();

  static HabitSchedule fromCanonicalMap(Map<String, dynamic> source) {
    final type = (source['type'] ?? '').toString().trim();
    switch (type) {
      case 'daily':
        return HabitSchedule.daily();
      case 'weekly':
        final rawDays = source['weekdays'];
        if (rawDays is! List || rawDays.isEmpty) {
          throw const FormatException('Weekly schedule needs weekdays.');
        }
        final days = <int>[];
        for (final rawDay in rawDays) {
          final day = rawDay is int
              ? rawDay
              : rawDay is num && rawDay.isFinite && rawDay % 1 == 0
                  ? rawDay.toInt()
                  : int.tryParse(rawDay.toString());
          if (day == null || day < DateTime.monday || day > DateTime.sunday) {
            throw const FormatException('Weekly schedule has invalid weekday.');
          }
          if (days.contains(day)) {
            throw const FormatException(
                'Weekly schedule has duplicate weekday.');
          }
          days.add(day);
        }
        days.sort();
        return HabitSchedule.weekly(weekdays: days);
      case 'timesPerWeek':
        final rawTarget = source['timesPerWeek'];
        final target = rawTarget is num
            ? rawTarget.toInt()
            : int.tryParse((rawTarget ?? '').toString().trim());
        if (target == null || target < 1) {
          throw const FormatException(
            'timesPerWeek schedule needs a positive target.',
          );
        }
        return HabitSchedule.timesPerWeek(
          timesPerWeek: target,
          weekStartsOn: (source['weekStartsOn'] as num?)?.toInt() ?? 1,
        );
      case 'once':
        throw const FormatException('once is not supported in onboarding.');
      default:
        throw const FormatException('Unknown onboarding schedule.');
    }
  }

  static Map<String, dynamic> toCanonicalMap(HabitSchedule schedule) {
    switch (schedule.type) {
      case HabitScheduleType.daily:
        return <String, dynamic>{'type': 'daily'};
      case HabitScheduleType.weekly:
        if (schedule.weekdays.isEmpty) {
          throw const FormatException('Weekly schedule needs weekdays.');
        }
        return <String, dynamic>{
          'type': 'weekly',
          'weekdays': List<int>.from(schedule.weekdays),
        };
      case HabitScheduleType.once:
        throw const FormatException('once is not supported in onboarding.');
      case HabitScheduleType.timesPerWeek:
        return <String, dynamic>{
          'type': 'timesPerWeek',
          'timesPerWeek': schedule.timesPerWeek ?? 1,
          'weekStartsOn': schedule.weekStartsOn,
        };
    }
  }
}
