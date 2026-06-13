import 'package:flutter/material.dart';
import 'package:rutio/screens/diary_v2/diary_v2_mood_visuals.dart';

import 'diary_v2_styles.dart';

class DiaryV2DailyMoodCard extends StatelessWidget {
  const DiaryV2DailyMoodCard({
    super.key,
    required this.title,
    required this.helperText,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String title;
  final String helperText;
  final int? selectedMood;
  final Future<void> Function(int mood) onMoodSelected;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final selectedLabel = selectedMood == null
        ? null
        : DiaryMoodVisuals.labelForLocale(selectedMood!, locale);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DiaryV2Styles.textStrong,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                ),
              ),
              if (selectedLabel != null)
                _SelectedMoodBadge(
                  label: selectedLabel,
                  moodValue: selectedMood!,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            helperText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DiaryV2Styles.mutedTextStrong,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final mood in DiaryMoodVisuals.values)
                Expanded(
                  child: _MoodOptionButton(
                    moodValue: mood,
                    selected: selectedMood == mood,
                    onTap: () => onMoodSelected(mood),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MoodOptionButton extends StatelessWidget {
  const _MoodOptionButton({
    required this.moodValue,
    required this.selected,
    required this.onTap,
  });

  final int moodValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = DiaryMoodVisuals.emojiFor(moodValue);
    final tone = DiaryV2Styles.editorMoodTone(moodValue);

    return Semantics(
      button: true,
      selected: selected,
      label: DiaryMoodVisuals.semanticLabelForLocale(
        moodValue,
        Localizations.localeOf(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: selected
                        ? tone.selectedFill
                        : DiaryV2Styles.cream.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? tone.selectedBorder
                          : DiaryV2Styles.border.withValues(alpha: 0.92),
                      width: selected ? 1.8 : 1.1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: tone.selectedBorder.withValues(alpha: 0.16),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    emoji,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      fontSize: moodValue == 0 ? 19 : 18,
                      height: 1,
                      fontWeight:
                          moodValue == 0 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tone.selectedIndicator,
                      shape: BoxShape.circle,
                    ),
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

class _SelectedMoodBadge extends StatelessWidget {
  const _SelectedMoodBadge({
    required this.label,
    required this.moodValue,
  });

  final String label;
  final int moodValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DiaryMoodVisuals.fillColorFor(moodValue),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: DiaryMoodVisuals.borderColorFor(moodValue).withValues(alpha: 0.65),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DiaryMoodVisuals.borderColorFor(moodValue),
              fontWeight: FontWeight.w600,
              height: 1,
            ),
      ),
    );
  }
}
