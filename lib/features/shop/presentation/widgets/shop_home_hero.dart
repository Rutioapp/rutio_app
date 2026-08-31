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
                final bool isCompact = constraints.maxWidth < 340;
                final double aspectRatio = isCompact ? 0.92 : 1.0;
                const double gap = 12;
                final double cardWidth = ((constraints.maxWidth - gap) / 2)
                    .clamp(0.0, double.infinity);
                final double cardHeight =
                    cardWidth > 0 ? cardWidth / aspectRatio : 0;

                return SizedBox(
                  height: cardHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: _HeroActionCard(
                          key: const Key('shopHomeHeroBackpack'),
                          title: l10n.shopHomeHeroBackpackTitle,
                          subtitle: l10n.shopHomeHeroBackpackSubtitle,
                          icon: Icons.inventory_2_outlined,
                          onTap: onOpenBackpack,
                        ),
                      ),
                      const SizedBox(width: gap),
                      Expanded(
                        child: _HeroActionCard(
                          key: const Key('shopHomeHeroCustomization'),
                          title: l10n.shopHomeHeroCustomizationTitle,
                          subtitle: l10n.shopHomeHeroCustomizationSubtitle,
                          icon: Icons.tune_rounded,
                          onTap: onOpenCustomization,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  const _HeroActionCard({
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
    final bool isEnabled = onTap != null;

    return Opacity(
      opacity: isEnabled ? 1 : 0.72,
      child: Material(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: InkWell(
          onTap: onTap,
          borderRadius: ShopUiTokens.radiusLgShape,
          child: Ink(
            decoration: BoxDecoration(
              color: ShopUiTokens.surfaceRaised,
              borderRadius: ShopUiTokens.radiusLgShape,
              border: Border.all(color: ShopUiTokens.stroke),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 128),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: ShopUiTokens.backgroundAlt,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          icon,
                          size: 19,
                          color: ShopUiTokens.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: ShopUiTextStyles.label.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style:
                            ShopUiTextStyles.bodySmall.copyWith(fontSize: 12.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
