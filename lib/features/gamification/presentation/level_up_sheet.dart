import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/currency/rutio_currency.dart';
import '../../../l10n/l10n.dart';
import '../domain/level_event.dart';

const Color _cream = Color(0xFFF6F2E9);
const Color _ink = Color(0xFF2F1E12);
const Color _inkSoft = Color(0xA62F1E12);
const Color _earth = Color(0xFF9E7540);

Future<T?> showLevelUpSheet<T>(
  BuildContext context, {
  required LevelEvent event,
  int? rewardAmbar,
  VoidCallback? onContinue,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierLabel: 'Level up',
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, __, ___) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: _LevelUpModal(
              event: event,
              rewardAmbar: rewardAmbar,
              onContinue: onContinue,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _LevelUpModal extends StatelessWidget {
  const _LevelUpModal({
    required this.event,
    this.rewardAmbar,
    this.onContinue,
  });

  final LevelEvent event;
  final int? rewardAmbar;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copy = _copyForEvent(context, event);
    final hasReward = (rewardAmbar ?? 0) > 0;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x262F1E12),
              blurRadius: 34,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: _earth.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _earth.withValues(alpha: 0.30),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${event.level}',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 38,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                copy.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                copy.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _inkSoft,
                  height: 1.35,
                ),
              ),
              if (hasReward) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.levelUpRewardLineWithCurrency(
                    rewardAmbar!,
                    RutioCurrency.coinEmoji,
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _earth,
                    height: 1.35,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _ink,
                    foregroundColor: _cream,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(l10n.levelUpContinueButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelUpCopy {
  const _LevelUpCopy({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

_LevelUpCopy _copyForEvent(BuildContext context, LevelEvent event) {
  final l10n = context.l10n;
  switch (event.type) {
    case LevelEventType.firstMilestone:
      return _LevelUpCopy(
        title: l10n.levelUpFirstMilestoneTitle,
        subtitle: l10n.levelUpFirstMilestoneSubtitle(event.level),
      );
    case LevelEventType.majorMilestone:
      return _LevelUpCopy(
        title: l10n.levelUpMajorMilestoneTitle,
        subtitle: l10n.levelUpMajorMilestoneSubtitle(event.level),
      );
    case LevelEventType.normalLevelUp:
      return _LevelUpCopy(
        title: l10n.levelUpNormalTitle,
        subtitle: l10n.levelUpNormalSubtitle(event.level),
      );
  }
}
