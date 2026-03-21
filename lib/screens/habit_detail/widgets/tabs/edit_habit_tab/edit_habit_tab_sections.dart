import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../../utils/family_theme.dart';
import '../../editor/habit_form_visuals.dart';
import 'edit_habit_tab_constants.dart';
import 'edit_habit_tab_form_data.dart';

class EditHabitTabContent extends StatelessWidget {
  const EditHabitTabContent({
    super.key,
    required this.titleController,
    required this.titleFocusNode,
    required this.descriptionController,
    required this.notesController,
    required this.unitController,
    required this.formData,
    required this.showTitleError,
    required this.onPickEmoji,
    required this.onTitleChanged,
    required this.onSelectFamily,
    required this.onSelectCheckTrackingType,
    required this.onSelectCountTrackingType,
    required this.onDecrementTarget,
    required this.onIncrementTarget,
    required this.onEditTarget,
    required this.onOpenUnitSelector,
    required this.onDecrementStep,
    required this.onIncrementStep,
    required this.onEditStep,
    required this.onSelectFrequencyMode,
    required this.onToggleSelectedDay,
    required this.onDecrementTimesPerWeek,
    required this.onIncrementTimesPerWeek,
    required this.onEditTimesPerWeek,
    required this.onToggleReminders,
    required this.onReminderTimeChanged,
  });

  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final TextEditingController descriptionController;
  final TextEditingController notesController;
  final TextEditingController unitController;
  final EditHabitTabFormData formData;
  final bool showTitleError;
  final VoidCallback onPickEmoji;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSelectFamily;
  final VoidCallback onSelectCheckTrackingType;
  final VoidCallback onSelectCountTrackingType;
  final VoidCallback onDecrementTarget;
  final VoidCallback onIncrementTarget;
  final VoidCallback onEditTarget;
  final VoidCallback onOpenUnitSelector;
  final VoidCallback onDecrementStep;
  final VoidCallback onIncrementStep;
  final VoidCallback onEditStep;
  final ValueChanged<String> onSelectFrequencyMode;
  final ValueChanged<int> onToggleSelectedDay;
  final VoidCallback onDecrementTimesPerWeek;
  final VoidCallback onIncrementTimesPerWeek;
  final VoidCallback onEditTimesPerWeek;
  final ValueChanged<bool> onToggleReminders;
  final ValueChanged<DateTime> onReminderTimeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HabitFormSectionLabel(text: l10n.editHabitSectionIdentity),
        EditHabitIdentitySection(
          titleController: titleController,
          titleFocusNode: titleFocusNode,
          emoji: formData.emoji,
          showTitleError: showTitleError,
          onPickEmoji: onPickEmoji,
          onTitleChanged: onTitleChanged,
        ),
        const SizedBox(height: 28),
        HabitFormSectionLabel(text: l10n.editHabitSectionCategory),
        EditHabitCategorySection(
          families: EditHabitTabFormData.availableFamilies,
          selectedFamilyId: formData.familyId,
          onSelectFamily: onSelectFamily,
        ),
        const SizedBox(height: 28),
        HabitFormSectionLabel(text: l10n.editHabitSectionTracking),
        EditHabitTrackingTypeSection(
          trackingType: formData.trackingType,
          onSelectCheck: onSelectCheckTrackingType,
          onSelectCount: onSelectCountTrackingType,
        ),
        const SizedBox(height: 28),
        EditHabitCountSection(
          isVisible: formData.showsCountTargetSection,
          targetCount: formData.targetCount,
          unitController: unitController,
          counterStep: formData.counterStep,
          onDecrementTarget: onDecrementTarget,
          onIncrementTarget: onIncrementTarget,
          onEditTarget: onEditTarget,
          onOpenUnitSelector: onOpenUnitSelector,
          onDecrementStep: onDecrementStep,
          onIncrementStep: onIncrementStep,
          onEditStep: onEditStep,
        ),
        const SizedBox(height: 28),
        HabitFormSectionLabel(text: l10n.editHabitSectionFrequency),
        EditHabitFrequencySection(
          trackingType: formData.trackingType,
          frequencyMode: formData.frequencyMode,
          selectedDays: formData.selectedDays,
          timesPerWeekTarget: formData.timesPerWeekTarget,
          showsWeeklyCheckTargetSection: formData.showsWeeklyCheckTargetSection,
          onSelectFrequencyMode: onSelectFrequencyMode,
          onToggleSelectedDay: onToggleSelectedDay,
          onDecrementTimesPerWeek: onDecrementTimesPerWeek,
          onIncrementTimesPerWeek: onIncrementTimesPerWeek,
          onEditTimesPerWeek: onEditTimesPerWeek,
        ),
        const SizedBox(height: 28),
        HabitFormSectionLabel(text: l10n.editHabitSectionReminder),
        EditHabitReminderSection(
          remindersEnabled: formData.remindersEnabled,
          reminderTime: formData.reminderTime,
          onToggleReminders: onToggleReminders,
          onReminderTimeChanged: onReminderTimeChanged,
        ),
        const SizedBox(height: 28),
        HabitFormSectionLabel(text: l10n.editHabitSectionDetails),
        EditHabitDetailsSection(
          descriptionController: descriptionController,
          notesController: notesController,
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class EditHabitIdentitySection extends StatelessWidget {
  const EditHabitIdentitySection({
    super.key,
    required this.titleController,
    required this.titleFocusNode,
    required this.emoji,
    required this.showTitleError,
    required this.onPickEmoji,
    required this.onTitleChanged,
  });

  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final String emoji;
  final bool showTitleError;
  final VoidCallback onPickEmoji;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onPickEmoji,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: editHabitCamel.withOpacitySafe(0.11),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: editHabitCamel.withOpacitySafe(0.35)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
                const Positioned(
                  right: -2,
                  bottom: -2,
                  child: _EditBadge(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleController,
                focusNode: titleFocusNode,
                maxLength: 40,
                onChanged: onTitleChanged,
                style: GoogleFonts.dmSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: editHabitDark,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: l10n.editHabitTitleHint,
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: editHabitDark.withOpacitySafe(0.28),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: showTitleError
                          ? editHabitCamel
                          : editHabitCamel.withOpacitySafe(0.30),
                      width: showTitleError ? 1.4 : 1,
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: showTitleError
                          ? editHabitCamel
                          : editHabitCamel.withOpacitySafe(0.80),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${titleController.text.characters.length} / 40',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: editHabitDark.withOpacitySafe(0.28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditHabitCategorySection extends StatelessWidget {
  const EditHabitCategorySection({
    super.key,
    required this.families,
    required this.selectedFamilyId,
    required this.onSelectFamily,
  });

  final List<String> families;
  final String selectedFamilyId;
  final ValueChanged<String> onSelectFamily;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: families.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 74 / 60,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (BuildContext context, int index) {
        final familyId = families[index];
        final isSelected = familyId == selectedFamilyId;
        final color = FamilyTheme.colorOf(familyId);

        return GestureDetector(
          onTap: () => onSelectFamily(familyId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withOpacitySafe(0.11)
                  : Colors.white.withOpacitySafe(0.50),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    isSelected ? color : editHabitCamel.withOpacitySafe(0.12),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    FamilyTheme.emojiOf(familyId),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.familyName(familyId),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: editHabitDark,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class EditHabitTrackingTypeSection extends StatelessWidget {
  const EditHabitTrackingTypeSection({
    super.key,
    required this.trackingType,
    required this.onSelectCheck,
    required this.onSelectCount,
  });

  final String trackingType;
  final VoidCallback onSelectCheck;
  final VoidCallback onSelectCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 112,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: HabitFormTypeCard(
              title: l10n.editHabitTrackingCheckTitle,
              description: l10n.editHabitTrackingCheckSubtitle,
              icon: Icons.check_rounded,
              accentColor: editHabitSage,
              isSelected: trackingType == 'check',
              onTap: onSelectCheck,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: HabitFormTypeCard(
              title: l10n.editHabitTrackingCountTitle,
              description: l10n.editHabitTrackingCountSubtitle,
              icon: Icons.loop_rounded,
              accentColor: editHabitCamel,
              isSelected: trackingType == 'count',
              onTap: onSelectCount,
            ),
          ),
        ],
      ),
    );
  }
}

class EditHabitCountSection extends StatelessWidget {
  const EditHabitCountSection({
    super.key,
    required this.isVisible,
    required this.targetCount,
    required this.unitController,
    required this.counterStep,
    required this.onDecrementTarget,
    required this.onIncrementTarget,
    required this.onEditTarget,
    required this.onOpenUnitSelector,
    required this.onDecrementStep,
    required this.onIncrementStep,
    required this.onEditStep,
  });

  final bool isVisible;
  final int targetCount;
  final TextEditingController unitController;
  final int counterStep;
  final VoidCallback onDecrementTarget;
  final VoidCallback onIncrementTarget;
  final VoidCallback onEditTarget;
  final VoidCallback onOpenUnitSelector;
  final VoidCallback onDecrementStep;
  final VoidCallback onIncrementStep;
  final VoidCallback onEditStep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: isVisible ? 1 : 0,
        child: isVisible
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HabitFormSectionLabel(text: l10n.editHabitDailyGoalSection),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacitySafe(0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: editHabitCamel.withOpacitySafe(0.14)),
                    ),
                    child: Column(
                      children: [
                        _EditHabitStepperRow(
                          title: l10n.editHabitRepetitionsTitle,
                          subtitle: l10n.editHabitRepetitionsSubtitle,
                          value: targetCount,
                          onDecrement: onDecrementTarget,
                          onIncrement: onIncrementTarget,
                          onEdit: onEditTarget,
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: onOpenUnitSelector,
                          child: AbsorbPointer(
                            child: SizedBox(
                              height: 44,
                              child: TextField(
                                controller: unitController,
                                readOnly: true,
                                minLines: 1,
                                maxLines: 1,
                                textAlignVertical: TextAlignVertical.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: editHabitDark,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  hintText: l10n.editHabitUnitHint,
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: editHabitDark.withOpacitySafe(0.28),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  suffixIconConstraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 28,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.expand_more_rounded,
                                    color: editHabitCamel.withOpacitySafe(0.90),
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          editHabitCamel.withOpacitySafe(0.30),
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color:
                                          editHabitCamel.withOpacitySafe(0.80),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _EditHabitStepperRow(
                          title: l10n.editHabitCounterStepTitle,
                          subtitle: l10n.editHabitCounterStepSubtitle,
                          value: counterStep,
                          onDecrement: onDecrementStep,
                          onIncrement: onIncrementStep,
                          onEdit: onEditStep,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class EditHabitFrequencySection extends StatelessWidget {
  const EditHabitFrequencySection({
    super.key,
    required this.trackingType,
    required this.frequencyMode,
    required this.selectedDays,
    required this.timesPerWeekTarget,
    required this.showsWeeklyCheckTargetSection,
    required this.onSelectFrequencyMode,
    required this.onToggleSelectedDay,
    required this.onDecrementTimesPerWeek,
    required this.onIncrementTimesPerWeek,
    required this.onEditTimesPerWeek,
  });

  final String trackingType;
  final String frequencyMode;
  final Set<int> selectedDays;
  final int timesPerWeekTarget;
  final bool showsWeeklyCheckTargetSection;
  final ValueChanged<String> onSelectFrequencyMode;
  final ValueChanged<int> onToggleSelectedDay;
  final VoidCallback onDecrementTimesPerWeek;
  final VoidCallback onIncrementTimesPerWeek;
  final VoidCallback onEditTimesPerWeek;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            HabitFormFrequencyChip(
              label: l10n.editHabitFrequencyDaily,
              isSelected: frequencyMode == 'daily',
              onTap: () => onSelectFrequencyMode('daily'),
            ),
            HabitFormFrequencyChip(
              label: l10n.editHabitFrequencySpecificDays,
              isSelected: frequencyMode == 'specificDays',
              onTap: () => onSelectFrequencyMode('specificDays'),
            ),
            if (trackingType == 'check')
              HabitFormFrequencyChip(
                label: l10n.editHabitFrequencyTimesPerWeek,
                isSelected: frequencyMode == 'timesPerWeek',
                onTap: () => onSelectFrequencyMode('timesPerWeek'),
              ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: frequencyMode == 'specificDays'
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List<Widget>.generate(
                      7,
                      (int index) {
                        final day = index + 1;
                        final isSelected = selectedDays.contains(day);

                        return GestureDetector(
                          onTap: () => onToggleSelectedDay(day),
                          child: Container(
                            width: 38,
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? editHabitCamel
                                  : Colors.white.withOpacitySafe(0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? editHabitCamel
                                    : editHabitCamel.withOpacitySafe(0.20),
                              ),
                            ),
                            child: Text(
                              l10n.weekdayLetter(day),
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? editHabitCream
                                    : editHabitDark.withOpacitySafe(0.38),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: showsWeeklyCheckTargetSection
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacitySafe(0.42),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: editHabitCamel.withOpacitySafe(0.14)),
                    ),
                    child: _EditHabitStepperRow(
                      title: l10n.editHabitWeeklyGoalTitle,
                      subtitle: l10n.editHabitWeeklyGoalSubtitle,
                      value: timesPerWeekTarget,
                      onDecrement: onDecrementTimesPerWeek,
                      onIncrement: onIncrementTimesPerWeek,
                      onEdit: onEditTimesPerWeek,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class EditHabitReminderSection extends StatelessWidget {
  const EditHabitReminderSection({
    super.key,
    required this.remindersEnabled,
    required this.reminderTime,
    required this.onToggleReminders,
    required this.onReminderTimeChanged,
  });

  final bool remindersEnabled;
  final DateTime reminderTime;
  final ValueChanged<bool> onToggleReminders;
  final ValueChanged<DateTime> onReminderTimeChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacitySafe(0.48),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: editHabitCamel.withOpacitySafe(0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: editHabitCamel.withOpacitySafe(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  size: 18,
                  color: editHabitCamel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.editHabitReminderDailyTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: editHabitDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.editHabitReminderDailySubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: editHabitDark.withOpacitySafe(0.42),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: remindersEnabled,
                activeTrackColor: editHabitCamel,
                onChanged: onToggleReminders,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: remindersEnabled
              ? Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacitySafe(0.42),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: editHabitCamel.withOpacitySafe(0.14)),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: reminderTime,
                    use24hFormat: true,
                    onDateTimeChanged: onReminderTimeChanged,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class EditHabitDetailsSection extends StatelessWidget {
  const EditHabitDetailsSection({
    super.key,
    required this.descriptionController,
    required this.notesController,
  });

  final TextEditingController descriptionController;
  final TextEditingController notesController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacitySafe(0.42),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: editHabitCamel.withOpacitySafe(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: descriptionController,
            minLines: 1,
            maxLines: 2,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: editHabitDark,
            ),
            decoration: InputDecoration(
              hintText: l10n.editHabitDescriptionHint,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: editHabitDark.withOpacitySafe(0.28),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: editHabitCamel.withOpacitySafe(0.30)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: editHabitCamel.withOpacitySafe(0.80)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            minLines: 3,
            maxLines: 5,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: editHabitDark,
            ),
            decoration: InputDecoration(
              hintText: l10n.editHabitNotesHint,
              hintStyle: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: editHabitDark.withOpacitySafe(0.28),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: editHabitCamel.withOpacitySafe(0.30)),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: editHabitCamel.withOpacitySafe(0.80)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditHabitStepperRow extends StatelessWidget {
  const _EditHabitStepperRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: editHabitDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: editHabitDark.withOpacitySafe(0.38),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            HabitFormStepperButton(
              icon: Icons.remove_rounded,
              onTap: onDecrement,
            ),
            const SizedBox(width: 10),
            HabitFormEditableTargetValue(
              value: value,
              onTap: onEdit,
            ),
            const SizedBox(width: 10),
            HabitFormStepperButton(
              icon: Icons.add_rounded,
              onTap: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

class _EditBadge extends StatelessWidget {
  const _EditBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: editHabitCamel,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.edit,
        size: 9,
        color: editHabitCream,
      ),
    );
  }
}
