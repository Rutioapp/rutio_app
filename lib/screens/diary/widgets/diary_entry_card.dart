import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../stores/user_state_store.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/family_theme.dart';
import '../models/diary_types.dart';

class DiaryEntryCard extends StatefulWidget {
  const DiaryEntryCard({
    super.key,
    required this.store,
    required this.entry,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  });

  final UserStateStore store;
  final DiaryEntryUi entry;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  @override
  State<DiaryEntryCard> createState() => _DiaryEntryCardState();
}

class _DiaryEntryCardState extends State<DiaryEntryCard> {
  bool _expanded = false;

  bool get _shouldShowMore {
    final t = widget.entry.text.trim();
    if (t.length > 125) return true;
    return '\n'.allMatches(t).length >= 2;
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isHabit = entry.type == DiaryEntryType.habit;
    final l10n = context.l10n;
    final resolved = _resolveEntryMeta(context, widget.store, entry);
    final accent = resolved.familyColor;
    final title =
        isHabit ? resolved.title : l10n.diaryDetailFallbackPersonalTitle;
    final entryEmoji = _entryEmoji(entry);

    return IntrinsicHeight(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(30),
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 42,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Positioned(
                      top: 16,
                      bottom: 14,
                      child: Container(
                        width: 0.8,
                        color: const Color(0xFFD9C7B1).withValues(alpha: 0.34),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8EF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE4D3BE)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14B08B68),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: entryEmoji != null
                              ? Text(
                                  entryEmoji,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12.5, height: 1),
                                )
                              : Icon(
                                  CupertinoIcons.bolt_fill,
                                  size: 12,
                                  color: accent,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF8),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x082E2118),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF0E4D7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.authTitle.copyWith(
                                fontSize: 23,
                                height: 1.12,
                                color: const Color(0xFF3D2A1F),
                                letterSpacing: -0.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _TypeBadge(
                            label: isHabit
                                ? l10n.diaryCardTypeHabitShort
                                : l10n.diaryCardTypePersonalShort,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        entry.text,
                        maxLines: _expanded ? null : 2,
                        overflow: _expanded
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF8B7465),
                              height: 1.45,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 118,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: SizedBox(
                            height: 6,
                            child: Stack(
                              children: [
                                Container(color: const Color(0xFFE6DACB)),
                                FractionallySizedBox(
                                  widthFactor: _progressFactor(entry.text),
                                  alignment: Alignment.centerLeft,
                                  child: Container(color: accent),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.centerLeft,
                            child: entryEmoji != null
                                ? Text(
                                    entryEmoji,
                                    style: const TextStyle(
                                        fontSize: 15, height: 1),
                                  )
                                : Icon(
                                    CupertinoIcons.bolt_fill,
                                    size: 12,
                                    color: accent,
                                  ),
                          ),
                          const Spacer(),
                          Text(
                            entry.timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                      if (_shouldShowMore) ...[
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            splashColor: accent.withValues(alpha: 0.10),
                            highlightColor: accent.withValues(alpha: 0.05),
                            onTap: () => setState(() => _expanded = !_expanded),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.18),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _expanded
                                        ? l10n.diaryShowLess
                                        : l10n.diaryShowMore,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    _expanded
                                        ? CupertinoIcons.chevron_up_circle_fill
                                        : CupertinoIcons
                                            .chevron_down_circle_fill,
                                    size: 16,
                                    color: accent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _entryEmoji(DiaryEntryUi entry) {
  switch (entry.mood) {
    case -2:
      return '\uD83C\uDF27\uFE0F';
    case -1:
      return '\uD83C\uDF42';
    case 0:
      return '\u2601\uFE0F';
    case 1:
      return '\u2600\uFE0F';
    case 2:
      return '\uD83C\uDF31';
    default:
      return null;
  }
}

_ResolvedEntryMeta _resolveEntryMeta(
  BuildContext context,
  UserStateStore store,
  DiaryEntryUi entry,
) {
  final isHabit = entry.type == DiaryEntryType.habit;

  String? resolvedHabitName = entry.habitName?.trim();
  String? resolvedFamilyId;
  String? resolvedFamilyName = entry.familyName?.trim();
  Color? resolvedFamilyColor = entry.familyColor;

  if (isHabit && entry.habitId != null && entry.habitId!.trim().isNotEmpty) {
    final habit = store.getActiveHabitById(entry.habitId!.trim());
    if (habit is Map) {
      final map = habit.cast<String, dynamic>();
      resolvedHabitName ??=
          (map['name'] ?? map['title'] ?? map['label'])?.toString().trim();
      resolvedFamilyId ??=
          (map['familyId'] ?? map['family'] ?? map['familyKey'])
              ?.toString()
              .trim();
    }
  }

  if (isHabit) {
    final fid = (resolvedFamilyId != null && resolvedFamilyId.isNotEmpty)
        ? resolvedFamilyId.toLowerCase()
        : FamilyTheme.fallbackId;

    resolvedFamilyName ??= context.l10n.familyName(fid);
    resolvedFamilyColor ??= FamilyTheme.colorOf(fid);
  }

  return _ResolvedEntryMeta(
    title: resolvedHabitName?.isNotEmpty == true
        ? resolvedHabitName!
        : context.l10n.diaryDetailFallbackHabitTitle,
    familyName: resolvedFamilyName?.isNotEmpty == true
        ? resolvedFamilyName!
        : context.l10n.familyName(FamilyTheme.fallbackId),
    familyColor:
        resolvedFamilyColor ?? FamilyTheme.colorOf(FamilyTheme.fallbackId),
  );
}

class _ResolvedEntryMeta {
  const _ResolvedEntryMeta({
    required this.title,
    required this.familyName,
    required this.familyColor,
  });

  final String title;
  final String familyName;
  final Color familyColor;
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5ECDF).withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC08B56),
              fontWeight: FontWeight.w700,
              fontSize: 9,
              letterSpacing: 0.45,
            ),
      ),
    );
  }
}

double _progressFactor(String text) {
  final len = text.trim().length;
  if (len <= 20) return 0.35;
  if (len <= 60) return 0.52;
  if (len <= 120) return 0.68;
  if (len <= 220) return 0.82;
  return 0.92;
}
