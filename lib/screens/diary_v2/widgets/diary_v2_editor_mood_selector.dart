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
    final tone = _toneForMood(moodValue);

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
                      color: selected ? tone.fill : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? tone.active : tone.base,
                        width: selected ? 1.8 : 1.1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: tone.active.withValues(alpha: 0.16),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  Text(
                    tone.emoji,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1,
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: DiaryV2Styles.accentDeep,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _MoodTone _toneForMood(int mood) {
    switch (mood) {
      case -2:
        return const _MoodTone(
          emoji: '😕',
          base: Color(0xFF92A36F),
          active: Color(0xFF7D9258),
          fill: Color(0xFFEAF1E0),
        );
      case -1:
        return const _MoodTone(
          emoji: '🙁',
          base: Color(0xFF92A36F),
          active: Color(0xFF7D9258),
          fill: Color(0xFFF1F5E9),
        );
      case 0:
        return const _MoodTone(
          emoji: '😐',
          base: DiaryV2Styles.accentDeep,
          active: DiaryV2Styles.accentDeep,
          fill: Color(0xFFF2C487),
        );
      case 1:
        return const _MoodTone(
          emoji: '🙂',
          base: Color(0xFF92A36F),
          active: Color(0xFF7D9258),
          fill: Color(0xFFF3F6ED),
        );
      case 2:
        return const _MoodTone(
          emoji: '😊',
          base: Color(0xFF92A36F),
          active: Color(0xFF7D9258),
          fill: Color(0xFFEDEFE6),
        );
      default:
        return _toneForMood(0);
    }
  }
}

class _MoodTone {
  const _MoodTone({
    required this.emoji,
    required this.base,
    required this.active,
    required this.fill,
  });

  final String emoji;
  final Color base;
  final Color active;
  final Color fill;
}
