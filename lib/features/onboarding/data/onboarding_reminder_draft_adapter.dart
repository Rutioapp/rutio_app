import '../domain/models/onboarding_reminder_configuration.dart';
import '../domain/models/onboarding_types.dart';

class OnboardingReminderDraftAdapterException implements Exception {
  const OnboardingReminderDraftAdapterException(this.message);

  final String message;

  @override
  String toString() => 'OnboardingReminderDraftAdapterException: $message';
}

/// The only boundary that knows the persisted ReminderDraft map shape.
class OnboardingReminderDraftAdapter {
  const OnboardingReminderDraftAdapter._();

  static Map<String, dynamic> encode(OnboardingReminderConfiguration value) {
    final error = _validateShape(value);
    if (error != null) {
      throw OnboardingReminderDraftAdapterException(error);
    }
    return <String, dynamic>{
      'enabled': value.enabled,
      if (value.selectedTime != null)
        'selectedTime': <String, dynamic>{
          'hour': value.selectedTime!.hour,
          'minute': value.selectedTime!.minute,
        },
      'permissionState': value.permissionState.code,
      'schedulingState': value.schedulingState.code,
    };
  }

  static OnboardingReminderConfiguration decode(Map<String, dynamic> source) {
    final enabled = _readBool(source['enabled']);
    if (enabled == null) {
      throw const OnboardingReminderDraftAdapterException(
        'Reminder enabled decision is required.',
      );
    }
    final permission = ReminderPermissionState.fromCode(
      source['permissionState'],
    );
    if (permission == null) {
      throw const OnboardingReminderDraftAdapterException(
        'Reminder permission state is invalid.',
      );
    }
    final scheduling = ReminderSchedulingState.fromCode(
      source['schedulingState'],
    );
    if (scheduling == null) {
      throw const OnboardingReminderDraftAdapterException(
        'Reminder scheduling state is invalid.',
      );
    }
    final result = OnboardingReminderConfiguration(
      enabled: enabled,
      selectedTime: _decodeTime(source),
      permissionState: permission,
      schedulingState: scheduling,
    );
    final error = _validateShape(result);
    if (error != null) throw OnboardingReminderDraftAdapterException(error);
    return result;
  }

  static OnboardingReminderConfiguration? tryDecode(
    Map<String, dynamic>? source,
  ) {
    if (source == null || source.isEmpty) return null;
    try {
      return decode(source);
    } on OnboardingReminderDraftAdapterException {
      return null;
    }
  }

  static String? _validateShape(OnboardingReminderConfiguration value) {
    if (value.selectedTime != null && !value.selectedTime!.isValid) {
      return 'Reminder time is invalid.';
    }
    if (!value.enabled) {
      if (value.schedulingState == ReminderSchedulingState.notRequested &&
          value.selectedTime != null &&
          value.permissionState == ReminderPermissionState.notRequested) {
        return null;
      }
      if (value.selectedTime != null) return 'Disabled reminder has no time.';
      if (value.schedulingState != ReminderSchedulingState.disabled) {
        return 'Disabled reminder must use disabled scheduling state.';
      }
      return null;
    }
    if (value.selectedTime == null) return 'Enabled reminder needs a time.';
    if (value.schedulingState == ReminderSchedulingState.disabled) {
      return 'Enabled reminder cannot use disabled scheduling state.';
    }
    return null;
  }

  static OnboardingReminderTime? _decodeTime(Map<String, dynamic> source) {
    final raw = source['selectedTime'] ?? source['time'];
    if (raw is Map) {
      final hour = _readInt(raw['hour']);
      final minute = _readInt(raw['minute']);
      if (hour == null || minute == null) {
        throw const OnboardingReminderDraftAdapterException(
          'Reminder time is invalid.',
        );
      }
      return OnboardingReminderTime(hour: hour, minute: minute);
    }
    // Read the old local HH:mm representation, but never write it back.
    final legacy = (raw ?? source['reminderTime'])?.toString().trim();
    if (legacy == null || legacy.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(legacy);
    if (match == null) {
      throw const OnboardingReminderDraftAdapterException(
        'Reminder time is invalid.',
      );
    }
    return OnboardingReminderTime(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      if (value == 'true') return true;
      if (value == 'false') return false;
    }
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num && value.isFinite && value % 1 == 0) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
