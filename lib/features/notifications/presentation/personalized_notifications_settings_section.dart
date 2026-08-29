import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../screens/profile/widgets/notification_time_tile.dart';
import '../../../screens/profile/widgets/switch_row.dart';
import '../application/notification_permission_controller.dart';
import '../application/personalized_notification_settings_controller.dart';
import '../domain/personalized_notification_models.dart';
import 'notification_permission_recovery_sheet.dart';

class PersonalizedNotificationsSettingsSection extends StatefulWidget {
  const PersonalizedNotificationsSettingsSection({super.key});

  @override
  State<PersonalizedNotificationsSettingsSection> createState() =>
      _PersonalizedNotificationsSettingsSectionState();
}

class _PersonalizedNotificationsSettingsSectionState
    extends State<PersonalizedNotificationsSettingsSection> {
  final NotificationPermissionController _permissionController =
      NotificationPermissionController();

  Future<void> _handleEnabledChanged(bool enabled) async {
    final controller =
        context.read<PersonalizedNotificationSettingsController>();
    final result = await controller.setEnabled(enabled);

    if (!mounted ||
        !result.needsRecoverySheet ||
        result.permissionResult == null) {
      return;
    }

    final recoveryOutcome = await showNotificationPermissionRecoverySheet(
      context,
      controller: _permissionController,
      permissionResult: result.permissionResult!,
    );

    if (!mounted) return;
    if (recoveryOutcome == NotificationPermissionRecoveryOutcome.granted) {
      await controller.setEnabled(true);
    }
  }

  Future<void> _pickReferenceTime() async {
    final controller =
        context.read<PersonalizedNotificationSettingsController>();
    final current = controller.referenceTime;
    final initialDateTime = DateTime(2024, 1, 1, current.hour, current.minute);

    if (Theme.of(context).platform == TargetPlatform.iOS ||
        Theme.of(context).platform == TargetPlatform.macOS) {
      DateTime selected = initialDateTime;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (pickerContext) {
          return Container(
            height: 320,
            color: Colors.white,
            child: Column(
              children: [
                SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        onPressed: () => Navigator.of(pickerContext).pop(),
                        child: Text(context.l10n.commonCancel),
                      ),
                      CupertinoButton(
                        onPressed: () async {
                          Navigator.of(pickerContext).pop();
                          await controller.setReferenceTime(
                            NotificationClockTime(
                              hour: selected.hour,
                              minute: selected.minute,
                            ),
                          );
                        },
                        child: Text(context.l10n.commonSave),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                    initialDateTime: initialDateTime,
                    onDateTimeChanged: (value) => selected = value,
                  ),
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (selectedTime == null) return;

    await controller.setReferenceTime(
      NotificationClockTime(
        hour: selectedTime.hour,
        minute: selectedTime.minute,
      ),
    );
  }

  String _formatTimeLabel(BuildContext context, NotificationClockTime time) {
    final timeOfDay = TimeOfDay(hour: time.hour, minute: time.minute);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String _intensityLabel(
    BuildContext context,
    NotificationIntensityPreset preset,
  ) {
    final l10n = context.l10n;
    switch (preset) {
      case NotificationIntensityPreset.light:
        return l10n.personalizedNotificationsIntensitySoft;
      case NotificationIntensityPreset.balanced:
        return l10n.personalizedNotificationsIntensityBalanced;
      case NotificationIntensityPreset.active:
        return l10n.personalizedNotificationsIntensityActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller =
        context.watch<PersonalizedNotificationSettingsController>();
    final preferences = controller.preferences;
    final enabled = controller.personalizedNotificationsEnabled;
    final canEdit = controller.canEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchRow(
          title: l10n.personalizedNotificationsEnableTitle,
          subtitle: l10n.personalizedNotificationsEnableSubtitle,
          value: enabled,
          enabled: canEdit,
          onChanged: _handleEnabledChanged,
        ),
        const SizedBox(height: 14),
        Text(
          l10n.personalizedNotificationsIntensityLabel,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.personalizedNotificationsIntensitySubtitle,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF7A7A7A),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        Opacity(
          opacity: canEdit ? 1 : 0.68,
          child: IgnorePointer(
            ignoring: !canEdit,
            child: CupertinoSegmentedControl<NotificationIntensityPreset>(
              groupValue: preferences.intensityPreset,
              borderColor: const Color(0xFFE3E0F7),
              selectedColor: const Color(0xFF6C5CE7),
              unselectedColor: Colors.white,
              pressedColor: const Color(0xFFEDEAFF),
              children: {
                for (final preset in NotificationIntensityPreset.values)
                  preset: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      _intensityLabel(context, preset),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: preferences.intensityPreset == preset
                            ? Colors.white
                            : const Color(0xFF4D4D4D),
                      ),
                    ),
                  ),
              },
              onValueChanged: (preset) {
                unawaited(controller.setIntensity(preset));
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        NotificationTimeTile(
          title: l10n.personalizedNotificationsReferenceTimeTitle,
          subtitle: l10n.personalizedNotificationsReferenceTimeSubtitle,
          valueLabel: _formatTimeLabel(context, preferences.dailyAnchorTime),
          enabled: canEdit && enabled,
          onTap: canEdit && enabled ? _pickReferenceTime : null,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.personalizedNotificationsHabitReminderNote,
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF7A7A7A),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
