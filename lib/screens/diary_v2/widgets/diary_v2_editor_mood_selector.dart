import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2EditorMoodSelector extends StatelessWidget {
  const DiaryV2EditorMoodSelector({
    super.key,
    required this.title,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  final String title;
  final int? selectedMood;
  final ValueChanged<int> onMoodSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 11),
      decoration: DiaryV2Styles.compactCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final mood in const [-2, -1, 0, 1, 2])
                Expanded(
                  child: _MoodButton(
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

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.moodValue,
    required this.selected,
    required this.onTap,
  });

  final int moodValue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final moodFace = _faceForMood(moodValue);
    final selectorTone = DiaryV2Styles.editorMoodTone(moodValue);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? selectorTone.selectedFill
                          : DiaryV2Styles.cream.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected
                            ? selectorTone.selectedBorder
                            : DiaryV2Styles.border.withValues(alpha: 0.92),
                        width: selected ? 1.8 : 1.1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color:
                                    selectorTone.selectedBorder.withValues(alpha: 0.14),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      moodFace,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: selected ? 1 : 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectorTone.selectedIndicator,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _faceForMood(int mood) {
    switch (mood) {
      case -2:
        return '\u{1F615}';
      case -1:
        return '\u{1F641}';
      case 0:
        return '\u{1F610}';
      case 1:
        return '\u{1F642}';
      case 2:
        return '\u{1F60A}';
      default:
        return _faceForMood(0);
    }
  }
}
