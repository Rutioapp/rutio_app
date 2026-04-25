import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/models/achievement.dart';

const Color _cream = Color(0xFFF5EDE0);
const Color _camel = Color(0xFFB8895A);
const Color _darkBrown = Color(0xFF3D2010);
const Color _amber = Color(0xFFC9A84C);

Future<T?> showAchievementUnlockSheet<T>(
  BuildContext context, {
  required Achievement achievement,
  required VoidCallback onViewAchievements,
  VoidCallback? onShare,
  VoidCallback? onContinue,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: _cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
    ),
    builder: (_) => AchievementUnlockSheet(
      achievement: achievement,
      onViewAchievements: onViewAchievements,
      onShare: onShare,
      onContinue: onContinue,
    ),
  );
}

class AchievementUnlockSheet extends StatelessWidget {
  const AchievementUnlockSheet({
    super.key,
    required this.achievement,
    required this.onViewAchievements,
    this.onShare,
    this.onContinue,
  });

  final Achievement achievement;
  final VoidCallback onViewAchievements;
  final VoidCallback? onShare;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return _AnimatedSheetContent(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.84,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + safeBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                _AchievementHeader(achievement: achievement),
                const SizedBox(height: 24),
                _AchievementBadge(achievement: achievement),
                const SizedBox(height: 24),
                _RewardPillsRow(
                  xpReward: achievement.xpReward,
                  ambarReward: achievement.ambarReward,
                ),
                if (achievement.collection != null) ...[
                  const SizedBox(height: 20),
                  _CollectionProgressCard(collection: achievement.collection!),
                ],
                const SizedBox(height: 20),
                _AchievementActions(
                  onViewAchievements: () {
                    Navigator.of(context).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onViewAchievements();
                    });
                  },
                  onShare: onShare,
                  onContinue: () {
                    Navigator.of(context).pop();
                    if (onContinue != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onContinue!();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedSheetContent extends StatefulWidget {
  const _AnimatedSheetContent({required this.child});

  final Widget child;

  @override
  State<_AnimatedSheetContent> createState() => _AnimatedSheetContentState();
}

class _AnimatedSheetContentState extends State<_AnimatedSheetContent> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.03),
        child: widget.child,
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: _darkBrown.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _AchievementHeader extends StatelessWidget {
  const _AchievementHeader({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          context.l10n.achievementsOverlayTitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _camel,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '“${achievement.name}”',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _darkBrown,
            height: 1.18,
          ),
        ),
      ],
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Insignia del logro ${achievement.name}',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Center(
          child: SizedBox(
            width: 112,
            height: 112,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _camel.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _amber.withValues(alpha: 0.10),
                    border: Border.all(
                      color: const Color(0x66C9A84C),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        achievement.badgeAssetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const _BadgeFallbackIcon(),
                      ),
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

class _BadgeFallbackIcon extends StatelessWidget {
  const _BadgeFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.rosette,
        size: 36,
        color: _camel.withValues(alpha: 0.72),
      ),
    );
  }
}

class _RewardPillsRow extends StatelessWidget {
  const _RewardPillsRow({
    required this.xpReward,
    required this.ambarReward,
  });

  final int xpReward;
  final int ambarReward;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Recompensas del logro',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          _RewardPill.xp(value: xpReward),
          _RewardPill.ambar(value: ambarReward),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill._({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.leading,
    required this.semanticsLabel,
  });

  factory _RewardPill.xp({required int value}) {
    return _RewardPill._(
      label: '+$value XP',
      textColor: _darkBrown,
      backgroundColor: _darkBrown.withValues(alpha: 0.06),
      borderColor: _darkBrown.withValues(alpha: 0.10),
      leading: const _XpStarIcon(color: _darkBrown),
      semanticsLabel: 'Recompensa de experiencia: +$value XP',
    );
  }

  factory _RewardPill.ambar({required int value}) {
    return _RewardPill._(
      label: '+$value Ámbar',
      textColor: const Color(0xFFA07820),
      backgroundColor: _amber.withValues(alpha: 0.10),
      borderColor: _amber.withValues(alpha: 0.32),
      leading: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: _amber,
          shape: BoxShape.circle,
        ),
      ),
      semanticsLabel: 'Recompensa de ámbar: +$value Ámbar',
    );
  }

  final String label;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final Widget leading;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpStarIcon extends StatelessWidget {
  const _XpStarIcon({required this.color});

  final Color color;

  static const String _starSvg = '''
<svg width="13" height="13" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M7 1L8.5 5H13L9.5 7.5L11 12L7 9.5L3 12L4.5 7.5L1 5H5.5L7 1Z" fill="currentColor"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _starSvg,
      width: 13,
      height: 13,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _CollectionProgressCard extends StatelessWidget {
  const _CollectionProgressCard({required this.collection});

  final AchievementCollection collection;

  @override
  Widget build(BuildContext context) {
    final safeTotal = collection.totalCount <= 0 ? 1 : collection.totalCount;
    final safeUnlocked = collection.unlockedCount.clamp(0, safeTotal);
    final progress = _clampProgress(safeUnlocked / safeTotal);

    return Semantics(
      container: true,
      label:
          'Progreso de colección: $safeUnlocked de $safeTotal logros desbloqueados',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _camel.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _camel.withValues(alpha: 0.18),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: collection.familyColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    collection.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _camel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$safeUnlocked / $safeTotal',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _camel.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _CollectionDotsRow(
              familyColor: collection.familyColor,
              totalCount: safeTotal,
              unlockedCount: safeUnlocked,
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _camel.withValues(alpha: 0.15),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: collection.familyColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionDotsRow extends StatelessWidget {
  const _CollectionDotsRow({
    required this.familyColor,
    required this.totalCount,
    required this.unlockedCount,
  });

  final Color familyColor;
  final int totalCount;
  final int unlockedCount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(totalCount, (index) {
          final isUnlocked = index < unlockedCount;
          final isLatestUnlocked = unlockedCount > 0 && index == unlockedCount - 1;
          final size = isLatestUnlocked ? 22.0 : 20.0;

          return Padding(
            padding: EdgeInsets.only(right: index == totalCount - 1 ? 0 : 6),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: isLatestUnlocked ? 0.92 : 1, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? familyColor.withValues(alpha: isLatestUnlocked ? 1 : 0.75)
                      : _darkBrown.withValues(alpha: 0.07),
                  border: isUnlocked
                      ? null
                      : Border.all(
                          color: _camel.withValues(alpha: 0.20),
                        ),
                  boxShadow: isLatestUnlocked
                      ? [
                          BoxShadow(
                            color: familyColor.withValues(alpha: 0.30),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AchievementActions extends StatelessWidget {
  const _AchievementActions({
    required this.onViewAchievements,
    required this.onContinue,
    this.onShare,
  });

  final VoidCallback onViewAchievements;
  final VoidCallback onContinue;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final secondaryShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );

    return Column(
      children: [
        Semantics(
          button: true,
          label: 'Ver mis logros',
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewAchievements,
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: _darkBrown,
                foregroundColor: _cream,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                textStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Ver mis logros'),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: 'Compartir logro',
                child: OutlinedButton(
                  onPressed: onShare,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: _camel,
                    disabledForegroundColor: _camel.withValues(alpha: 0.45),
                    side: BorderSide(
                      color: _camel.withValues(alpha: 0.35),
                      width: 0.7,
                    ),
                    shape: secondaryShape,
                    backgroundColor: Colors.transparent,
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Compartir'),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Continuar',
                child: TextButton(
                  onPressed: onContinue,
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: _darkBrown.withValues(alpha: 0.35),
                    shape: secondaryShape,
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: const Text('Continuar'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

double _clampProgress(double value) {
  if (value.isNaN || value.isInfinite) return 0;
  return value.clamp(0, 1).toDouble();
}
