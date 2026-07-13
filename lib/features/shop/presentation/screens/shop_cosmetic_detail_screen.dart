import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_asset_preview.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_item_detail_info_row.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopCosmeticDetailScreen extends StatelessWidget {
  const ShopCosmeticDetailScreen({
    super.key,
    required this.item,
    required this.isEquipped,
    required this.onBackPressed,
    required this.onEquipPressed,
    this.collectionName,
  });

  final ShopItem item;
  final bool isEquipped;
  final String? collectionName;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onEquipPressed;

  @override
  Widget build(BuildContext context) {
    final String status = isEquipped ? 'Equipado' : 'Comprado';

    return ShopPageShell(
      header: ShopHeader(
        title: 'Detalle',
        subtitle: _headerSubtitle(item.type),
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 16),
          _PreviewPanel(item: item),
          const SizedBox(height: 18),
          _InfoCard(
            children: <Widget>[
              ShopItemDetailInfoRow(
                label: 'Rareza',
                value: _rarityLabel(item.rarity),
              ),
              const SizedBox(height: 12),
              ShopItemDetailInfoRow(
                label: 'Tipo',
                value: _typeLabel(item.type),
              ),
              const SizedBox(height: 12),
              ShopItemDetailInfoRow(
                label: 'Estilo',
                value: collectionName ?? _styleLabel(item.collectionId),
              ),
              const SizedBox(height: 12),
              ShopItemDetailInfoRow(
                label: 'Estado',
                value: status,
                valueKey: const Key('shopCosmeticDetailStatusValue'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ActionCard(
            key: const Key('shopCosmeticDetailActionCard'),
            label: isEquipped ? 'Equipado' : 'Equipar',
            enabled: !isEquipped,
            onPressed: isEquipped ? null : () => onEquipPressed(item.id),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  String _headerSubtitle(ShopItemType type) {
    return switch (type) {
      ShopItemType.background => 'Fondo',
      ShopItemType.habitCard => 'Habit Card',
      ShopItemType.userCard => 'User Card',
      ShopItemType.xpBoost => 'Cosmético',
      ShopItemType.coinBoost => 'Cosmético',
      ShopItemType.streakRecover => 'Cosmético',
      ShopItemType.streakShield => 'Cosmético',
      ShopItemType.mysteryBox => 'Cosmético',
    };
  }

  String _styleLabel(String? collectionId) {
    switch (collectionId) {
      case 'minimal':
        return 'Minimal';
      case 'gradient':
        return 'Gradient';
      case 'landscape':
        return 'Landscape';
      default:
        return 'Rutio';
    }
  }

  String _typeLabel(ShopItemType type) {
    return switch (type) {
      ShopItemType.background => 'Fondo',
      ShopItemType.habitCard => 'Habit Card',
      ShopItemType.userCard => 'User Card',
      ShopItemType.xpBoost => 'XP Boost',
      ShopItemType.coinBoost => 'Coin Boost',
      ShopItemType.streakRecover => 'Streak Recover',
      ShopItemType.streakShield => 'Streak Shield',
      ShopItemType.mysteryBox => 'Mystery Box',
    };
  }

  String _rarityLabel(ShopItemRarity rarity) {
    return switch (rarity) {
      ShopItemRarity.common => 'Common',
      ShopItemRarity.uncommon => 'Uncommon',
      ShopItemRarity.rare => 'Rare',
      ShopItemRarity.epic => 'Epic',
      ShopItemRarity.legendary => 'Legendary',
    };
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: Key('shopCosmeticDetailPreview-${item.type.name}'),
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: _buildPreview(),
      ),
    );
  }

  Widget _buildPreview() {
    return switch (item.type) {
      ShopItemType.background => _BackgroundMobilePreview(item: item),
      ShopItemType.habitCard => _HabitCardStylePreview(item: item),
      ShopItemType.userCard => _UserCardStylePreview(item: item),
      ShopItemType.xpBoost ||
      ShopItemType.coinBoost ||
      ShopItemType.streakRecover ||
      ShopItemType.streakShield ||
      ShopItemType.mysteryBox =>
        _BackgroundMobilePreview(item: item),
    };
  }
}

class _BackgroundMobilePreview extends StatelessWidget {
  const _BackgroundMobilePreview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF212121),
          borderRadius: ShopUiTokens.radiusXlShape,
          border: Border.all(color: ShopUiTokens.stroke),
          boxShadow: ShopUiTokens.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: <Widget>[
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ShopUiTokens.backgroundAlt,
                    borderRadius: ShopUiTokens.radiusLgShape,
                    border: Border.all(color: ShopUiTokens.stroke),
                  ),
                  child: ClipRRect(
                    borderRadius: ShopUiTokens.radiusLgShape,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ShopItemAssetPreview(
                          item: item,
                          fallbackLabel: item.title,
                          fallbackTone: ShopPreviewPlaceholderTone.camel,
                          fallbackIcon: Icons.wallpaper_rounded,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.white.withValues(alpha: 0.02),
                                Colors.black.withValues(alpha: 0.08),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 92,
                height: 8,
                decoration: BoxDecoration(
                  color: ShopUiTokens.textTertiary.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HabitCardStylePreview extends StatelessWidget {
  const _HabitCardStylePreview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: AspectRatio(
          aspectRatio: 1.22,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: ShopItemAssetPreview(
              item: item,
              fallbackLabel: item.title,
              fallbackTone: ShopPreviewPlaceholderTone.sand,
              fallbackIcon: Icons.view_agenda_outlined,
              fit: BoxFit.cover,
              mode: ShopAssetPreviewMode.applied,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCardStylePreview extends StatelessWidget {
  const _UserCardStylePreview({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: AspectRatio(
          aspectRatio: 1.08,
          child: ShopItemAssetPreview(
            item: item,
            fallbackLabel: item.title,
            fallbackTone: ShopPreviewPlaceholderTone.ice,
            fallbackIcon: Icons.badge_outlined,
            fit: BoxFit.cover,
            mode: ShopAssetPreviewMode.applied,
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
        boxShadow: ShopUiTokens.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ShopPrimaryButton(
          key: const Key('shopCosmeticDetailActionButton'),
          label: label,
          onPressed: enabled ? onPressed : null,
          icon: enabled
              ? Icons.auto_fix_high_rounded
              : Icons.check_circle_outline_rounded,
        ),
      ),
    );
  }
}
