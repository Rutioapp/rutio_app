import 'package:flutter/foundation.dart';

import 'onboarding_types.dart';

@immutable
class OnboardingReminderTime {
  const OnboardingReminderTime({required this.hour, required this.minute});

  final int hour;
  final int minute;

  bool get isValid => hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59;

  @override
  bool operator ==(Object other) =>
      other is OnboardingReminderTime &&
      other.hour == hour &&
      other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Typed, side-effect-free reminder intent stored inside the onboarding draft.
/// It is not a scheduled notification and deliberately has no notification id.
@immutable
class OnboardingReminderConfiguration {
  const OnboardingReminderConfiguration({
    required this.enabled,
    required this.selectedTime,
    required this.permissionState,
    required this.schedulingState,
  });

  factory OnboardingReminderConfiguration.disabled({
    ReminderPermissionState permissionState =
        ReminderPermissionState.notRequested,
  }) {
    return OnboardingReminderConfiguration(
      enabled: false,
      selectedTime: null,
      permissionState: permissionState,
      schedulingState: ReminderSchedulingState.disabled,
    );
  }

  factory OnboardingReminderConfiguration.pending({
    required OnboardingReminderTime selectedTime,
  }) {
    return OnboardingReminderConfiguration(
      enabled: true,
      selectedTime: selectedTime,
      permissionState: ReminderPermissionState.notRequested,
      schedulingState: ReminderSchedulingState.notRequested,
    );
  }

  /// A catalog-only prefill. It is intentionally disabled until the user
  /// chooses the explicit Enable action in the Reminder step.
  factory OnboardingReminderConfiguration.suggestion({
    required OnboardingReminderTime selectedTime,
  }) {
    return OnboardingReminderConfiguration(
      enabled: false,
      selectedTime: selectedTime,
      permissionState: ReminderPermissionState.notRequested,
      schedulingState: ReminderSchedulingState.notRequested,
    );
  }

  final bool enabled;
  final OnboardingReminderTime? selectedTime;
  final ReminderPermissionState permissionState;
  final ReminderSchedulingState schedulingState;

  OnboardingReminderConfiguration copyWith({
    bool? enabled,
    Object? selectedTime = _unset,
    ReminderPermissionState? permissionState,
    ReminderSchedulingState? schedulingState,
  }) {
    return OnboardingReminderConfiguration(
      enabled: enabled ?? this.enabled,
      selectedTime: identical(selectedTime, _unset)
          ? this.selectedTime
          : selectedTime as OnboardingReminderTime?,
      permissionState: permissionState ?? this.permissionState,
      schedulingState: schedulingState ?? this.schedulingState,
    );
  }

  static const Object _unset = Object();
}
