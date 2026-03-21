import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../models/diary_entry.dart';
import '../../../stores/user_state_store.dart';
import '../models/diary_types.dart';
import '../sheets/after_complete_prompt_sheet.dart';
import '../sheets/diary_entry_composer_sheet.dart';
import '../sheets/filters_sheet.dart';

Future<bool> showDiaryDeleteConfirmationDialog(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(context.l10n.diaryDeleteEntryTitle),
      content: Text(context.l10n.diaryDeleteEntryBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(context.l10n.diaryActionDelete),
        ),
      ],
    ),
  );

  return confirmed == true;
}

void showDiaryFiltersBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => const DiaryFiltersSheet(),
  );
}

void showDiaryEntryComposerBottomSheet(
  BuildContext context, {
  DiaryEntryUi? editing,
  String? presetHabitId,
  String? presetHabitName,
  String? presetFamilyName,
  Color? presetFamilyColor,
  bool lockHabit = false,
  required String successMessage,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => DiaryEntryComposerSheet(
      editing: editing,
      presetHabitId: presetHabitId,
      presetHabitName: presetHabitName,
      presetFamilyName: presetFamilyName,
      presetFamilyColor: presetFamilyColor,
      lockHabit: lockHabit,
      onSave: (draft) {
        final store = context.read<UserStateStore>();
        final now = DateTime.now();
        final id = editing?.id ?? newDiaryEntryId();
        final createdAtRaw =
            editing?.createdAtRaw ?? now.millisecondsSinceEpoch;

        final entry = DiaryEntry.fromJson(
          <String, dynamic>{
            'id': id,
            'createdAt': createdAtRaw,
            'type': (draft.type == DiaryEntryType.habit) ? 'habit' : 'personal',
            'entryType':
                (draft.type == DiaryEntryType.habit) ? 'habit' : 'personal',
            'isHabit': draft.type == DiaryEntryType.habit,
            'text': draft.text,
            if (draft.mood != null) 'mood': draft.mood,
            if (draft.habitId != null) 'habitId': draft.habitId,
            if (draft.habitName != null) 'habitName': draft.habitName,
            if (draft.familyName != null) 'familyName': draft.familyName,
            if (draft.familyColor != null)
              'familyColor': draft.familyColor!.toARGB32(),
          },
        );

        if (editing == null) {
          store.addDiaryEntry(entry);
        } else {
          store.updateDiaryEntry(entry);
        }

        Navigator.of(sheetContext).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      },
    ),
  );
}

String newDiaryEntryId() => DateTime.now().microsecondsSinceEpoch.toString();

Future<void> showAfterHabitCompleteNotePrompt(
  BuildContext context, {
  required String habitId,
  required String habitName,
  required String familyName,
  required Color familyColor,
}) async {
  final wantsToWrite = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (_) => AfterCompletePromptSheet(
      habitName: habitName,
      familyColor: familyColor,
    ),
  );

  if (!context.mounted || wantsToWrite != true) return;

  showDiaryEntryComposerBottomSheet(
    context,
    presetHabitId: habitId,
    presetHabitName: habitName,
    presetFamilyName: familyName,
    presetFamilyColor: familyColor,
    lockHabit: true,
    successMessage: context.l10n.diaryNoteSaved,
  );
}
