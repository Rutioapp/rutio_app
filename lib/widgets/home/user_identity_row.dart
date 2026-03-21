import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/avatar/avatar_with_xp_ring.dart';

class UserIdentityRow extends StatelessWidget {
  final String username;
  final int level;
  final int coins;
  final double xpProgress;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const UserIdentityRow({
    super.key,
    required this.username,
    required this.level,
    required this.coins,
    required this.xpProgress,
    this.avatarUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _UserIdentityPalette.resolve(context);
    final l10n = context.l10n;
    final safeUsername =
        username.trim().isEmpty ? l10n.homeFallbackUsername : username.trim();
    final numberFormat =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: palette.textPrimary.withValues(alpha: 0.05),
        highlightColor: palette.textPrimary.withValues(alpha: 0.025),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarWithXpRing(
                avatarUrl: avatarUrl,
                fallbackLabel: safeUsername,
                progress: xpProgress,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeUsername,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DMSerifDisplay',
                        fontSize: 18,
                        height: 1.0,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.userLevelShort(level),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11.5,
                            height: 1.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: palette.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 12,
                          color: palette.separator,
                        ),
                        const SizedBox(width: 8),
                        _CoinGlyph(palette: palette),
                        const SizedBox(width: 6),
                        Text(
                          numberFormat.format(coins),
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12.5,
                            height: 1.0,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinGlyph extends StatelessWidget {
  final _UserIdentityPalette palette;

  const _CoinGlyph({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.24, -0.34),
          radius: 0.96,
          colors: [
            palette.coinHighlight,
            palette.coinBase,
            palette.coinEdge,
          ],
          stops: const [0.0, 0.66, 1.0],
        ),
        border: Border.all(
          color: palette.coinStroke,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.coinShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'R',
        style: TextStyle(
          fontFamily: 'DMSerifDisplay',
          fontSize: 9.5,
          height: 1.0,
          color: palette.coinLetter,
        ),
      ),
    );
  }
}

class _UserIdentityPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color separator;
  final Color coinHighlight;
  final Color coinBase;
  final Color coinEdge;
  final Color coinStroke;
  final Color coinLetter;
  final Color coinShadow;

  const _UserIdentityPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
    required this.coinHighlight,
    required this.coinBase,
    required this.coinEdge,
    required this.coinStroke,
    required this.coinLetter,
    required this.coinShadow,
  });

  factory _UserIdentityPalette.resolve(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return _UserIdentityPalette(
        textPrimary: ColorPalette.textPrimaryDark.withValues(alpha: 0.96),
        textSecondary: ColorPalette.textSecondaryDark.withValues(alpha: 0.86),
        separator: ColorPalette.textPrimaryDark.withValues(alpha: 0.18),
        coinHighlight: Colors.white,
        coinBase: AppColors.cream,
        coinEdge: AppColors.cream2,
        coinStroke: AppColors.earth.withValues(alpha: 0.52),
        coinLetter: AppColors.ink,
        coinShadow: AppColors.flowerYellow.withValues(alpha: 0.16),
      );
    }

    return _UserIdentityPalette(
      textPrimary: Color.lerp(AppColors.ink, AppColors.earth, 0.72)!,
      textSecondary: AppColors.earth.withValues(alpha: 0.88),
      separator: AppColors.earth.withValues(alpha: 0.24),
      coinHighlight: AppColors.ink,
      coinBase: const Color(0xFF2A1408),
      coinEdge: const Color(0xFF1A0C04),
      coinStroke: AppColors.earth.withValues(alpha: 0.62),
      coinLetter: AppColors.cream,
      coinShadow: AppColors.earth.withValues(alpha: 0.16),
    );
  }
}
