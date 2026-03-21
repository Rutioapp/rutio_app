import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../models/diary_types.dart';
import '../../../stores/user_state_store.dart';
import '../../../utils/family_theme.dart';
import 'widgets/diary_entry_detail_panel.dart';

enum DiaryEntryDetailAction { edit, delete }

class DiaryEntryDetailScreen extends StatelessWidget {
  const DiaryEntryDetailScreen({super.key, required this.entry});

  final DiaryEntryUi entry;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStateStore>();
    final vm = _DiaryEntryDetailVm.from(
        entry: entry, store: store, l10n: context.l10n);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0E7),
      body: Stack(
        children: [
          const Positioned.fill(child: _DetailBackground()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: CupertinoIcons.back,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              vm.topLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFFB0825A),
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.l10n.diaryDetailScreenTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF2F190F),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      _CircleIconButton(
                        icon: CupertinoIcons.ellipsis_vertical,
                        onTap: () => _showActions(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: DiaryEntryDetailPanel(
                      moodEmoji: vm.moodEmoji,
                      familyEmoji: vm.familyEmoji,
                      familyColor: vm.familyColor,
                      title: vm.title,
                      dateLabel: vm.dayLabel,
                      bodyText: vm.bodyText,
                      leadingMeta: vm.leadingMeta,
                      trailingMeta: vm.timeLabel,
                      familyLabel: vm.familyLabel,
                      isHabit: vm.isHabit,
                      typeLabel: vm.typeLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(BuildContext context) async {
    final action = await showMenu<DiaryEntryDetailAction>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 80, 16, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      items: [
        PopupMenuItem(
          value: DiaryEntryDetailAction.edit,
          child: Row(
            children: [
              Icon(CupertinoIcons.pencil, size: 18),
              SizedBox(width: 10),
              Text(context.l10n.diaryActionEdit),
            ],
          ),
        ),
        PopupMenuItem(
          value: DiaryEntryDetailAction.delete,
          child: Row(
            children: [
              Icon(CupertinoIcons.trash, size: 18, color: Colors.red),
              SizedBox(width: 10),
              Text(context.l10n.diaryActionDelete),
            ],
          ),
        ),
      ],
    );

    if (action != null && context.mounted) {
      Navigator.of(context).pop(action);
    }
  }
}

class _DiaryEntryDetailVm {
  const _DiaryEntryDetailVm({
    required this.isHabit,
    required this.topLabel,
    required this.title,
    required this.dayLabel,
    required this.bodyText,
    required this.leadingMeta,
    required this.timeLabel,
    required this.moodEmoji,
    required this.familyColor,
    required this.familyLabel,
    required this.familyEmoji,
    required this.typeLabel,
    required this.bottomCta,
  });

  final bool isHabit;
  final String topLabel;
  final String title;
  final String dayLabel;
  final String bodyText;
  final String leadingMeta;
  final String timeLabel;
  final String moodEmoji;
  final Color familyColor;
  final String familyLabel;
  final String familyEmoji;
  final String typeLabel;
  final String bottomCta;

  factory _DiaryEntryDetailVm.from({
    required DiaryEntryUi entry,
    required UserStateStore store,
    required AppLocalizations l10n,
  }) {
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

    final familyId = (resolvedFamilyId != null && resolvedFamilyId.isNotEmpty)
        ? resolvedFamilyId.toLowerCase()
        : FamilyTheme.fallbackId;

    final familyLabel = isHabit
        ? (resolvedFamilyName?.isNotEmpty == true
            ? resolvedFamilyName!
            : l10n.familyName(familyId))
        : l10n.diaryDetailFamilyPersonal;
    final familyColor = isHabit
        ? (resolvedFamilyColor ?? FamilyTheme.colorOf(familyId))
        : const Color(0xFFC98A47);

    return _DiaryEntryDetailVm(
      isHabit: isHabit,
      topLabel: isHabit
          ? l10n.diaryDetailTopHabitUpper
          : l10n.diaryDetailTopPersonalUpper,
      title: isHabit
          ? ((resolvedHabitName?.isNotEmpty ?? false)
              ? resolvedHabitName!
              : l10n.diaryDetailFallbackHabitTitle)
          : l10n.diaryDetailFallbackPersonalTitle,
      dayLabel: l10n.diaryDetailDate(entry.createdAt),
      bodyText: entry.text,
      leadingMeta: isHabit
          ? ((resolvedHabitName?.isNotEmpty ?? false)
              ? resolvedHabitName!
              : familyLabel)
          : l10n.diaryDetailLeadingPersonal,
      timeLabel: entry.timeLabel,
      moodEmoji: _moodEmoji(entry.mood, isHabit: isHabit),
      familyColor: familyColor,
      familyLabel: familyLabel,
      familyEmoji: isHabit ? FamilyTheme.emojiOf(familyId) : '\u270D\uFE0F',
      typeLabel:
          isHabit ? l10n.diaryDetailTypeHabit : l10n.diaryDetailTypePersonal,
      bottomCta: '\u2713',
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.84),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF3A2B24), size: 20),
        ),
      ),
    );
  }
}

class _DetailBackground extends StatelessWidget {
  const _DetailBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F0E7),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            bottom: -28,
            child: Container(
              width: 180,
              height: 140,
              decoration: BoxDecoration(
                color: Color(0xFFE7DCCF),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(120)),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 94,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x1BC1D39C), Color(0x00C1D39C)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _moodEmoji(int? mood, {required bool isHabit}) {
  switch (mood) {
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
      return isHabit ? '\uD83C\uDF31' : '\u270D\uFE0F';
  }
}
