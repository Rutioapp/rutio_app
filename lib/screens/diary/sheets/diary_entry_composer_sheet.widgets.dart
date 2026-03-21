part of 'diary_entry_composer_sheet.dart';

const TextStyle _sectionLabelStyle = TextStyle(
  color: Color(0xFFBF9165),
  fontSize: 13,
  fontWeight: FontWeight.w600,
  letterSpacing: 2.8,
);

class _DiaryComposerContent extends StatelessWidget {
  const _DiaryComposerContent({
    required this.bottomInset,
    required this.isEditing,
    required this.formattedDate,
    required this.lockHabit,
    required this.type,
    required this.habitName,
    required this.familyName,
    required this.familyColor,
    required this.mood,
    required this.titleController,
    required this.reflectionController,
    required this.onCancel,
    required this.onTypeChanged,
    required this.onPickHabit,
    required this.onMoodChanged,
    required this.onSave,
  });

  final double bottomInset;
  final bool isEditing;
  final String formattedDate;
  final bool lockHabit;
  final dt.DiaryEntryType type;
  final String? habitName;
  final String? familyName;
  final Color? familyColor;
  final int? mood;
  final TextEditingController titleController;
  final TextEditingController reflectionController;
  final VoidCallback onCancel;
  final ValueChanged<dt.DiaryEntryType> onTypeChanged;
  final Future<void> Function() onPickHabit;
  final ValueChanged<int?> onMoodChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6EFE3),
      child: Stack(
        children: [
          const _DiaryComposerBackground(),
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFC69656),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.l10n.diaryComposerCancel,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          isEditing
                              ? context.l10n.diaryComposerEditEntryUpper
                              : context.l10n.diaryComposerNewEntryUpper,
                          style: const TextStyle(
                            color: Color(0xFFC98D4A),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formattedDate,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                            fontSize: 28,
                            height: 1.15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E1C12),
                            fontFamilyFallback: const [
                              'Georgia',
                              'Times New Roman',
                              'serif',
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _DecorativeDivider(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 42),
                  if (!lockHabit) ...[
                    _EntryTypeToggle(
                      value: type,
                      onChanged: onTypeChanged,
                    ),
                    const SizedBox(height: 22),
                  ],
                  if (type == dt.DiaryEntryType.habit) ...[
                    _HabitPickerCard(
                      habitName: habitName,
                      familyName: familyName,
                      familyColor: familyColor,
                      enabled: !lockHabit,
                      onPick: () => onPickHabit(),
                    ),
                    const SizedBox(height: 26),
                  ],
                  Text(
                    context.l10n.diaryComposerMoodSectionUpper,
                    style: _sectionLabelStyle,
                  ),
                  const SizedBox(height: 12),
                  _MoodRow(
                    value: mood,
                    onChanged: onMoodChanged,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.l10n.diaryComposerTitleUpper,
                    style: _sectionLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  _EditorialField(
                    controller: titleController,
                    hintText: context.l10n.diaryComposerTitleHint,
                    minLines: 1,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.l10n.diaryComposerReflectionUpper,
                    style: _sectionLabelStyle,
                  ),
                  const SizedBox(height: 10),
                  _EditorialField(
                    controller: reflectionController,
                    hintText: type == dt.DiaryEntryType.habit
                        ? context.l10n.diaryComposerHabitReflectionHint
                        : context.l10n.diaryComposerPersonalReflectionHint,
                    minLines: 7,
                    maxLines: 10,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF351606),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        isEditing
                            ? context.l10n.diaryComposerSaveChanges
                            : context.l10n.diaryComposerSaveEntry,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          fontFamilyFallback: const [
                            'Georgia',
                            'Times New Roman',
                            'serif',
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeDivider extends StatelessWidget {
  const _DecorativeDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 46, height: 1.5, color: const Color(0xFFE2BF92)),
        const SizedBox(width: 10),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFC98D4A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Container(width: 46, height: 1.5, color: const Color(0xFFE2BF92)),
      ],
    );
  }
}

class _DiaryComposerBackground extends StatelessWidget {
  const _DiaryComposerBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -60,
            top: 62,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x14C5D7A2), Color(0x00C5D7A2)],
                ),
              ),
            ),
          ),
          Positioned(
            left: -110,
            bottom: -70,
            child: Container(
              width: 350,
              height: 210,
              decoration: const BoxDecoration(
                color: Color(0xFFB9CAA6),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(180),
                ),
              ),
            ),
          ),
          Positioned(
            right: -70,
            bottom: -120,
            child: Container(
              width: 280,
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF9BB286),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(220),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 378,
            child: Container(
              height: 70,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00A9C28F),
                    Color(0x26A9C28F),
                    Color(0x00A9C28F),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTypeToggle extends StatelessWidget {
  const _EntryTypeToggle({
    required this.value,
    required this.onChanged,
  });

  final dt.DiaryEntryType value;
  final ValueChanged<dt.DiaryEntryType> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedHabit = value == dt.DiaryEntryType.habit;

    return Container(
      height: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF26201B), width: 1.4),
        color: Colors.white.withValues(alpha: 0.55),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TogglePill(
              title: context.l10n.diaryComposerTypeHabit,
              icon: CupertinoIcons.check_mark_circled,
              selected: selectedHabit,
              onTap: () => onChanged(dt.DiaryEntryType.habit),
            ),
          ),
          Expanded(
            child: _TogglePill(
              title: context.l10n.diaryComposerTypePersonal,
              icon: CupertinoIcons.pencil,
              selected: !selectedHabit,
              onTap: () => onChanged(dt.DiaryEntryType.personal),
            ),
          ),
        ],
      ),
    );
  }
}

class _TogglePill extends StatelessWidget {
  const _TogglePill({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF558F41) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF111111)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitPickerCard extends StatelessWidget {
  const _HabitPickerCard({
    required this.habitName,
    required this.familyName,
    required this.familyColor,
    required this.enabled,
    required this.onPick,
  });

  final String? habitName;
  final String? familyName;
  final Color? familyColor;
  final bool enabled;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final title = habitName ?? context.l10n.diaryComposerSelectHabit;
    final family = familyName ?? context.l10n.diaryComposerTapToChooseHabit;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPick : null,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD9C9B6)),
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 44,
                decoration: BoxDecoration(
                  color: familyColor ?? const Color(0xFFC98D4A),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2B1A11),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      family,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF96765A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                enabled
                    ? CupertinoIcons.chevron_right
                    : CupertinoIcons.lock_fill,
                color: const Color(0xFF7A624F),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodRow extends StatelessWidget {
  const _MoodRow({
    required this.value,
    required this.onChanged,
  });

  static const moods = [
    (-2, '\u{1F327}\uFE0F'),
    (-1, '\u{1F342}'),
    (0, '\u2601\uFE0F'),
    (1, '\u2600\uFE0F'),
    (2, '\u{1F331}'),
  ];

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final mood in moods)
          _MoodButton(
            emoji: mood.$2,
            selected: value == mood.$1,
            onTap: () => onChanged(value == mood.$1 ? null : mood.$1),
          ),
      ],
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 54,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF2E1)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFFC98D4A) : const Color(0xFFD8CAB9),
            width: selected ? 1.25 : 1,
          ),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _EditorialField extends StatelessWidget {
  const _EditorialField({
    required this.controller,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hintText;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: TextInputAction.newline,
      style: const TextStyle(
        color: Color(0xFF3B271B),
        fontSize: 20,
        height: 1.55,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.72),
        hintText: hintText,
        hintStyle: TextStyle(
          color: const Color(0xFFCDB198).withValues(alpha: 0.95),
          fontSize: 18,
          height: 1.55,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          fontFamilyFallback: const ['Georgia', 'Times New Roman', 'serif'],
        ),
        contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8CAB9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFD8CAB9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFC98D4A), width: 1.3),
        ),
      ),
    );
  }
}
