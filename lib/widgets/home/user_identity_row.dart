import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:rutio/constants/color_palette.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:rutio/utils/app_theme.dart';
import 'package:rutio/widgets/avatar/avatar_with_xp_ring.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

class UserIdentityRow extends StatelessWidget {
  final String username;
  final int level;
  final int coins;
  final double xpProgress;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final String? backgroundImageAssetPath;

  const UserIdentityRow({
    super.key,
    required this.username,
    required this.level,
    required this.coins,
    required this.xpProgress,
    this.avatarUrl,
    this.onTap,
    this.backgroundImageAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    if (backgroundImageAssetPath != null) {
      _log(
        'UserIdentityRow direct backgroundImageAssetPath=$backgroundImageAssetPath fallback=false',
      );
      return _UserIdentityRowSurface(
        username: username,
        level: level,
        coins: coins,
        xpProgress: xpProgress,
        avatarUrl: avatarUrl,
        onTap: onTap,
        backgroundImageAssetPath: backgroundImageAssetPath,
      );
    }

    try {
      final storeRevision = context.select<UserStateStore, String?>(
        (UserStateStore store) => _lastSavedAt(store.state),
      );
      final backgroundImageAssetPath =
          context.select<ShopCosmeticsController, String?>(
        (ShopCosmeticsController controller) =>
            controller.getEquippedUserCardAssetOrNullSync()?.assetPath,
      );
      _log(
        'UserIdentityRow storeRevision=$storeRevision backgroundImageAssetPath=$backgroundImageAssetPath '
        'fallback=${backgroundImageAssetPath == null}',
      );
      return _UserIdentityRowSurface(
        username: username,
        level: level,
        coins: coins,
        xpProgress: xpProgress,
        avatarUrl: avatarUrl,
        onTap: onTap,
        backgroundImageAssetPath: backgroundImageAssetPath,
      );
    } catch (_) {
      _log(
          'UserIdentityRow failed to resolve background image, using fallback');
      return _UserIdentityRowSurface(
        username: username,
        level: level,
        coins: coins,
        xpProgress: xpProgress,
        avatarUrl: avatarUrl,
        onTap: onTap,
      );
    }
  }

  static String? _lastSavedAt(Map<String, dynamic>? root) {
    final userState = root?['userState'];
    if (userState is! Map) return null;
    final meta = userState['meta'];
    if (meta is! Map) return null;
    return meta['lastSavedAt']?.toString();
  }

  static void _log(String message) {
    if (!kDebugMode) return;
    debugPrint('[ShopCosmetics] $message');
  }
}

class _UserIdentityRowSurface extends StatelessWidget {
  const _UserIdentityRowSurface({
    required this.username,
    required this.level,
    required this.coins,
    required this.xpProgress,
    required this.avatarUrl,
    required this.onTap,
    this.backgroundImageAssetPath,
  });

  final String username;
  final int level;
  final int coins;
  final double xpProgress;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final String? backgroundImageAssetPath;

  static final BorderRadius _borderRadius = BorderRadius.circular(20);
  static const EdgeInsets _contentPadding =
      EdgeInsets.symmetric(horizontal: 4, vertical: 6);

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
        borderRadius: _borderRadius,
        splashColor: palette.textPrimary.withValues(alpha: 0.05),
        highlightColor: palette.textPrimary.withValues(alpha: 0.025),
        child: UserCardThemeBackground(
          backgroundImageAssetPath: backgroundImageAssetPath,
          borderRadius: _borderRadius,
          fallbackDecoration: palette.fallbackDecoration,
          borderColor: palette.borderColor,
          child: Padding(
            key: const Key('userIdentityRowContentPadding'),
            padding: _contentPadding,
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
                          const AmberCoinIcon(size: 16),
                          const SizedBox(width: 6),
                          Text(
                            numberFormat.format(coins),
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 12.5,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: palette.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
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
      ),
    );
  }
}

class UserCardThemeBackground extends StatelessWidget {
  const UserCardThemeBackground({
    super.key,
    required this.child,
    required this.borderRadius,
    required this.fallbackDecoration,
    required this.borderColor,
    this.backgroundImageAssetPath,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Decoration fallbackDecoration;
  final Color borderColor;
  final String? backgroundImageAssetPath;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('userIdentityRowThemeBackground'),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        key: const Key('userIdentityRowClipRRect'),
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            DecoratedBox(
              key: const Key('userIdentityRowFallbackBackground'),
              decoration: fallbackDecoration,
            ),
            if (backgroundImageAssetPath != null)
              Positioned.fill(
                child: Image.asset(
                  backgroundImageAssetPath!,
                  key: const Key('userIdentityRowBackgroundImage'),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stackTrace) {
                    UserIdentityRow._log(
                      'UserIdentityRow failed to load '
                      'backgroundImageAssetPath=$backgroundImageAssetPath '
                      'error=$error',
                    );
                    return const SizedBox.shrink();
                  },
                ),
              ),
            if (backgroundImageAssetPath != null)
              Positioned.fill(
                child: DecoratedBox(
                  key: const Key('userIdentityRowBackgroundOverlay'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.24),
                        Colors.white.withValues(alpha: 0.34),
                        Colors.white.withValues(alpha: 0.46),
                      ],
                    ),
                  ),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _UserIdentityPalette {
  final Color textPrimary;
  final Color textSecondary;
  final Color separator;
  final Decoration fallbackDecoration;
  final Color borderColor;

  const _UserIdentityPalette({
    required this.textPrimary,
    required this.textSecondary,
    required this.separator,
    required this.fallbackDecoration,
    required this.borderColor,
  });

  factory _UserIdentityPalette.resolve(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      return _UserIdentityPalette(
        textPrimary: ColorPalette.textPrimaryDark.withValues(alpha: 0.96),
        textSecondary: ColorPalette.textSecondaryDark.withValues(alpha: 0.86),
        separator: ColorPalette.textPrimaryDark.withValues(alpha: 0.18),
        fallbackDecoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              const Color(0xFF3A3F4A),
              const Color(0xFF262B34),
            ],
          ),
        ),
        borderColor: Colors.white.withValues(alpha: 0.14),
      );
    }

    return _UserIdentityPalette(
      textPrimary: Color.lerp(AppColors.ink, AppColors.earth, 0.72)!,
      textSecondary: AppColors.earth.withValues(alpha: 0.88),
      separator: AppColors.earth.withValues(alpha: 0.24),
      fallbackDecoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92),
            const Color(0xFFF4E8D8).withValues(alpha: 0.98),
          ],
        ),
      ),
      borderColor: Colors.white.withValues(alpha: 0.68),
    );
  }
}
