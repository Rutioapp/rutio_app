import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
                        const _CoinGlyph(),
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
  static const String _lightAsset =
      'lib/assets/icons/currency/rutio_moneda_bicolor_light.svg';
  static const String _darkAsset =
      'lib/assets/icons/currency/rutio_moneda_bicolor_dark.svg';

  const _CoinGlyph();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final assetPath =
        brightness == Brightness.dark ? _lightAsset : _darkAsset;

    return SvgPicture.asset(
      assetPath,
      width: 16,
      height: 16,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
  }
}

class _UserIdentityPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color separator;

  const _UserIdentityPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
  });

  factory _UserIdentityPalette.resolve(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return _UserIdentityPalette(
        textPrimary: ColorPalette.textPrimaryDark.withValues(alpha: 0.96),
        textSecondary: ColorPalette.textSecondaryDark.withValues(alpha: 0.86),
        separator: ColorPalette.textPrimaryDark.withValues(alpha: 0.18),
      );
    }

    return _UserIdentityPalette(
      textPrimary: Color.lerp(AppColors.ink, AppColors.earth, 0.72)!,
      textSecondary: AppColors.earth.withValues(alpha: 0.88),
      separator: AppColors.earth.withValues(alpha: 0.24),
    );
  }
}
