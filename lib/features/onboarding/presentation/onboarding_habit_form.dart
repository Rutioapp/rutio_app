import 'package:flutter/material.dart';

import '../../../features/habits/domain/metrics/habit_snapshot.dart';
import '../../../l10n/l10n.dart';
import '../../../screens/habit_detail/widgets/editor/habit_form_visuals.dart';
import '../../../screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_dialogs.dart';
import '../../../screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_form_data.dart';
import '../../../screens/habit_detail/widgets/tabs/edit_habit_tab/edit_habit_tab_sections.dart';
import '../../../utils/family_theme.dart';
import '../../../widgets/emoji_picker_bottom_sheet.dart';
import '../domain/models/onboarding_habit_configuration.dart';

/// Onboarding-only adapter around the real habit editor body.
///
/// The editor sections provide the visual language and controls used by the
/// normal habit editor. This wrapper owns only transient form state and turns
/// it back into the typed onboarding configuration; it never builds a habit
/// entity or invokes a store, sync, notification or Navigator side effect.
class OnboardingHabitForm extends StatefulWidget {
  const OnboardingHabitForm({
    super.key,
    required this.initialConfiguration,
    required this.onSubmit,
    this.errorMessage,
  });

  final OnboardingHabitConfiguration initialConfiguration;
  final ValueChanged<OnboardingHabitConfiguration> onSubmit;
  final String? errorMessage;

  @override
  OnboardingHabitFormState createState() => OnboardingHabitFormState();
}

class OnboardingHabitFormState extends State<OnboardingHabitForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _unitController;
  late final FocusNode _titleFocusNode;
  late EditHabitTabFormData _formData;
  String? _familyCode;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialConfiguration;
    _familyCode = initial.primaryFamilyCode;
    _formData = _formDataFrom(initial);
    _titleController = TextEditingController(text: initial.name);
    _unitController = TextEditingController(text: initial.unit ?? '');
    _titleFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _unitController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditHabitIdentitySection(
          titleController: _titleController,
          titleFocusNode: _titleFocusNode,
          titleFieldKey: const ValueKey('onboardingHabitName'),
          emoji: _formData.emoji,
          showTitleError: _showTitleError,
          onPickEmoji: _pickEmoji,
          onTitleChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        HabitFormSectionLabel(text: l10n.createHabitSectionCategory),
        EditHabitCategorySection(
          families: EditHabitTabFormData.availableFamilies,
          selectedFamilyId: _formData.familyId,
          onSelectFamily: _selectFamily,
        ),
        const SizedBox(height: 14),
        HabitFormSectionLabel(text: l10n.createHabitSectionTracking),
        EditHabitTrackingTypeSection(
          trackingType: _formData.trackingType,
          onSelectCheck: () => setState(_formData.setTrackingTypeToCheck),
          onSelectCount: () => setState(_formData.setTrackingTypeToCount),
        ),
        const SizedBox(height: 14),
        EditHabitCountSection(
          isVisible: _formData.showsCountTargetSection,
          targetKey: const ValueKey('onboardingHabitTarget'),
          unitFieldKey: const ValueKey('onboardingHabitUnit'),
          targetCount: _formData.targetCount,
          unitController: _unitController,
          counterStep: _formData.counterStep,
          onDecrementTarget: () => setState(() {
            _formData.targetCount =
                (_formData.targetCount - _formData.counterStep)
                    .clamp(1, 999999);
          }),
          onIncrementTarget: () => setState(() {
            _formData.targetCount += _formData.counterStep;
          }),
          onEditTarget: _editTarget,
          onOpenUnitSelector: _openUnitSelector,
          onSelectQuickUnit: _selectQuickUnit,
          onDecrementStep: () => setState(() {
            _formData.counterStep =
                (_formData.counterStep - 1).clamp(1, 999999);
          }),
          onIncrementStep: () => setState(() {
            _formData.counterStep += 1;
          }),
          onEditStep: _editStep,
        ),
        const SizedBox(height: 14),
        EditHabitFrequencySection(
          trackingType: _formData.trackingType,
          frequencyMode: _formData.frequencyMode,
          selectedDays: _formData.selectedDays,
          timesPerWeekTarget: _formData.timesPerWeekTarget,
          showsWeeklyCheckTargetSection: false,
          includeTimesPerWeek: false,
          weekdayKeyPrefix: 'onboardingHabitWeekday',
          onSelectFrequencyMode: _selectFrequencyMode,
          onToggleSelectedDay: (day) => setState(() {
            _formData.toggleSelectedDay(day);
          }),
          onDecrementTimesPerWeek: () {},
          onIncrementTimesPerWeek: () {},
          onEditTimesPerWeek: () {},
        ),
        if (widget.errorMessage != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.errorMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  EditHabitTabFormData _formDataFrom(OnboardingHabitConfiguration value) {
    final schedule = value.schedule;
    return EditHabitTabFormData(
      familyId: value.primaryFamilyCode ?? FamilyTheme.fallbackId,
      emoji: value.emoji,
      emojiWasEdited: false,
      trackingType: value.kind.key,
      targetCount: value.targetValue ?? 1,
      unitLabel: value.unit ?? '',
      frequencyMode: schedule.isWeekly ? 'specificDays' : 'daily',
      selectedDays: schedule.isWeekly
          ? schedule.weekdays.toSet()
          : <int>{1, 2, 3, 4, 5, 6, 7},
      remindersEnabled: false,
      reminderTime: DateTime(2000, 1, 1, 8),
      archived: false,
      timesPerWeekTarget: 1,
      counterStep: 1,
    );
  }

  Future<void> _pickEmoji() async {
    final selected = await showEmojiPickerBottomSheet(
      context,
      currentEmoji: _formData.emoji,
      currentHabitName: _titleController.text,
      accentColor: _formData.currentFamilyColor,
    );
    if (!mounted || selected == null || selected.trim().isEmpty) return;
    setState(() => _formData.setEmoji(selected.trim()));
  }

  void _selectFamily(String familyId) {
    setState(() {
      _familyCode = familyId;
      _formData.selectFamily(familyId);
    });
  }

  void _selectFrequencyMode(String mode) {
    if (mode != 'daily' && mode != 'specificDays') return;
    setState(() => _formData.frequencyMode = mode);
  }

  Future<void> _editTarget() async {
    await showEditHabitNumberInputDialog(
      context,
      title: context.l10n.createHabitCounterTargetAmountLabel,
      initialValue: _formData.targetCount,
      onSubmitted: (value) => setState(() => _formData.targetCount = value),
    );
  }

  Future<void> _editStep() async {
    await showEditHabitNumberInputDialog(
      context,
      title: context.l10n.editHabitCounterStepTitle,
      initialValue: _formData.counterStep,
      onSubmitted: (value) => setState(() => _formData.counterStep = value),
    );
  }

  Future<void> _openUnitSelector() async {
    final selected = await showEditHabitUnitBottomSheet(
      context,
      currentUnit: _formData.unitLabel,
    );
    if (!mounted || selected == null) return;
    _selectQuickUnit(selected);
  }

  void _selectQuickUnit(String unit) {
    setState(() {
      _formData.unitLabel = unit.trim();
      _unitController.text = _formData.unitLabel;
    });
  }

  void submit() {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _showTitleError = true);
      _titleFocusNode.requestFocus();
      return;
    }
    final schedule = _formData.frequencyMode == 'specificDays'
        ? HabitSchedule.weekly(
            weekdays: _formData.resolvedRoutineDaysForSave(),
          )
        : HabitSchedule.daily();
    widget.onSubmit(
      OnboardingHabitConfiguration(
        name: _titleController.text.trim(),
        emoji: _formData.emoji,
        primaryFamilyCode: _familyCode,
        kind: _formData.trackingType == 'count'
            ? HabitKind.count
            : HabitKind.check,
        schedule: schedule,
        targetValue:
            _formData.trackingType == 'count' ? _formData.targetCount : null,
        unit: _formData.trackingType == 'count'
            ? (_formData.unitLabel.trim().isEmpty
                ? null
                : _formData.unitLabel.trim())
            : null,
      ),
    );
  }
}
