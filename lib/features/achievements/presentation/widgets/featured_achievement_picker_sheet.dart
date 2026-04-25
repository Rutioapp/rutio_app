import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../ui/foundations/ios_foundations.dart';
import '../../domain/models/achievement.dart';
import '../../domain/models/achievement_progress.dart';
import 'achievement_badge_art.dart';

Future<void> showFeaturedAchievementPickerSheet(
  BuildContext context, {
  required List<AchievementProgress> unlockedAchievements,
  required List<String> selectedIds,
  required ValueChanged<List<String>> onSave,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (sheetContext) => _FeaturedAchievementPickerSheet(
      unlockedAchievements: unlockedAchievements,
      selectedIds: selectedIds,
      onSave: onSave,
    ),
  );
}

class _FeaturedAchievementPickerSheet extends StatefulWidget {
  const _FeaturedAchievementPickerSheet({
    required this.unlockedAchievements,
    required this.selectedIds,
    required this.onSave,
  });

  final List<AchievementProgress> unlockedAchievements;
  final List<String> selectedIds;
  final ValueChanged<List<String>> onSave;

  @override
  State<_FeaturedAchievementPickerSheet> createState() =>
      _FeaturedAchievementPickerSheetState();
}

class _FeaturedAchievementPickerSheetState
    extends State<_FeaturedAchievementPickerSheet> {
  late final List<String> _selectedIds = List<String>.from(widget.selectedIds);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.18),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: IosSpacing.xs),
                Container(
                  width: 38,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.11),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.achievementsFeaturedPickerTitle,
                              style: IosTypography.title(context),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.achievementsFeaturedPickerSubtitle(
                                _selectedIds.length,
                              ),
                              style: IosTypography.caption(context),
                            ),
                          ],
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
                Expanded(
                  child: widget.unlockedAchievements.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(IosSpacing.xl),
                            child: Text(
                              l10n.achievementsFeaturedPickerEmpty,
                              textAlign: TextAlign.center,
                              style: IosTypography.body(context),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            IosSpacing.lg,
                            0,
                            IosSpacing.lg,
                            IosSpacing.lg,
                          ),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: widget.unlockedAchievements.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: IosSpacing.xs),
                          itemBuilder: (context, index) {
                            final item = widget.unlockedAchievements[index];
                            final isSelected =
                                _selectedIds.contains(item.achievement.id);
                            final canSelect =
                                isSelected || _selectedIds.length < 3;
                            final isSpecial =
                                item.achievement.type == AchievementType.special;
                            final familyName = isSpecial
                                ? l10n.achievementsSpecialLabel
                                : l10n.familyName(item.achievement.familyId);
                            final subtitle = isSpecial
                                ? item.achievement.description
                                : l10n
                                    .achievementsFeaturedPickerFamilySubtitle(
                                    familyName,
                                    item.targetValue,
                                  );

                            return CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: canSelect
                                  ? () => setState(() {
                                        if (isSelected) {
                                          _selectedIds.remove(
                                            item.achievement.id,
                                          );
                                        } else {
                                          _selectedIds.add(
                                            item.achievement.id,
                                          );
                                        }
                                      })
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.all(IosSpacing.md),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF0E7D8)
                                      : Colors.white.withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(
                                    IosCornerRadius.card,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFD9B97E)
                                        : const Color(0xFFE8DFD1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    AchievementBadgeArt(
                                      assetPath: item.achievement.assetPath,
                                      status: item.status,
                                      progress: item.progress,
                                      size: 58,
                                    ),
                                    const SizedBox(width: IosSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.achievement.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                IosTypography.body(context)
                                                    .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF241A12),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: IosTypography.caption(
                                              context,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: IosSpacing.sm),
                                    Icon(
                                      isSelected
                                          ? CupertinoIcons
                                              .check_mark_circled_solid
                                          : CupertinoIcons.circle,
                                      color: isSelected
                                          ? const Color(0xFFB48842)
                                          : const Color(0xFFCAC1B4),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    IosSpacing.lg,
                    0,
                    IosSpacing.lg,
                    IosSpacing.xl,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(18),
                      onPressed: () {
                        widget.onSave(_selectedIds);
                        Navigator.of(context).pop();
                      },
                      child: Text(l10n.commonSave),
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
