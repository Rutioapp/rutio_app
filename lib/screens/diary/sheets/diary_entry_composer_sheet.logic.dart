part of 'diary_entry_composer_sheet.dart';

const String _fallbackFamilyId = 'general';

String _familyNameOf(BuildContext context, String? rawId) {
  final id = (rawId ?? _fallbackFamilyId).trim();
  if (id == 'general') return context.l10n.diaryGeneralFamilyName;
  return context.l10n.familyName(id);
}

Color _familyColorOf(String? rawId) {
  final id = (rawId ?? _fallbackFamilyId).trim();
  switch (id) {
    case 'mind':
      return const Color(0xFF8E75FF);
    case 'spirit':
      return const Color(0xFF7BC8B6);
    case 'body':
      return const Color(0xFFFF8A65);
    case 'emotional':
      return const Color(0xFFFF6FAE);
    case 'social':
      return const Color(0xFF64B5F6);
    case 'discipline':
      return const Color(0xFFB0BEC5);
    case 'professional':
      return const Color(0xFFFFD54F);
    case 'general':
    default:
      return const Color(0xFFB39DDB);
  }
}

(String, String) _splitInitialText(String value) {
  if (value.isEmpty) return ('', '');

  final parts = value.split(RegExp(r'\n\s*\n'));
  if (parts.length >= 2) {
    return (parts.first.trim(), parts.sublist(1).join('\n\n').trim());
  }

  return ('', value);
}

String _composeDiaryText({
  required String title,
  required String reflection,
}) {
  final trimmedTitle = title.trim();
  final trimmedReflection = reflection.trim();

  return [
    if (trimmedTitle.isNotEmpty) trimmedTitle,
    if (trimmedReflection.isNotEmpty) trimmedReflection,
  ].join('\n\n').trim();
}

void _showComposerSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

DiaryEntryComposerDraft? _buildDiaryDraft({
  required BuildContext context,
  required dt.DiaryEntryType type,
  required String title,
  required String reflection,
  required int? mood,
  required String? habitId,
  required String? habitName,
  required String? familyName,
  required Color? familyColor,
}) {
  final text = _composeDiaryText(title: title, reflection: reflection);
  if (text.isEmpty) {
    _showComposerSnackBar(
      context,
      context.l10n.diaryComposerWriteSomethingError,
    );
    return null;
  }

  if (type == dt.DiaryEntryType.habit &&
      (habitId == null || habitName == null)) {
    _showComposerSnackBar(context, context.l10n.diaryComposerSelectHabitError);
    return null;
  }

  return DiaryEntryComposerDraft(
    type: type,
    text: text,
    mood: mood,
    habitId: type == dt.DiaryEntryType.habit ? habitId : null,
    habitName: type == dt.DiaryEntryType.habit ? habitName : null,
    familyName: type == dt.DiaryEntryType.habit ? familyName : null,
    familyColor: type == dt.DiaryEntryType.habit ? familyColor : null,
  );
}

_HabitPickOption _habitPickFromData(BuildContext context, dynamic rawHabit) {
  final habit = rawHabit is Map ? rawHabit : const <Object?, Object?>{};
  final id = (habit['id'] ?? habit['habitId'] ?? habit['uuid'] ?? habit['key'])
          ?.toString() ??
      '';
  final name =
      (habit['name'] ?? habit['title'] ?? habit['label'])?.toString() ??
          context.l10n.habitStatsHabitFallbackTitle;
  final familyId =
      (habit['familyId'] ?? habit['family'] ?? habit['familyKey'])?.toString();
  final resolvedFamilyId = familyId ?? _fallbackFamilyId;

  return _HabitPickOption(
    id: id,
    name: name,
    familyId: familyId,
    familyName: _familyNameOf(context, resolvedFamilyId),
    familyColor: _familyColorOf(resolvedFamilyId),
  );
}

Future<_HabitPickOption?> _showHabitPickerSheet(BuildContext context) async {
  final store = context.read<UserStateStore>();
  final habits = store.activeHabits;

  if (habits.isEmpty) {
    _showComposerSnackBar(
      context,
      context.l10n.diaryComposerNoActiveHabits,
    );
    return null;
  }

  return showModalBottomSheet<_HabitPickOption>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFF8F3EA),
    builder: (sheetContext) {
      final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;

      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Text(
                  context.l10n.diaryComposerSelectHabitSheetTitle,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: habits.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (itemContext, index) {
                    final pick = _habitPickFromData(context, habits[index]);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: pick.familyColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        pick.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        pick.familyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(itemContext).pop(pick),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
