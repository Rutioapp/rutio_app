import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopHomeHero extends StatelessWidget {
  const ShopHomeHero({
    super.key,
    this.onOpenBackpack,
    this.onOpenCustomization,
  });

  final VoidCallback? onOpenBackpack;
  final VoidCallback? onOpenCustomization;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: ShopUiTokens.radiusXlShape,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            ShopUiTokens.surfaceRaised,
            ShopUiTokens.surfaceMuted,
          ],
        ),
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              l10n.shopHomeHeroTitle,
              style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.shopHomeHeroSubtitle,
              style: ShopUiTextStyles.subtitle,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool isCompact = constraints.maxWidth < 460;
                final Widget artwork = const _HeroArtwork();
                final Widget actions = _HeroActions(
                  isCompact: isCompact,
                  onOpenBackpack: onOpenBackpack,
                  onOpenCustomization: onOpenCustomization,
                );

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SizedBox(height: 152, child: artwork),
                      const SizedBox(height: 12),
                      actions,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: 148, child: artwork),
                    const SizedBox(height: 12),
                    actions,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: ShopUiTokens.radiusLgShape,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF8F2E6),
            Color(0xFFE9DBC4),
          ],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 16,
            top: 18,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ShopUiTokens.accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: 66,
                      height: 66,
                      decoration: const BoxDecoration(
                        color: ShopUiTokens.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 30,
                        color: ShopUiTokens.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 34,
                      width: 120,
                      decoration: BoxDecoration(
                        color: ShopUiTokens.placeholderCamel,
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({
    required this.isCompact,
    this.onOpenBackpack,
    this.onOpenCustomization,
  });

  final bool isCompact;
  final VoidCallback? onOpenBackpack;
  final VoidCallback? onOpenCustomization;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (isCompact) {
      return Column(
        children: <Widget>[
          _QuickLink(
            key: const Key('shopHomeHeroBackpack'),
            title: l10n.shopHomeHeroBackpackTitle,
            subtitle: l10n.shopHomeHeroBackpackSubtitle,
            icon: Icons.inventory_2_outlined,
            onTap: onOpenBackpack,
          ),
          const SizedBox(height: 10),
          _QuickLink(
            key: const Key('shopHomeHeroCustomization'),
            title: l10n.shopHomeHeroCustomizationTitle,
            subtitle: l10n.shopHomeHeroCustomizationSubtitle,
            icon: Icons.tune_rounded,
            onTap: onOpenCustomization,
          ),
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _QuickLink(
            key: const Key('shopHomeHeroBackpack'),
            title: l10n.shopHomeHeroBackpackTitle,
            subtitle: l10n.shopHomeHeroBackpackSubtitle,
            icon: Icons.inventory_2_outlined,
            onTap: onOpenBackpack,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickLink(
            key: const Key('shopHomeHeroCustomization'),
            title: l10n.shopHomeHeroCustomizationTitle,
            subtitle: l10n.shopHomeHeroCustomizationSubtitle,
            icon: Icons.tune_rounded,
            onTap: onOpenCustomization,
          ),
        ),
      ],
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.72 : 1,
      child: Material(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusMdShape,
        child: InkWell(
          onTap: onTap,
          borderRadius: ShopUiTokens.radiusMdShape,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: ShopUiTokens.radiusMdShape,
              border: Border.all(color: ShopUiTokens.stroke),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: ShopUiTokens.backgroundAlt,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: ShopUiTokens.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        style: ShopUiTextStyles.label.copyWith(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ShopUiTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
