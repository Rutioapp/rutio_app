import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Tu espacio, mas tuyo',
              style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 26),
            ),
            const SizedBox(height: 8),
            Text(
              'Descubre estilos suaves, utilidades ligeras y colecciones pensadas para Rutio.',
              style: ShopUiTextStyles.subtitle,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final isCompact = constraints.maxWidth < 420;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(
                        height: 196,
                        child: _HeroArtwork(isCompact: true),
                      ),
                      const SizedBox(height: 16),
                      _HeroActions(
                        onOpenBackpack: onOpenBackpack,
                        onOpenCustomization: onOpenCustomization,
                      ),
                    ],
                  );
                }

                return SizedBox(
                  height: 196,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Expanded(
                        flex: 6,
                        child: _HeroArtwork(isCompact: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 5,
                        child: _HeroActions(
                          onOpenBackpack: onOpenBackpack,
                          onOpenCustomization: onOpenCustomization,
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

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.isCompact});

  final bool isCompact;

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
            top: 18,
            left: 18,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 18,
            top: 24,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: ShopUiTokens.accentSoft,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        color: ShopUiTokens.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.face_retouching_natural_rounded,
                        size: 42,
                        color: ShopUiTokens.accent,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 56,
                      width: 160,
                      decoration: BoxDecoration(
                        color: ShopUiTokens.placeholderCamel,
                        borderRadius: BorderRadius.circular(24),
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
    this.onOpenBackpack,
    this.onOpenCustomization,
  });

  final VoidCallback? onOpenBackpack;
  final VoidCallback? onOpenCustomization;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _QuickLink(
          key: const Key('shopHomeHeroBackpack'),
          title: 'Backpack',
          subtitle: 'Lo que ya has conseguido',
          icon: Icons.inventory_2_outlined,
          onTap: onOpenBackpack,
        ),
        const SizedBox(height: 12),
        _QuickLink(
          key: const Key('shopHomeHeroCustomization'),
          title: 'Personalizar',
          subtitle: 'Combina fondos y cards',
          icon: Icons.tune_rounded,
          onTap: onOpenCustomization,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: ShopUiTokens.radiusMdShape,
              border: Border.all(color: ShopUiTokens.stroke),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: ShopUiTokens.backgroundAlt,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 18, color: ShopUiTokens.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: ShopUiTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ShopUiTextStyles.bodySmall,
                        maxLines: 2,
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
