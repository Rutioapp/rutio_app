import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2MoodOption {
  const DiaryV2MoodOption({
    required this.moodValue,
    required this.isSelected,
  });

  final int moodValue;
  final bool isSelected;
}

class DiaryV2TodayEntryCard extends StatelessWidget {
  const DiaryV2TodayEntryCard({
    super.key,
    required this.title,
    required this.dateLabel,
    required this.excerpt,
    required this.emptyTitle,
    required this.emptyBody,
    required this.moodPrompt,
    required this.chips,
    required this.moods,
    required this.isEmpty,
    this.extraEntriesLabel,
    this.onViewAllTap,
  });

  final String title;
  final String dateLabel;
  final String excerpt;
  final String emptyTitle;
  final String emptyBody;
  final String moodPrompt;
  final List<String> chips;
  final List<DiaryV2MoodOption> moods;
  final bool isEmpty;
  final String? extraEntriesLabel;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: DiaryV2Styles.cream.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(DiaryV2Styles.cardRadius),
        border: Border.all(color: DiaryV2Styles.border.withValues(alpha: 0.9)),
        boxShadow: const [
          BoxShadow(
            color: DiaryV2Styles.shadowWarm,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DiaryV2Styles.accentSoftMuted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.book,
                  color: DiaryV2Styles.accentDeep,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DiaryV2Styles.title(context).copyWith(
                      fontSize: 18,
                      color: DiaryV2Styles.textStrong,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    dateLabel,
                    maxLines: 2,
                    textAlign: TextAlign.right,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: DiaryV2Styles.mutedText,
                          fontSize: 12,
                          height: 1.2,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isEmpty
                ? const _EmptyState()
                : _Excerpt(excerpt: excerpt),
          ),
          const SizedBox(height: 16),
          Text(
            moodPrompt,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < moods.length; i++) ...[
                Expanded(
                  child: Align(
                    child: _MoodBubble(
                      moodValue: moods[i].moodValue,
                      isSelected: moods[i].isSelected,
                    ),
                  ),
                ),
                if (i != moods.length - 1) const SizedBox(width: 3),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: DiaryV2Styles.dividerWarm.withValues(alpha: 0.75),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (chip) => _TagChip(
                    label: chip,
                    accented: chip == 'Energ\u00eda' || chip == 'Energy',
                  ),
                )
                .toList(),
          ),
          if (extraEntriesLabel != null && onViewAllTap != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onViewAllTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        extraEntriesLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DiaryV2Styles.accentDeep,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: DiaryV2Styles.accentDeep,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('empty'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A\u00fan no has escrito hoy',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: DiaryV2Styles.textStrong,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cuando quieras, puedes guardar un momento, una emoci\u00f3n o una idea de tu d\u00eda.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DiaryV2Styles.mutedTextStrong,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}

class _Excerpt extends StatelessWidget {
  const _Excerpt({required this.excerpt});

  final String excerpt;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('excerpt'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '\u201c',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: DiaryV2Styles.accent.withValues(alpha: 0.7),
                fontSize: 24,
                height: 1,
              ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            excerpt,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DiaryV2Styles.textStrong,
                  fontStyle: FontStyle.italic,
                  height: 1.48,
                ),
          ),
        ),
      ],
    );
  }
}

class _MoodBubble extends StatelessWidget {
  const _MoodBubble({
    required this.moodValue,
    required this.isSelected,
  });

  final int moodValue;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final tone = _toneForMood(moodValue);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: isSelected ? tone.fill : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? tone.borderStrong : tone.border.withValues(alpha: 0.78),
              width: isSelected ? 1.6 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: tone.borderStrong.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            tone.icon,
            color: isSelected ? tone.borderStrong : tone.border,
            size: 18,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: isSelected ? 1 : 0,
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: DiaryV2Styles.accent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  _MoodTone _toneForMood(int moodValue) {
    switch (moodValue) {
      case -2:
        return const _MoodTone(
          icon: CupertinoIcons.cloud_rain,
          border: Color(0xFF9CAD7E),
          borderStrong: Color(0xFF80935F),
          fill: Color(0xFFEAF1E0),
        );
      case -1:
        return const _MoodTone(
          icon: CupertinoIcons.moon_zzz,
          border: Color(0xFF9CAD7E),
          borderStrong: Color(0xFF879A68),
          fill: Color(0xFFEFF3E7),
        );
      case 1:
        return const _MoodTone(
          icon: CupertinoIcons.sun_max,
          border: Color(0xFFB67A34),
          borderStrong: Color(0xFF9F631D),
          fill: Color(0xFFFFE9CD),
        );
      case 2:
        return const _MoodTone(
          icon: CupertinoIcons.heart_circle,
          border: Color(0xFFB67A34),
          borderStrong: Color(0xFF9F631D),
          fill: Color(0xFFFFE3BE),
        );
      default:
        return const _MoodTone(
          icon: CupertinoIcons.smiley,
          border: Color(0xFFB67A34),
          borderStrong: Color(0xFF9F631D),
          fill: Color(0xFFFFE7C9),
        );
    }
  }
}

class _MoodTone {
  const _MoodTone({
    required this.icon,
    required this.border,
    required this.borderStrong,
    required this.fill,
  });

  final IconData icon;
  final Color border;
  final Color borderStrong;
  final Color fill;
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.accented,
  });

  final String label;
  final bool accented;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: accented
            ? DiaryV2Styles.accentSoftMuted
            : DiaryV2Styles.creamStrong.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accented ? DiaryV2Styles.accentDeep : DiaryV2Styles.sage,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
      ),
    );
  }
}
