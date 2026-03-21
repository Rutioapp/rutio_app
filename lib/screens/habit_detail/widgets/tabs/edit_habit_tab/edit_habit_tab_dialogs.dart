import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../../../l10n/l10n.dart';
import 'edit_habit_tab_constants.dart';

Future<String?> showEditHabitUnitBottomSheet(
  BuildContext context, {
  required String currentUnit,
}) async {
  final customController = TextEditingController(text: currentUnit.trim());

  final selected = await showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    backgroundColor: editHabitCream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (BuildContext bottomSheetContext) {
      final l10n = bottomSheetContext.l10n;

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: editHabitCamel.withOpacitySafe(0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.editHabitUnitPickerTitle,
              style: AppTextStyles.welcomeTitle.copyWith(
                fontSize: 28,
                color: editHabitDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.editHabitUnitPickerSubtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: editHabitDark.withOpacitySafe(0.62),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: l10n.editHabitSuggestedUnits.map((String unit) {
                final isSelected = currentUnit.trim() == unit;
                return GestureDetector(
                  onTap: () => Navigator.of(bottomSheetContext).pop(unit),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? editHabitCamel.withOpacitySafe(0.12)
                          : Colors.white.withOpacitySafe(0.55),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? editHabitCamel
                            : editHabitCamel.withOpacitySafe(0.24),
                      ),
                    ),
                    child: Text(
                      unit,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: editHabitDark,
                      ),
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: customController,
              autofocus: false,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: editHabitDark,
              ),
              decoration: InputDecoration(
                hintText: l10n.editHabitTitleHint,
                hintStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: editHabitDark.withOpacitySafe(0.35),
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
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: editHabitDark,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => Navigator.of(bottomSheetContext)
                    .pop(customController.text.trim()),
                child: Text(
                  l10n.editHabitUnitPickerAction,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: editHabitCream,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  customController.dispose();
  return selected;
}

Future<void> showEditHabitNumberInputDialog(
  BuildContext context, {
  required String title,
  required int initialValue,
  required ValueChanged<int> onSubmitted,
  String? subtitle,
}) async {
  final controller = TextEditingController(text: initialValue.toString());

  await showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) {
      return CupertinoAlertDialog(
        title: Text(
          title,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: editHabitDark,
          ),
        ),
        content: Column(
          children: [
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: editHabitDark.withOpacitySafe(0.68),
                ),
              ),
            ],
            const SizedBox(height: 14),
            CupertinoTextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: editHabitDark,
              ),
              decoration: BoxDecoration(
                color: editHabitCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: editHabitCamel.withOpacitySafe(0.24)),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              context.l10n.commonCancel,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              final value =
                  _parsePositiveInt(controller.text, fallback: initialValue);
              onSubmitted(value);
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              context.l10n.commonSave,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  );

  controller.dispose();
}

int _parsePositiveInt(String raw, {required int fallback}) {
  final parsed = int.tryParse(raw.trim());
  if (parsed == null || parsed < 1) {
    return fallback;
  }
  return parsed;
}
