import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/l10n/gen/app_localizations.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/widgets/currency/amber_coin_icon.dart';

class MysteryBoxRewardView extends StatelessWidget {
  const MysteryBoxRewardView({
    super.key,
    required this.transaction,
    this.reducedMotion = false,
    this.showIntroCopy = true,
  });

  final MysteryBoxOpeningTransaction transaction;
  final bool reducedMotion;
  final bool showIntroCopy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reward = transaction.reward;
    final tone = _RewardVisualTone.fromReward(reward);
    final summary = _summaryFor(reward, l10n);
    final items = _rewardItems(reward, tone, l10n);

    return Semantics(
      container: true,
      liveRegion: true,
      label: summary,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ShopUiTokens.surfaceRaised,
          borderRadius: ShopUiTokens.radiusXlShape,
          border: Border.all(color: _borderColorForTone(tone)),
          boxShadow: _shadowForTone(tone),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (showIntroCopy) ...<Widget>[
                Text(
                  l10n.shopMysteryBoxRewardTitle,
                  textAlign: TextAlign.center,
                  style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.shopMysteryBoxRewardDescription,
                  textAlign: TextAlign.center,
                  style: ShopUiTextStyles.bodySmall,
                ),
                const SizedBox(height: 18),
              ],
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final useWideLayout = constraints.maxWidth >= 380 &&
                      reward.hasCoins &&
                      reward.hasXp &&
                      !reward.hasUtilityRewards;

                  if (useWideLayout) {
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: _RewardAmountCard(
                            kind: _RewardCardKind.coins,
                            amount: reward.coins,
                            tone: tone,
                            reducedMotion: reducedMotion,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RewardAmountCard(
                            kind: _RewardCardKind.xp,
                            amount: reward.xp,
                            tone: tone,
                            reducedMotion: reducedMotion,
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      for (int index = 0; index < items.length; index += 1) ...<Widget>[
                        items[index],
                        if (index < items.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _rewardItems(
    MysteryBoxRewardResult reward,
    _RewardVisualTone tone,
    AppLocalizations l10n,
  ) {
    final items = <Widget>[];

    for (final entry in reward.utilityRewards.entries) {
      final item = ShopCatalog.getItemById(entry.key);
      items.add(
        _RewardUtilityCard(
          item: item,
          quantity: entry.value,
          tone: tone,
          reducedMotion: reducedMotion,
          l10n: l10n,
        ),
      );
    }

    if (reward.hasCoins && reward.hasXp) {
      items.addAll(<Widget>[
        _RewardAmountCard(
          kind: _RewardCardKind.coins,
          amount: reward.coins,
          tone: tone,
          reducedMotion: reducedMotion,
        ),
        const SizedBox(height: 10),
        _RewardAmountCard(
          kind: _RewardCardKind.xp,
          amount: reward.xp,
          tone: tone,
          reducedMotion: reducedMotion,
        ),
      ]);
      return items;
    }

    if (reward.hasCoins) {
      items.add(
        _RewardAmountCard(
          kind: _RewardCardKind.coins,
          amount: reward.coins,
          tone: tone,
          reducedMotion: reducedMotion,
        ),
      );
    }

    if (reward.hasXp) {
      if (items.isNotEmpty) {
        items.add(const SizedBox(height: 10));
      }
      items.add(
        _RewardAmountCard(
          kind: _RewardCardKind.xp,
          amount: reward.xp,
          tone: tone,
          reducedMotion: reducedMotion,
        ),
      );
    }

    if (items.isEmpty) {
      items.add(
        _RewardEmptyState(
          tone: tone,
          reducedMotion: reducedMotion,
        ),
      );
    }

    return items;
  }

  String _summaryFor(MysteryBoxRewardResult reward, AppLocalizations l10n) {
    final parts = <String>[];

    for (final entry in reward.utilityRewards.entries) {
      final item = ShopCatalog.getItemById(entry.key);
      final title = item != null
          ? l10n.shopUtilityTitleForItem(item)
          : l10n.shopActionAvailable;
      parts.add(entry.value == 1 ? title : '$title x${entry.value}');
    }

    if (reward.hasCoins) {
      parts.add(l10n.shopPriceCoins(reward.coins));
    }
    if (reward.hasXp) {
      parts.add('${reward.xp} XP');
    }

    if (parts.isEmpty) {
      return l10n.shopMysteryBoxRewardTitle;
    }
    return '${l10n.shopMysteryBoxRewardTitle}: ${parts.join(' · ')}';
  }

  Color _borderColorForTone(_RewardVisualTone tone) {
    switch (tone) {
      case _RewardVisualTone.standard:
        return ShopUiTokens.stroke;
      case _RewardVisualTone.elevated:
        return ShopUiTokens.accentSoft.withValues(alpha: 0.66);
      case _RewardVisualTone.special:
        return ShopUiTokens.coinSoft.withValues(alpha: 0.88);
    }
  }

  List<BoxShadow> _shadowForTone(_RewardVisualTone tone) {
    switch (tone) {
      case _RewardVisualTone.standard:
        return ShopUiTokens.softShadow;
      case _RewardVisualTone.elevated:
        return <BoxShadow>[
          BoxShadow(
            color: ShopUiTokens.accentSoft.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ];
      case _RewardVisualTone.special:
        return <BoxShadow>[
          BoxShadow(
            color: ShopUiTokens.coinSoft.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ];
    }
  }
}

enum _RewardCardKind { coins, xp }

enum _RewardVisualTone {
  standard,
  elevated,
  special;

  static _RewardVisualTone fromReward(MysteryBoxRewardResult reward) {
    if (reward.hasUtilityRewards || reward.coins >= 150) {
      return _RewardVisualTone.special;
    }
    if (reward.coins >= 125) {
      return _RewardVisualTone.elevated;
    }
    return _RewardVisualTone.standard;
  }
}

class _RewardAmountCard extends StatelessWidget {
  const _RewardAmountCard({
    required this.kind,
    required this.amount,
    required this.tone,
    required this.reducedMotion,
  });

  final _RewardCardKind kind;
  final int amount;
  final _RewardVisualTone tone;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSpecial = tone == _RewardVisualTone.special;
    final isElevated = tone == _RewardVisualTone.elevated;
    final text =
        kind == _RewardCardKind.coins ? l10n.shopPriceCoins(amount) : '$amount XP';
    final icon = kind == _RewardCardKind.coins
        ? const AmberCoinIcon(size: 24)
        : const Icon(Icons.auto_graph_rounded, color: ShopUiTokens.success);
    final semanticLabel =
        kind == _RewardCardKind.coins ? l10n.shopPriceCoins(amount) : '$amount XP';
    final background = kind == _RewardCardKind.coins
        ? ShopUiTokens.coinSoft.withValues(alpha: isSpecial ? 0.28 : 0.18)
        : ShopUiTokens.successSoft.withValues(
            alpha: isSpecial ? 0.22 : 0.16,
          );
    final border = kind == _RewardCardKind.coins
        ? ShopUiTokens.coin.withValues(alpha: isSpecial ? 0.28 : 0.16)
        : ShopUiTokens.success.withValues(alpha: isSpecial ? 0.24 : 0.14);

    return Semantics(
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: ShopUiTokens.radiusLgShape,
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 180;
              final iconSize = compact
                  ? 38.0
                  : isSpecial
                      ? 54.0
                      : isElevated
                          ? 50.0
                          : 46.0;
              final textStyle = ShopUiTextStyles.sectionTitle.copyWith(
                fontSize: compact
                    ? 16
                    : isSpecial
                        ? 22
                        : isElevated
                            ? 20
                            : 18,
                color: ShopUiTokens.textPrimary,
              );
              final iconContainer = Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: ShopUiTokens.surfaceRaised,
                  borderRadius: ShopUiTokens.radiusMdShape,
                ),
                child: Center(child: icon),
              );
              final labelWidget = AnimatedDefaultTextStyle(
                duration: reducedMotion
                    ? const Duration(milliseconds: 1)
                    : const Duration(milliseconds: 180),
                style: textStyle,
                child: Text(
                  text,
                  maxLines: compact ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                ),
              );

              if (compact) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    iconContainer,
                    const SizedBox(height: 10),
                    labelWidget,
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  iconContainer,
                  const SizedBox(width: 12),
                  Expanded(child: labelWidget),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _RewardUtilityCard extends StatelessWidget {
  const _RewardUtilityCard({
    required this.item,
    required this.quantity,
    required this.tone,
    required this.reducedMotion,
    required this.l10n,
  });

  final ShopItem? item;
  final int quantity;
  final _RewardVisualTone tone;
  final bool reducedMotion;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final label = item != null
        ? l10n.shopUtilityTitleForItem(item!)
        : l10n.shopActionAvailable;
    final countLabel = quantity == 1 ? 'x1' : 'x$quantity';
    final assetPreview = ShopItemAssetPreview(
      item: item,
      fallbackTone: _toneFor(item?.type),
      fallbackIcon: _iconFor(item?.type),
      fallbackLabel: label,
      height: 82,
      fit: BoxFit.contain,
    );

    return Semantics(
      label: quantity == 1 ? label : '$label x$quantity',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ShopUiTokens.surfaceRaised,
          borderRadius: ShopUiTokens.radiusLgShape,
          border: Border.all(color: _borderColor()),
          boxShadow: tone == _RewardVisualTone.special
              ? <BoxShadow>[
                  BoxShadow(
                    color: ShopUiTokens.coinSoft.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : ShopUiTokens.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: ShopUiTokens.radiusMdShape,
                child: SizedBox(width: 88, height: 88, child: assetPreview),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      countLabel,
                      style: ShopUiTextStyles.bodySmall.copyWith(
                        color: ShopUiTokens.textSecondary,
                      ),
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

  Color _borderColor() {
    switch (tone) {
      case _RewardVisualTone.standard:
        return ShopUiTokens.stroke;
      case _RewardVisualTone.elevated:
        return ShopUiTokens.accentSoft.withValues(alpha: 0.50);
      case _RewardVisualTone.special:
        return ShopUiTokens.coinSoft.withValues(alpha: 0.75);
    }
  }

  ShopPreviewPlaceholderTone _toneFor(ShopItemType? type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return ShopPreviewPlaceholderTone.sage;
      case ShopItemType.coinBoost:
        return ShopPreviewPlaceholderTone.camel;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return ShopPreviewPlaceholderTone.sand;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
      case ShopItemType.mysteryBox:
      case null:
        return ShopPreviewPlaceholderTone.clay;
    }
  }

  IconData _iconFor(ShopItemType? type) {
    switch (type) {
      case ShopItemType.xpBoost:
        return Icons.auto_graph_rounded;
      case ShopItemType.coinBoost:
        return Icons.monetization_on_rounded;
      case ShopItemType.streakRecover:
        return Icons.restore_rounded;
      case ShopItemType.streakShield:
        return Icons.shield_rounded;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
      case ShopItemType.mysteryBox:
      case null:
        return Icons.inventory_2_outlined;
    }
  }
}

class _RewardEmptyState extends StatelessWidget {
  const _RewardEmptyState({
    required this.tone,
    required this.reducedMotion,
  });

  final _RewardVisualTone tone;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: reducedMotion ? 1.0 : 0.98,
      duration: reducedMotion
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ShopUiTokens.surfaceRaised,
          borderRadius: ShopUiTokens.radiusLgShape,
          border: Border.all(color: ShopUiTokens.stroke),
          boxShadow: tone == _RewardVisualTone.special
              ? <BoxShadow>[
                  BoxShadow(
                    color: ShopUiTokens.coinSoft.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ]
              : ShopUiTokens.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'Sin recompensa visible.',
            textAlign: TextAlign.center,
            style: ShopUiTextStyles.bodySmall,
          ),
        ),
      ),
    );
  }
}
