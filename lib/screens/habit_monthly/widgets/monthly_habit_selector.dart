import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

class MonthlyHabitSelector extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final String selectedHabitId;
  final Color Function(Map<String, dynamic> habit) colorResolver;
  final ValueChanged<String> onHabitSelected;

  const MonthlyHabitSelector({
    super.key,
    required this.habits,
    required this.selectedHabitId,
    required this.colorResolver,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

    final selectedHabit = habits.firstWhere(
      (habit) => (habit['id'] ?? '').toString() == selectedHabitId,
      orElse: () => habits.first,
    );

    final emoji = (selectedHabit['emoji'] ?? selectedHabit['habitEmoji'] ?? '')
        .toString()
        .trim();
    final title = (selectedHabit['name'] ??
            selectedHabit['title'] ??
            l10n.monthlyHabitFallbackTitle)
        .toString()
        .trim();
    final accent = colorResolver(selectedHabit);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              l10n.monthlyHabitSelectorTitle,
              style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
                letterSpacing: 1.7,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.46),
              ),
            ),
          ),
          // IOS-FIRST IMPROVEMENT START
          _MonthlyHabitDropdownButton(
            emoji: emoji.isEmpty ? '\u2728' : emoji,
            title: title,
            accent: accent,
            habitsCount: habits.length,
            onTap: () => _openHabitPicker(context),
          ),
          // IOS-FIRST IMPROVEMENT END
        ],
      ),
    );
  }

  Future<void> _openHabitPicker(BuildContext context) async {
    await IosFeedback.selection();
    if (!context.mounted) return;

    await showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return _MonthlyHabitPickerSheet(
          habits: habits,
          selectedHabitId: selectedHabitId,
          colorResolver: colorResolver,
          onHabitSelected: (habitId) {
            Navigator.of(sheetContext).pop();
            onHabitSelected(habitId);
          },
        );
      },
    );
  }
}

class _MonthlyHabitDropdownButton extends StatelessWidget {
  final String emoji;
  final String title;
  final Color accent;
  final int habitsCount;
  final VoidCallback onTap;

  const _MonthlyHabitDropdownButton({
    required this.emoji,
    required this.title,
    required this.accent,
    required this.habitsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(IosCornerRadius.card),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(IosCornerRadius.card),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(
            IosSpacing.md,
            IosSpacing.sm,
            IosSpacing.md,
            IosSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(IosCornerRadius.chip),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(width: IosSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (textTheme.titleMedium ?? const TextStyle()).copyWith(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha: 0.76),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$habitsCount ${l10n.monthlyStatHabitsLabel.toLowerCase()}',
                      style: IosTypography.caption(context).copyWith(
                        color: Colors.black.withValues(alpha: 0.48),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: IosSpacing.sm),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 18,
                color: Colors.black.withValues(alpha: 0.42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyHabitPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>> habits;
  final String selectedHabitId;
  final Color Function(Map<String, dynamic> habit) colorResolver;
  final ValueChanged<String> onHabitSelected;

  const _MonthlyHabitPickerSheet({
    required this.habits,
    required this.selectedHabitId,
    required this.colorResolver,
    required this.onHabitSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.14),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8FC),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: IosSpacing.xs),
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(IosCornerRadius.pill),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    IosSpacing.xl,
                    IosSpacing.md,
                    IosSpacing.xl,
                    IosSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.monthlyHabitSelectorTitle,
                          style: IosTypography.title(context),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          MaterialLocalizations.of(context).closeButtonLabel,
                          style: IosTypography.body(context).copyWith(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      IosSpacing.lg,
                      0,
                      IosSpacing.lg,
                      IosSpacing.xl,
                    ),
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: habits.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: IosSpacing.xs),
                    itemBuilder: (context, index) {
                      final habit = habits[index];
                      final id = (habit['id'] ?? '').toString();
                      final selected = id == selectedHabitId;

                      final emoji =
                          (habit['emoji'] ?? habit['habitEmoji'] ?? '')
                              .toString()
                              .trim();
                      final title = (habit['name'] ??
                              habit['title'] ??
                              l10n.monthlyHabitFallbackTitle)
                          .toString()
                          .trim();
                      final accent = colorResolver(habit);

                      return _MonthlyHabitSheetRow(
                        selected: selected,
                        emoji: emoji.isEmpty ? '\u2728' : emoji,
                        title: title,
                        accent: accent,
                        onTap: () async {
                          await IosFeedback.selection();
                          onHabitSelected(id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyHabitSheetRow extends StatelessWidget {
  final bool selected;
  final String emoji;
  final String title;
  final Color accent;
  final VoidCallback onTap;

  const _MonthlyHabitSheetRow({
    required this.selected,
    required this.emoji,
    required this.title,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: IosSpacing.md,
          vertical: IosSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(IosCornerRadius.card),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(IosCornerRadius.chip),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: IosSpacing.sm),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.76),
                ),
              ),
            ),
            const SizedBox(width: IosSpacing.sm),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: selected ? 1 : 0,
              child: Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 22,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
