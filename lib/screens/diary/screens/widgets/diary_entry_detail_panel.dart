import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

class DiaryEntryDetailPanel extends StatelessWidget {
  const DiaryEntryDetailPanel({
    super.key,
    required this.moodEmoji,
    required this.familyEmoji,
    required this.familyColor,
    required this.title,
    required this.dateLabel,
    required this.bodyText,
    required this.leadingMeta,
    required this.trailingMeta,
    required this.familyLabel,
    required this.isHabit,
    required this.typeLabel,
  });

  final String moodEmoji;
  final String familyEmoji;
  final Color familyColor;
  final String title;
  final String dateLabel;
  final String bodyText;
  final String leadingMeta;
  final String trailingMeta;
  final String familyLabel;
  final bool isHabit;
  final String typeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFEEDFD2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MoodChip(moodEmoji: moodEmoji),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _TagChip(
                        label: '$familyEmoji $familyLabel',
                        background: familyColor.withValues(alpha: 0.13),
                        foreground: familyColor,
                      ),
                      _TagChip(
                        label: typeLabel,
                        background: const Color(0xFFF4E9DD),
                        foreground: const Color(0xFFA37B55),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StreakPill(label: isHabit ? '4' : '\u2022'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineMedium?.copyWith(
                color: const Color(0xFF2C1E18),
                fontWeight: FontWeight.w700,
                height: 1.04,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: textTheme.titleMedium?.copyWith(
                color: const Color(0xFF8B6C58),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 52,
              height: 2,
              decoration: BoxDecoration(
                color: familyColor.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            _NotesCard(
              title: l10n.diaryDetailNotesUpper,
              counter: '${bodyText.characters.length} / 140',
              bodyText: bodyText,
            ),
            const SizedBox(height: 12),
            _WeekCard(familyColor: familyColor),
            const SizedBox(height: 18),
            Center(
              child: Text(
                l10n.diaryDetailLoggedAt(trailingMeta),
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFFC0A794),
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

class _MoodChip extends StatelessWidget {
  const _MoodChip({required this.moodEmoji});

  final String moodEmoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEAD7C6)),
      ),
      child: Text(
        moodEmoji,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFF8C2B),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26FF8C2B),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u26A1', style: TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.title,
    required this.counter,
    required this.bodyText,
  });

  final String title;
  final String counter;
  final String bodyText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECDDCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFA67E5A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
              ),
              const Spacer(),
              Text(
                counter,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFC0A794),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bodyText,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFD0B4A0),
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.familyColor});

  final Color familyColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels =
        List<String>.generate(7, (index) => l10n.weekdayLetter(index + 1));
    final subt = List<String>.generate(
      7,
      (index) => index == 6
          ? l10n.diaryTodayUpper
          : l10n.weekdayShort(index + 1).toUpperCase(),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFECDDCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.diaryDetailThisWeekUpper,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFFA67E5A),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
              ),
              const Spacer(),
              Text(
                '4 / 7',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF5B3A25),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 12) / 7;
              return Row(
                children: List.generate(labels.length, (index) {
                  final isToday = index == labels.length - 1;
                  final isDone =
                      index == 0 || index == 1 || index == 3 || index == 5;
                  final bg = isToday
                      ? const Color(0xFF5B3119)
                      : isDone
                          ? familyColor.withValues(alpha: 0.72)
                          : Colors.white;
                  final fg = isToday || isDone
                      ? Colors.white
                      : const Color(0xFFD0B4A0);
                  final border = isDone || isToday
                      ? Colors.transparent
                      : const Color(0xFFECDDCF);

                  return SizedBox(
                    width: itemWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bg,
                            shape: BoxShape.circle,
                            border: Border.all(color: border),
                          ),
                          child: Text(
                            labels[index],
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subt[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFFBEA28D),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: 4 / 7,
              minHeight: 4,
              backgroundColor: const Color(0xFFF0E4D8),
              valueColor: AlwaysStoppedAnimation<Color>(
                familyColor.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
