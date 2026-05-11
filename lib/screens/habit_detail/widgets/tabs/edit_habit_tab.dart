import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../features/notifications/application/notification_permission_controller.dart';
import '../../../../features/notifications/domain/notification_permission_status.dart';
import '../../../../features/notifications/presentation/notification_permission_recovery_sheet.dart';
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
      final store = context.read<UserStateStore>();

      if (_formData.remindersEnabled) {
        final permissionController = NotificationPermissionController();
        await permissionController.markPostLoginPromptShown();
        final canSchedule =
            await permissionController.ensureCanScheduleFromReminderFlow();
        if (!canSchedule) {
          final effectiveStatus = await permissionController.getEffectiveStatus();
          final shouldShowPermissionSnack =
              effectiveStatus == NotificationPermissionStatus.denied ||
                  effectiveStatus ==
                      NotificationPermissionStatus.permanentlyDenied;
          if (!shouldShowPermissionSnack || !mounted) {
            return;
          }

          final result = await NotificationService.instance.checkPermissionStatus();
          if (!mounted) return;
          await showNotificationPermissionRecoverySheet(
            context,
            controller: permissionController,
            permissionResult: result,
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

  Future<void> _showRoutineSheet() async {
    final l10n = context.l10n;
    final List<_EditRoutinePreviewOption> options = <_EditRoutinePreviewOption>[
      _EditRoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineMorningTitle,
        subtitle: l10n.createHabitRoutineMorningSubtitle,
      ),
      _EditRoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineDeepFocusTitle,
        subtitle: l10n.createHabitRoutineDeepFocusSubtitle,
      ),
      _EditRoutinePreviewOption(
        emoji: '??',
        title: l10n.createHabitRoutineEveningTitle,
        subtitle: l10n.createHabitRoutineEveningSubtitle,
      ),
    ];

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: editHabitCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: editHabitCamel.withOpacitySafe(0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.createHabitRoutineTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: editHabitDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.createHabitRoutineSheetSubtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: editHabitDark.withOpacitySafe(0.56),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...options.map(
                    (_EditRoutinePreviewOption option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacitySafe(0.62),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: editHabitCamel.withOpacitySafe(0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: editHabitCamel.withOpacitySafe(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  option.emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: editHabitDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.subtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w400,
                                        color:
                                            editHabitDark.withOpacitySafe(0.55),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacitySafe(0.82),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: editHabitCamel.withOpacitySafe(0.26),
                                  ),
                                ),
                                child: Text(
                                  l10n.createHabitRoutineSoon,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: editHabitCamel.withOpacitySafe(0.95),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacitySafe(0.35),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: editHabitCamel.withOpacitySafe(0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: editHabitCamel.withOpacitySafe(0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.createHabitRoutineCreateNew,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: editHabitDark.withOpacitySafe(0.82),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CupertinoButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(
                      l10n.createHabitRoutineNotNow,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: editHabitDark.withOpacitySafe(0.65),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
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
                    onSelectQuickUnit: _setUnit,
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
                    onOpenRoutineComingSoon: _showRoutineSheet,
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

class _EditRoutinePreviewOption {
  const _EditRoutinePreviewOption({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;
}
