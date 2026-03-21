import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/notification_permission_service.dart';
import '../../l10n/l10n.dart';
import '../../services/notification_models.dart';
import '../../services/notification_preferences.dart';
import '../../services/notification_service.dart';
import '../../stores/user_state_store.dart';
import 'widgets/notification_time_tile.dart';
import 'widgets/section_card.dart';
import 'widgets/switch_row.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const int _notificationCategoryTotal = 5;

  Future<void> _setMasterEnabled(bool enabled) async {
    final store = context.read<UserStateStore>();
    final preferences = NotificationPreferences(store);

    if (enabled) {
      final result = await NotificationService.instance.requestPermissionFlow();
      if (!result.isAuthorized) {
        _showNotificationPermissionSnack(result);
        return;
      }
    }

    await preferences.setMasterEnabled(enabled);
    await NotificationService.instance.syncPhaseOne(store: store);
  }

  Future<void> _setToggle({
    required bool nextValue,
    required Future<void> Function(NotificationPreferences preferences) persist,
  }) async {
    final store = context.read<UserStateStore>();
    final preferences = NotificationPreferences(store);
    final snapshot = preferences.snapshot;

    if (!snapshot.notificationsEnabled && nextValue) {
      final result = await NotificationService.instance.requestPermissionFlow();
      if (!result.isAuthorized) {
        _showNotificationPermissionSnack(result);
        return;
      }
      await preferences.setMasterEnabled(true);
    } else if (nextValue) {
      final result = await NotificationService.instance.requestPermissionFlow();
      if (!result.isAuthorized) {
        _showNotificationPermissionSnack(result);
        return;
      }
    }

    await persist(preferences);
    await NotificationService.instance.syncPhaseOne(store: store);
  }

  Future<void> _pickDayClosureTime(NotificationTime current) async {
    final initialDateTime = DateTime(2024, 1, 1, current.hour, current.minute);

    if (Platform.isIOS) {
      DateTime selected = initialDateTime;
      await showCupertinoModalPopup<void>(
        context: context,
        builder: (context) {
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
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.commonCancel),
                      ),
                      CupertinoButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _saveDayClosureTime(selected);
                        },
                        child: Text(context.l10n.commonSave),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    use24hFormat: true,
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
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (selectedTime == null) return;
    await _saveDayClosureTime(
      DateTime(2024, 1, 1, selectedTime.hour, selectedTime.minute),
    );
  }

  Future<void> _saveDayClosureTime(DateTime value) async {
    final store = context.read<UserStateStore>();
    final preferences = NotificationPreferences(store);
    await preferences.setDayClosureTime(
      NotificationTime(hour: value.hour, minute: value.minute),
    );
    await NotificationService.instance.syncPhaseOne(store: store);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<UserStateStore>();
    final preferences = NotificationPreferences(store);
    final snapshot = preferences.snapshot;
    final enabledCount = <bool>[
      snapshot.habitRemindersEnabled,
      snapshot.dayClosureEnabled,
      snapshot.streakRiskEnabled,
      snapshot.streakCelebrationEnabled,
      snapshot.inactivityReengagementEnabled,
    ].where((value) => value).length;

    final timeLabel = DateFormat.Hm().format(
      DateTime(
        2024,
        1,
        1,
        snapshot.dayClosureTime.hour,
        snapshot.dayClosureTime.minute,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F6FF),
        elevation: 0,
        surfaceTintColor: const Color(0xFFF7F6FF),
        centerTitle: true,
        title: Text(l10n.profileNotificationsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchRow(
                  title: l10n.profileEnableNotificationsTitle,
                  subtitle: l10n.profileEnableNotificationsSubtitle,
                  value: snapshot.notificationsEnabled,
                  onChanged: _setMasterEnabled,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.profileNotificationCategoriesActive(
                    enabledCount,
                    _notificationCategoryTotal,
                  ),
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF7A7A7A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.profileNotificationsPhaseOneTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          SectionCard(
            child: Column(
              children: [
                SwitchRow(
                  title: l10n.profileNotificationHabitRemindersTitle,
                  subtitle: l10n.profileNotificationHabitRemindersSubtitle,
                  value: snapshot.habitRemindersEnabled,
                  enabled: snapshot.notificationsEnabled,
                  onChanged: (value) => _setToggle(
                    nextValue: value,
                    persist: (preferences) =>
                        preferences.setHabitRemindersEnabled(value),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchRow(
                  title: l10n.profileNotificationDayClosureTitle,
                  subtitle: l10n.profileNotificationDayClosureSubtitle,
                  value: snapshot.dayClosureEnabled,
                  enabled: snapshot.notificationsEnabled,
                  onChanged: (value) => _setToggle(
                    nextValue: value,
                    persist: (preferences) =>
                        preferences.setDayClosureEnabled(value),
                  ),
                ),
                const SizedBox(height: 12),
                NotificationTimeTile(
                  title: l10n.profileNotificationDayClosureTimeTitle,
                  subtitle: l10n.profileNotificationDayClosureTimeSubtitle,
                  valueLabel: timeLabel,
                  enabled: snapshot.notificationsEnabled &&
                      snapshot.dayClosureEnabled,
                  onTap: () => _pickDayClosureTime(snapshot.dayClosureTime),
                ),
                const SizedBox(height: 12),
                SwitchRow(
                  title: l10n.profileNotificationStreakRiskTitle,
                  subtitle: l10n.profileNotificationStreakRiskSubtitle,
                  value: snapshot.streakRiskEnabled,
                  enabled: snapshot.notificationsEnabled,
                  onChanged: (value) => _setToggle(
                    nextValue: value,
                    persist: (preferences) =>
                        preferences.setStreakRiskEnabled(value),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchRow(
                  title: l10n.profileNotificationStreakCelebrationTitle,
                  subtitle: l10n.profileNotificationStreakCelebrationSubtitle,
                  value: snapshot.streakCelebrationEnabled,
                  enabled: snapshot.notificationsEnabled,
                  onChanged: (value) => _setToggle(
                    nextValue: value,
                    persist: (preferences) =>
                        preferences.setStreakCelebrationEnabled(value),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchRow(
                  title: l10n.profileNotificationInactivityTitle,
                  subtitle: l10n.profileNotificationInactivitySubtitle,
                  value: snapshot.inactivityReengagementEnabled,
                  enabled: snapshot.notificationsEnabled,
                  onChanged: (value) => _setToggle(
                    nextValue: value,
                    persist: (preferences) =>
                        preferences.setInactivityReengagementEnabled(value),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationPermissionSnack(
    NotificationPermissionResult result,
  ) {
    if (!mounted) return;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.notificationPermissionMessage(result.status)),
        action: result.shouldOpenSettings
            ? SnackBarAction(
                label: l10n.commonOpenSettings,
                onPressed: NotificationService.instance.openSettings,
              )
            : null,
      ),
    );
  }
}
