import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/currency/rutio_currency.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/app_theme.dart';
import '../domain/level_event.dart';

const Color _cream = AppColors.cream;
const Color _ink = Color(0xFF2B1A10);
const Color _earth = AppColors.earth;
const Color _earthSoft = Color(0xFFB8895A);
const Color _cardBorder = Color(0x2C9E7540);

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
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, __, ___) {
      return SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.34),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 20,
                ),
                child: _LevelUpModal(
                  event: event,
                  rewardAmbar: rewardAmbar,
                  onContinue: onContinue,
                ),
              ),
            ),
          ],
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
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
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
    final hasReward = (rewardAmbar ?? 0) > 0;
    final subtitle = l10n.levelUpNormalSubtitle(event.level);
    final highlightedChunk = _highlightedLevelChunk(context, event.level);
    final subtitleParts = _splitAroundChunk(subtitle, highlightedChunk);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _cream,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: _cardBorder, width: 0.9),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F2F1E12),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _earth.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _earth.withValues(alpha: 0.32),
                    width: 0.9,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.leaf_arrow_circlepath,
                  size: 20,
                  color: _earthSoft,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.levelUpNormalTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 0.98,
                ),
              ),
              const SizedBox(height: 10),
              if (subtitleParts != null)
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: _ink,
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(text: subtitleParts.$1),
                      TextSpan(
                        text: subtitleParts.$2,
                        style: GoogleFonts.dmSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: _earthSoft,
                          height: 1.25,
                        ),
                      ),
                      TextSpan(text: subtitleParts.$3),
                    ],
                  ),
                )
              else
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                    height: 1.25,
                  ),
                ),
              const SizedBox(height: 18),
              _LevelChip(level: event.level),
              if (hasReward) ...[
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 7,
                  runSpacing: 6,
                  children: [
                    Text(
                      _rewardLineText(
                        l10n: l10n,
                        amount: rewardAmbar!,
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _ink,
                        height: 1.2,
                      ),
                    ),
                    const _RutioCoinMark(size: 21),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue?.call();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _earthSoft,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: Colors.black.withValues(alpha: 0.11),
                    elevation: 1,
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.05,
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

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _earthSoft,
        border: Border.all(color: _earth.withValues(alpha: 0.34), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$level',
        style: GoogleFonts.cormorantGaramond(
          fontSize: 70,
          fontWeight: FontWeight.w700,
          height: 0.95,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0x33000000),
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class _RutioCoinMark extends StatelessWidget {
  const _RutioCoinMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.34),
          radius: 0.96,
          colors: [
            Colors.white,
            _earth.withValues(alpha: 0.84),
            const Color(0xFF8A6232),
          ],
          stops: const [0.0, 0.66, 1.0],
        ),
        border: Border.all(
          color: _earth.withValues(alpha: 0.52),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: _earth.withValues(alpha: 0.16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        RutioCurrency.coinSymbol,
        style: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: size * 0.54,
          height: 1,
          color: _ink,
        ),
      ),
    );
  }
}

String _highlightedLevelChunk(BuildContext context, int level) {
  final levelLabel = context.l10n.userLevelLabel.toLowerCase();
  return '$levelLabel $level';
}

(String, String, String)? _splitAroundChunk(String text, String chunk) {
  final lowerText = text.toLowerCase();
  final lowerChunk = chunk.toLowerCase();
  final start = lowerText.indexOf(lowerChunk);
  if (start < 0) return null;
  final end = start + chunk.length;
  return (
    text.substring(0, start),
    text.substring(start, end),
    text.substring(end),
  );
}

String _rewardLineText({
  required AppLocalizations l10n,
  required int amount,
}) {
  final raw = l10n.levelUpRewardLineWithCurrency(
    amount,
    RutioCurrency.coinSymbol,
  );
  final cleaned = raw.replaceAll(
    RegExp('\\s*${RegExp.escape(RutioCurrency.coinSymbol)}\\.?\\s*\$'),
    '',
  );
  return cleaned.trim();
}
