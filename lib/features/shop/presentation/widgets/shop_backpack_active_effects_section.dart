import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/active_utility_effect.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_asset_art.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopBackpackActiveEffectsSection extends StatelessWidget {
  const ShopBackpackActiveEffectsSection({
    super.key,
    required this.effects,
  });

  final List<ActiveUtilityEffect> effects;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      key: const Key('shopBackpackActiveEffectsSection'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: l10n.shopBackpackActiveEffectsTitle,
        ),
        if (effects.isEmpty)
          _CompactBackpackEmptyState(
            key: const Key('shopBackpackActiveEffectsEmpty'),
            message: l10n.shopBackpackActiveEffectsEmpty,
          )
        else ...<Widget>[
          const SizedBox(height: 10),
          SizedBox(
            height: 114,
            child: ListView.separated(
              key: const Key('shopBackpackActiveEffectsList'),
              scrollDirection: Axis.horizontal,
              itemCount: effects.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.82,
                  child: _ActiveEffectCard(effect: effects[index]),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveEffectCard extends StatelessWidget {
  const _ActiveEffectCard({
    required this.effect,
  });

  final ActiveUtilityEffect effect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = ShopCatalog.getItemById(effect.utilityId);
    final progress = effect.totalUses <= 0
        ? 0.0
        : (effect.remainingUses / effect.totalUses).clamp(0.0, 1.0).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: ShopUiTokens.radiusMdShape,
              child: SizedBox(
                width: 72,
                height: 72,
                child: _ActiveEffectPreview(item: item, effect: effect),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    item != null
                        ? l10n.shopUtilityTitleForItem(item)
                        : effect.utilityId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.shopBackpackActiveEffectsProgressLabel(
                      effect.remainingUses,
                      effect.totalUses,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ShopUiTextStyles.bodySmall.copyWith(
                      color: ShopUiTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: ShopUiTokens.radiusXlShape,
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: ShopUiTokens.backgroundAlt,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              ShopUiTokens.success,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.shopBackpackActiveEffectsActiveLabel,
                        style: ShopUiTextStyles.labelSmall.copyWith(
                          color: ShopUiTokens.success,
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
    );
  }
}

class _ActiveEffectPreview extends StatelessWidget {
  const _ActiveEffectPreview({
    required this.item,
    required this.effect,
  });

  final ShopItem? item;
  final ActiveUtilityEffect effect;

  @override
  Widget build(BuildContext context) {
    if (item != null) {
      return ShopUtilityAssetArt(
        item: item!,
        fallbackTone: _toneFor(effect),
        fallbackIcon: _iconFor(effect),
      );
    }

    return ShopPreviewPlaceholder(
      label: effect.utilityId,
      tone: _toneFor(effect),
      icon: _iconFor(effect),
    );
  }

  ShopPreviewPlaceholderTone _toneFor(ActiveUtilityEffect effect) {
    switch (effect.type) {
      case ActiveUtilityEffectType.xpBoost:
        return ShopPreviewPlaceholderTone.sage;
      case ActiveUtilityEffectType.coinBoost:
        return ShopPreviewPlaceholderTone.camel;
      case ActiveUtilityEffectType.streakShield:
        return ShopPreviewPlaceholderTone.sand;
    }
  }

  IconData _iconFor(ActiveUtilityEffect effect) {
    switch (effect.type) {
      case ActiveUtilityEffectType.xpBoost:
        return Icons.auto_graph_rounded;
      case ActiveUtilityEffectType.coinBoost:
        return Icons.monetization_on_rounded;
      case ActiveUtilityEffectType.streakShield:
        return Icons.shield_rounded;
    }
  }
}

class _CompactBackpackEmptyState extends StatelessWidget {
  const _CompactBackpackEmptyState({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          message,
          style: ShopUiTextStyles.subtitle,
        ),
      ),
    );
  }
}
