import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/l10n.dart';
import '../../../../services/notification_preferences.dart';
import '../../../../services/notification_service.dart';
import '../../../../stores/user_state_store.dart';
import '../editor/habit_editor_utils.dart';
import '../editor/habit_form_visuals.dart';
import '../../../../widgets/emoji_picker_bottom_sheet.dart';
import 'edit_habit_tab/edit_habit_tab_constants.dart';
import 'edit_habit_tab/edit_habit_tab_dialogs.dart';
import 'edit_habit_tab/edit_habit_tab_form_data.dart';
import 'edit_habit_tab/edit_habit_tab_sections.dart';

class EditHabitTab extends StatefulWidget {
  const EditHabitTab({
    super.key,
    required this.habit,
    required this.familyColor,
    required this.onSaved,
    this.onTitleLiveChanged,
    this.onFamilyIdLiveChanged,
    this.onEmojiPickerRequested,
    this.saveButtonLabel = '',
  });

  final dynamic habit;
  final Color familyColor;
  final void Function(String title)? onTitleLiveChanged;
  final void Function(String familyId)? onFamilyIdLiveChanged;
  final Future<String?> Function(
    BuildContext context,
    String currentEmoji,
    Color accent,
  )? onEmojiPickerRequested;
  final void Function(dynamic updatedHabit) onSaved;
  final String saveButtonLabel;

  @override
  State<EditHabitTab> createState() => _EditHabitTabState();
}

class _EditHabitTabState extends State<EditHabitTab> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _unitCtrl;
  late final FocusNode _titleFocusNode;
  late final EditHabitTabFormData _formData;

  bool _isSaving = false;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    _formData = EditHabitTabFormData.fromHabit(widget.habit);
    _titleCtrl = TextEditingController(
      text: getHabitString(
              widget.habit, ['title', 'name', 'habitTitle', 'label']) ??
          '',
    );
    _descCtrl = TextEditingController(
      text: getHabitString(widget.habit, ['description', 'desc', 'subtitle']) ??
          '',
    );
    _notesCtrl = TextEditingController(
      text: getHabitString(widget.habit, ['notes', 'note']) ?? '',
    );
    _unitCtrl = TextEditingController(text: _formData.unitLabel);
    _titleFocusNode = FocusNode();
    _titleCtrl.addListener(() {
      widget.onTitleLiveChanged?.call(_titleCtrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant EditHabitTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousArchived = _formData.archived;
    _formData.updateArchivedFromHabit(widget.habit);
    if (_formData.archived != previousArchived) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _notesCtrl.dispose();
    _unitCtrl.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickEmoji() async {
    final picker = widget.onEmojiPickerRequested;
    String? selected;

    if (picker != null) {
      // ignore: use_build_context_synchronously
      selected =
          await picker(context, _formData.emoji, _formData.currentFamilyColor);
    } else {
      // ignore: use_build_context_synchronously
      selected = await showEmojiPickerBottomSheet(
        context,
        currentEmoji: _formData.emoji,
        accentColor: _formData.currentFamilyColor,
      );
    }

    if (!mounted || selected == null) {
      return;
    }
    final trimmedSelected = selected.trim();
    if (trimmedSelected.isEmpty) {
      return;
    }

    setState(() => _formData.setEmoji(trimmedSelected));
  }

  void _selectFamily(String familyId) {
    setState(() => _formData.selectFamily(familyId));
    widget.onFamilyIdLiveChanged?.call(familyId);
  }

  void _setUnit(String value) {
    setState(() {
      _formData.unitLabel = value;
      _unitCtrl.text = value;
    });
  }

  Future<void> _showUnitBottomSheet() async {
    final selected = await showEditHabitUnitBottomSheet(
      context,
      currentUnit: _formData.unitLabel,
    );
    if (!mounted || selected == null) {
      return;
    }
    _setUnit(selected.trim());
  }

  Future<void> _showNumberInputDialog({
    required String title,
    required int initialValue,
    required ValueChanged<int> onSubmitted,
    String? subtitle,
  }) {
    return showEditHabitNumberInputDialog(
      context,
      title: title,
      initialValue: initialValue,
      onSubmitted: onSubmitted,
      subtitle: subtitle,
    );
  }

  Future<void> _handleSave() async {
    if (_isSaving) {
      return;
    }

    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _showTitleError = true);
      _titleFocusNode.requestFocus();
      return;
    }

    setState(() {
      _showTitleError = false;
      _isSaving = true;
    });

    final updatedHabit = _formData.buildUpdatedHabit(
      sourceHabit: widget.habit,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
    );

    widget.onSaved(updatedHabit);
    await _syncReminderNotification(updatedHabit);

    if (!mounted) {
      return;
    }

    setState(() => _isSaving = false);
  }

  Future<void> _syncReminderNotification(dynamic object) async {
    try {
      final habitId = getHabitString(object, ['id', 'habitId', 'uuid']) ?? '';
      if (habitId.isEmpty) return;
      final messenger = ScaffoldMessenger.of(context);
      final store = context.read<UserStateStore>();

      if (_formData.remindersEnabled) {
        final result = await NotificationService.instance.requestPermissionFlow();
        if (!result.isAuthorized) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.notificationPermissionMessage(result.status),
              ),
              action: result.shouldOpenSettings
                  ? SnackBarAction(
                      label: context.l10n.commonOpenSettings,
                      onPressed: NotificationService.instance.openSettings,
                    )
                  : null,
            ),
          );
          return;
        }

        final preferences = NotificationPreferences(store);
        final snapshot = preferences.snapshot;
        if (!snapshot.notificationsEnabled) {
          await preferences.setMasterEnabled(true);
        }
        if (!snapshot.habitRemindersEnabled) {
          await preferences.setHabitRemindersEnabled(true);
        }
      }

      await NotificationService.instance.syncPhaseOne(
        store: store,
      );
    } catch (error) {
      debugPrint('Notification sync error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Stack(
      children: [
        HabitFormBackground(familyColor: _formData.currentFamilyColor),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
                  child: EditHabitTabContent(
                    titleController: _titleCtrl,
                    titleFocusNode: _titleFocusNode,
                    descriptionController: _descCtrl,
                    notesController: _notesCtrl,
                    unitController: _unitCtrl,
                    formData: _formData,
                    showTitleError: _showTitleError,
                    onPickEmoji: _pickEmoji,
                    onTitleChanged: (String value) {
                      if (_showTitleError && value.trim().isNotEmpty) {
                        setState(() => _showTitleError = false);
                      }
                    },
                    onSelectFamily: _selectFamily,
                    onSelectCheckTrackingType: () {
                      setState(_formData.setTrackingTypeToCheck);
                    },
                    onSelectCountTrackingType: () {
                      setState(_formData.setTrackingTypeToCount);
                    },
                    onDecrementTarget: () {
                      if (_formData.targetCount > 1) {
                        setState(() => _formData.targetCount -= 1);
                      }
                    },
                    onIncrementTarget: () {
                      setState(() => _formData.targetCount += 1);
                    },
                    onEditTarget: () => _showNumberInputDialog(
                      title: l10n.editHabitDailyGoalDialogTitle,
                      subtitle: l10n.editHabitDailyGoalDialogSubtitle,
                      initialValue: _formData.targetCount,
                      onSubmitted: (int value) {
                        if (!mounted) return;
                        setState(() => _formData.targetCount = value);
                      },
                    ),
                    onOpenUnitSelector: _showUnitBottomSheet,
                    onDecrementStep: () {
                      if (_formData.counterStep > 1) {
                        setState(() => _formData.counterStep -= 1);
                      }
                    },
                    onIncrementStep: () {
                      setState(() => _formData.counterStep += 1);
                    },
                    onEditStep: () => _showNumberInputDialog(
                      title: l10n.editHabitCounterStepDialogTitle,
                      subtitle: l10n.editHabitCounterStepDialogSubtitle,
                      initialValue: _formData.counterStep,
                      onSubmitted: (int value) {
                        if (!mounted) return;
                        setState(() => _formData.counterStep = value);
                      },
                    ),
                    onSelectFrequencyMode: (String mode) {
                      setState(() => _formData.frequencyMode = mode);
                    },
                    onToggleSelectedDay: (int day) {
                      setState(() => _formData.toggleSelectedDay(day));
                    },
                    onDecrementTimesPerWeek: () {
                      if (_formData.timesPerWeekTarget > 1) {
                        setState(() => _formData.timesPerWeekTarget -= 1);
                      }
                    },
                    onIncrementTimesPerWeek: () {
                      setState(() => _formData.timesPerWeekTarget += 1);
                    },
                    onEditTimesPerWeek: () => _showNumberInputDialog(
                      title: l10n.editHabitTimesPerWeekDialogTitle,
                      subtitle: l10n.editHabitTimesPerWeekDialogSubtitle,
                      initialValue: _formData.timesPerWeekTarget,
                      onSubmitted: (int value) {
                        if (!mounted) return;
                        setState(() => _formData.timesPerWeekTarget = value);
                      },
                    ),
                    onToggleReminders: (bool value) {
                      setState(() => _formData.remindersEnabled = value);
                    },
                    onReminderTimeChanged: (DateTime value) {
                      setState(() => _formData.reminderTime = value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        HabitFormBottomCta(
          label: _isSaving
              ? l10n.editHabitSaving
              : (widget.saveButtonLabel.isEmpty
                  ? l10n.editHabitSaveChanges
                  : widget.saveButtonLabel),
          onPressed: _handleSave,
          isDisabled: _isSaving,
          backgroundColor: editHabitDark,
          foregroundColor: editHabitCream,
          baseColor: editHabitCream,
        ),
      ],
    );
  }
}
