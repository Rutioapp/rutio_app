import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rutio/utils/app_theme.dart';

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
    required this.onSelectQuickUnit,
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
    required this.onOpenRoutineComingSoon,
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
  final ValueChanged<String> onSelectQuickUnit;
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
  final VoidCallback onOpenRoutineComingSoon;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EditHabitHeaderSection(
          title: l10n.editHabitHeaderTitle,
          subtitle: l10n.editHabitHeaderSubtitle,
        ),
        const SizedBox(height: 12),
        EditHabitIdentitySection(
          titleController: titleController,
          titleFocusNode: titleFocusNode,
          emoji: formData.emoji,
          showTitleError: showTitleError,
          onPickEmoji: onPickEmoji,
          onTitleChanged: onTitleChanged,
        ),
        const SizedBox(height: 14),
        _EditSectionHeading(text: l10n.createHabitSectionCategory),
        const SizedBox(height: 8),
        EditHabitCategorySection(
          families: EditHabitTabFormData.availableFamilies,
          selectedFamilyId: formData.familyId,
          onSelectFamily: onSelectFamily,
        ),
        const SizedBox(height: 14),
        _EditSectionHeading(text: l10n.createHabitSectionTracking),
        const SizedBox(height: 8),
        EditHabitTrackingTypeSection(
          trackingType: formData.trackingType,
          onSelectCheck: onSelectCheckTrackingType,
          onSelectCount: onSelectCountTrackingType,
        ),
        const SizedBox(height: 14),
        EditHabitCountSection(
          isVisible: formData.showsCountTargetSection,
          targetCount: formData.targetCount,
          unitController: unitController,
          counterStep: formData.counterStep,
          onDecrementTarget: onDecrementTarget,
          onIncrementTarget: onIncrementTarget,
          onEditTarget: onEditTarget,
          onOpenUnitSelector: onOpenUnitSelector,
          onSelectQuickUnit: onSelectQuickUnit,
          onDecrementStep: onDecrementStep,
          onIncrementStep: onIncrementStep,
          onEditStep: onEditStep,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 12),
        EditHabitRoutineSection(
          onTap: onOpenRoutineComingSoon,
        ),
        const SizedBox(height: 12),
        EditHabitReminderSection(
          remindersEnabled: formData.remindersEnabled,
          reminderTime: formData.reminderTime,
          onToggleReminders: onToggleReminders,
          onReminderTimeChanged: onReminderTimeChanged,
        ),
        const SizedBox(height: 14),
        _EditSectionHeading(text: l10n.editHabitSectionDetails),
        const SizedBox(height: 8),
        EditHabitDetailsSection(
          descriptionController: descriptionController,
          notesController: notesController,
        ),
      ],
    );
  }
}

class EditHabitHeaderSection extends StatelessWidget {
  const EditHabitHeaderSection({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.authTitle.copyWith(
              fontSize: 38,
              height: 0.92,
              color: editHabitDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w400,
              color: editHabitDark.withOpacitySafe(0.55),
            ),
          ),
        ],
      ),
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

    return _EditSurfaceCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onPickEmoji,
            child: Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: editHabitCamel.withOpacitySafe(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: editHabitCamel.withOpacitySafe(0.24)),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 38),
                    ),
                  ),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: editHabitCream,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: editHabitCamel.withOpacitySafe(0.30),
                        ),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: editHabitCamel.withOpacitySafe(0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createHabitNameLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.9,
                    color: editHabitDark.withOpacitySafe(0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacitySafe(0.82),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: showTitleError
                          ? editHabitCamel
                          : editHabitCamel.withOpacitySafe(0.22),
                      width: showTitleError ? 1.4 : 1,
                    ),
                  ),
                  child: TextField(
                    controller: titleController,
                    focusNode: titleFocusNode,
                    maxLength: 40,
                    onChanged: onTitleChanged,
                    style: GoogleFonts.dmSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w500,
                      color: editHabitDark,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: l10n.editHabitTitleHint,
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: editHabitDark.withOpacitySafe(0.28),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.createHabitNameHelper,
                        maxLines: 2,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: editHabitDark.withOpacitySafe(0.52),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${titleController.text.characters.length} / 40',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: editHabitDark.withOpacitySafe(0.42),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: families.map((String familyId) {
          final bool isSelected = familyId == selectedFamilyId;
          final Color color = FamilyTheme.colorOf(familyId);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelectFamily(familyId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 66,
                height: 76,
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacitySafe(0.10)
                      : Colors.white.withOpacitySafe(0.56),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : editHabitCamel.withOpacitySafe(0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      FamilyTheme.emojiOf(familyId),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      context.l10n.familyName(familyId),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? color : editHabitDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
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
      height: 86,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _EditTrackingCard(
              title: l10n.createHabitTrackingCheckTitle,
              description: l10n.createHabitTrackingCheckSubtitle,
              leading: const Icon(
                Icons.check_rounded,
                size: 26,
                color: editHabitCream,
              ),
              accentColor: editHabitSage,
              isSelected: trackingType == 'check',
              onTap: onSelectCheck,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _EditTrackingCard(
              title: l10n.createHabitTrackingCountTitle,
              description: l10n.createHabitTrackingCountSubtitle,
              leading: Text(
                '123',
                style: GoogleFonts.dmSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: editHabitCamel.withOpacitySafe(0.95),
                ),
              ),
              accentColor: editHabitSage,
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
    required this.onSelectQuickUnit,
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
  final ValueChanged<String> onSelectQuickUnit;
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
                  _EditSectionHeading(text: l10n.editHabitDailyGoalSection),
                  const SizedBox(height: 8),
                  _EditSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.createHabitCounterGoalTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: editHabitDark,
                                ),
                              ),
                            ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: editHabitCamel.withOpacitySafe(0.14),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '123',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: editHabitCamel.withOpacitySafe(0.95),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.createHabitCounterGoalSubtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: editHabitDark.withOpacitySafe(0.52),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.createHabitCounterTargetAmountLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: editHabitDark.withOpacitySafe(0.40),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.createHabitCounterUnitLabel,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: editHabitDark.withOpacitySafe(0.40),
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                height: 42,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacitySafe(0.80),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: editHabitCamel.withOpacitySafe(0.20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: onDecrementTarget,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacitySafe(0.82),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: editHabitCamel
                                                .withOpacitySafe(0.24),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          CupertinoIcons.minus,
                                          size: 11,
                                          color: editHabitCamel
                                              .withOpacitySafe(0.95),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: onEditTarget,
                                        child: Container(
                                          alignment: Alignment.center,
                                          color: Colors.transparent,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '$targetCount',
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppTextStyles.serifFamily,
                                                fontSize: 22,
                                                color: editHabitDark,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: onIncrementTarget,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacitySafe(0.82),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: editHabitCamel
                                                .withOpacitySafe(0.24),
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(
                                          CupertinoIcons.add,
                                          size: 11,
                                          color: editHabitCamel
                                              .withOpacitySafe(0.95),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: onOpenUnitSelector,
                                child: AbsorbPointer(
                                  child: SizedBox(
                                    height: 42,
                                    child: TextField(
                                      controller: unitController,
                                      readOnly: true,
                                      minLines: 1,
                                      maxLines: 1,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: editHabitDark,
                                      ),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacitySafe(0.80),
                                        isDense: true,
                                        hintText: l10n.editHabitUnitHint,
                                        hintStyle: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: editHabitDark
                                              .withOpacitySafe(0.28),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        suffixIconConstraints:
                                            const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                        suffixIcon: Icon(
                                          Icons.expand_more_rounded,
                                          color: editHabitCamel.withOpacitySafe(
                                            0.90,
                                          ),
                                          size: 18,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          borderSide: BorderSide(
                                            color: editHabitCamel
                                                .withOpacitySafe(0.20),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          borderSide: BorderSide(
                                            color: editHabitCamel
                                                .withOpacitySafe(0.20),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          borderSide: BorderSide(
                                            color: editHabitCamel
                                                .withOpacitySafe(0.46),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.createHabitCounterQuickUnitsLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: editHabitDark.withOpacitySafe(0.40),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ...<String>[
                              l10n.createHabitCounterQuickUnitMinutes,
                              l10n.createHabitCounterQuickUnitPages,
                              l10n.createHabitCounterQuickUnitGlasses,
                              l10n.createHabitCounterQuickUnitReps,
                            ].map((String quickUnit) {
                              final bool isSelected =
                                  unitController.text.trim().toLowerCase() ==
                                      quickUnit.toLowerCase();
                              return GestureDetector(
                                onTap: () => onSelectQuickUnit(quickUnit),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? editHabitCamel.withOpacitySafe(0.88)
                                        : Colors.white.withOpacitySafe(0.76),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: isSelected
                                          ? editHabitCamel.withOpacitySafe(0.88)
                                          : editHabitCamel
                                              .withOpacitySafe(0.20),
                                    ),
                                  ),
                                  child: Text(
                                    quickUnit,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? editHabitCream
                                          : editHabitDark.withOpacitySafe(0.62),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            GestureDetector(
                              onTap: onOpenUnitSelector,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacitySafe(0.76),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: editHabitCamel.withOpacitySafe(0.20),
                                  ),
                                ),
                                child: Text(
                                  l10n.createHabitCounterQuickUnitCustom,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                    color: editHabitDark.withOpacitySafe(0.62),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacitySafe(0.64),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: editHabitCamel.withOpacitySafe(0.16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: editHabitCamel.withOpacitySafe(0.14),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  CupertinoIcons.clock,
                                  size: 12,
                                  color: editHabitCamel.withOpacitySafe(0.90),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.createHabitCounterExampleTitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: editHabitDark.withOpacitySafe(
                                          0.72,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      l10n.createHabitCounterExampleSubtitle,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w400,
                                        color: editHabitDark.withOpacitySafe(
                                          0.52,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
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
    final List<_EditSegmentOption> segments = [
      _EditSegmentOption(
        id: 'daily',
        label: l10n.editHabitFrequencyDaily,
      ),
      _EditSegmentOption(
        id: 'specificDays',
        label: l10n.editHabitFrequencySpecificDays,
      ),
      if (trackingType == 'check')
        _EditSegmentOption(
          id: 'timesPerWeek',
          label: l10n.editHabitFrequencyTimesPerWeek,
        ),
    ];

    String cardTitle;
    String cardSubtitle;
    IconData cardIcon;
    switch (frequencyMode) {
      case 'specificDays':
        cardTitle = l10n.createHabitFrequencySpecificTitle;
        cardSubtitle = l10n.createHabitFrequencySpecificSubtitle;
        cardIcon = CupertinoIcons.calendar_badge_plus;
        break;
      case 'timesPerWeek':
        cardTitle = l10n.createHabitFrequencyTimesPerWeekTitle;
        cardSubtitle = l10n.createHabitFrequencyTimesPerWeekSubtitle;
        cardIcon = CupertinoIcons.repeat;
        break;
      default:
        cardTitle = l10n.createHabitFrequencyDailyTitle;
        cardSubtitle = l10n.createHabitFrequencyDailySubtitle;
        cardIcon = CupertinoIcons.calendar_today;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _EditSectionHeading(text: l10n.createHabitSectionFrequency),
        const SizedBox(height: 8),
        _EditFrequencySegmentedControl(
          options: segments,
          selectedId: frequencyMode,
          onSelected: onSelectFrequencyMode,
        ),
        const SizedBox(height: 8),
        _EditSurfaceCard(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: editHabitSage.withOpacitySafe(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      cardIcon,
                      color: editHabitSage,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardTitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: editHabitDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardSubtitle,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: editHabitDark.withOpacitySafe(0.52),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: editHabitDark.withOpacitySafe(0.45),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: frequencyMode == 'specificDays'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: List<Widget>.generate(7, (int index) {
                            final int day = index + 1;
                            final bool isSelected = selectedDays.contains(day);

                            return GestureDetector(
                              onTap: () => onToggleSelectedDay(day),
                              child: Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? editHabitSage
                                      : Colors.white.withOpacitySafe(0.45),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: isSelected
                                        ? editHabitSage
                                        : editHabitCamel.withOpacitySafe(0.20),
                                  ),
                                ),
                                child: Text(
                                  l10n.weekdayLetter(day),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? editHabitCream
                                        : editHabitDark.withOpacitySafe(0.42),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: showsWeeklyCheckTargetSection
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.editHabitWeeklyGoalTitle,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: editHabitDark.withOpacitySafe(0.75),
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                HabitFormStepperButton(
                                  icon: Icons.remove_rounded,
                                  onTap: onDecrementTimesPerWeek,
                                ),
                                const SizedBox(width: 8),
                                HabitFormEditableTargetValue(
                                  value: timesPerWeekTarget,
                                  onTap: onEditTimesPerWeek,
                                ),
                                const SizedBox(width: 8),
                                HabitFormStepperButton(
                                  icon: Icons.add_rounded,
                                  onTap: onIncrementTimesPerWeek,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EditHabitRoutineSection extends StatelessWidget {
  const EditHabitRoutineSection({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return GestureDetector(
      onTap: onTap,
      child: _EditSurfaceCard(
        borderColor: editHabitCamel.withOpacitySafe(0.25),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: editHabitCamel.withOpacitySafe(0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.briefcase_fill,
                size: 17,
                color: editHabitCamel.withOpacitySafe(0.95),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        l10n.createHabitRoutineTitle,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: editHabitDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacitySafe(0.72),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: editHabitCamel.withOpacitySafe(0.22),
                          ),
                        ),
                        child: Text(
                          l10n.createHabitOptionalPill,
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: editHabitDark.withOpacitySafe(0.55),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.createHabitRoutineSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: editHabitDark.withOpacitySafe(0.52),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacitySafe(0.68),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: editHabitCamel.withOpacitySafe(0.40),
                ),
              ),
              child: Text(
                l10n.createHabitComingSoon,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: editHabitCamel.withOpacitySafe(0.95),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: editHabitDark.withOpacitySafe(0.42),
            ),
          ],
        ),
      ),
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
    final String timeText = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: reminderTime.hour, minute: reminderTime.minute),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat ||
          Localizations.localeOf(context).languageCode == 'es',
    );

    return GestureDetector(
      onTap: remindersEnabled ? () => _showReminderTimeSheet(context) : null,
      child: _EditSurfaceCard(
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: editHabitCamel.withOpacitySafe(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                CupertinoIcons.bell_fill,
                size: 17,
                color: editHabitCamel.withOpacitySafe(0.95),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.createHabitReminderTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: editHabitDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    remindersEnabled
                        ? l10n.createHabitReminderEnabledSubtitle
                        : l10n.createHabitReminderDisabledSubtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: editHabitDark.withOpacitySafe(0.55),
                    ),
                  ),
                  if (remindersEnabled) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: editHabitDark.withOpacitySafe(0.90),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CupertinoSwitch(
              value: remindersEnabled,
              activeTrackColor: editHabitSage,
              onChanged: (bool value) async {
                onToggleReminders(value);
                if (value) {
                  await _showReminderTimeSheet(context);
                }
              },
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: editHabitDark.withOpacitySafe(0.42),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReminderTimeSheet(BuildContext context) async {
    final l10n = context.l10n;
    DateTime selected = reminderTime;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        final double safeBottom = MediaQuery.of(sheetContext).padding.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: editHabitCream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 292 + (safeBottom > 10 ? 10 : safeBottom),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 34,
                    height: 3,
                    decoration: BoxDecoration(
                      color: editHabitCamel.withOpacitySafe(0.24),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: Text(
                            l10n.commonCancel,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: editHabitSage,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l10n.createHabitReminderTimeTitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: editHabitDark,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          onPressed: () {
                            onReminderTimeChanged(selected);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Text(
                            l10n.createHabitDone,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: editHabitSage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.9,
                    color: editHabitCamel.withOpacitySafe(0.14),
                  ),
                  Expanded(
                    child: Transform.scale(
                      scale: 1.07,
                      child: CupertinoDatePicker(
                        mode: CupertinoDatePickerMode.time,
                        itemExtent: 36,
                        initialDateTime: reminderTime,
                        use24hFormat:
                            MediaQuery.of(context).alwaysUse24HourFormat ||
                                Localizations.localeOf(context).languageCode ==
                                    'es',
                        onDateTimeChanged: (DateTime value) {
                          selected = value;
                        },
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

    return _EditSurfaceCard(
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

class _EditSectionHeading extends StatelessWidget {
  const _EditSectionHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.authTitle.copyWith(
        fontSize: 18.5,
        color: const Color(0xFF2D160B),
      ),
    );
  }
}

class _EditSurfaceCard extends StatelessWidget {
  const _EditSurfaceCard({
    required this.child,
    this.borderColor,
  });

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacitySafe(0.58),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ?? editHabitCamel.withOpacitySafe(0.16),
        ),
      ),
      child: child,
    );
  }
}

class _EditTrackingCard extends StatelessWidget {
  const _EditTrackingCard({
    required this.title,
    required this.description,
    required this.leading,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String description;
  final Widget leading;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacitySafe(0.08)
              : Colors.white.withOpacitySafe(0.58),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? accentColor.withOpacitySafe(0.85)
                : editHabitCamel.withOpacitySafe(0.18),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor
                        : editHabitCamel.withOpacitySafe(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: leading,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: editHabitDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: editHabitDark.withOpacitySafe(0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 19,
                  height: 19,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: editHabitCream,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditSegmentOption {
  const _EditSegmentOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _EditFrequencySegmentedControl extends StatelessWidget {
  const _EditFrequencySegmentedControl({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_EditSegmentOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacitySafe(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: editHabitCamel.withOpacitySafe(0.16),
        ),
      ),
      child: Row(
        children: options.map((option) {
          final bool isSelected = option.id == selectedId;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOut,
                height: 36,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF5E855F), Color(0xFF4A754E)],
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? editHabitCream
                        : editHabitDark.withOpacitySafe(0.55),
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
