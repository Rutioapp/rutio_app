import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2MoodOption {
  const DiaryV2MoodOption({
    required this.icon,
    required this.isSelected,
  });

  final IconData icon;
  final bool isSelected;
}

class DiaryV2TodayEntryCard extends StatelessWidget {
  const DiaryV2TodayEntryCard({
    super.key,
    required this.dateLabel,
    required this.body,
    required this.chips,
    required this.moods,
  });

  final String dateLabel;
  final String body;
  final List<String> chips;
  final List<DiaryV2MoodOption> moods;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: DiaryV2Styles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DiaryV2Styles.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.book,
                  color: DiaryV2Styles.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Entrada de hoy',
                  style: DiaryV2Styles.title(context),
                ),
              ),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: DiaryV2Styles.mutedText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF3C2E25),
              fontStyle: FontStyle.italic,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Como te sientes hoy?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: DiaryV2Styles.text,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: moods
                .map(
                  (mood) => _MoodBubble(
                    icon: mood.icon,
                    isSelected: mood.isSelected,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: DiaryV2Styles.border),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips.map((chip) => _TagChip(label: chip)).toList(),
          ),
        ],
      ),
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({
    required this.icon,
    required this.isSelected,
  });

  final IconData icon;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? DiaryV2Styles.accent : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? DiaryV2Styles.accent : DiaryV2Styles.sage,
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            size: 24,
            color: isSelected ? Colors.white : DiaryV2Styles.sage,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isSelected ? 1 : 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: DiaryV2Styles.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DiaryV2Styles.sageSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: DiaryV2Styles.sage,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
