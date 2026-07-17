import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/presentation/shop_localizations.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopCosmeticsRarityBadge extends StatelessWidget {
  const ShopCosmeticsRarityBadge({
    super.key,
    required this.rarity,
    this.compact = false,
  });

  final ShopAssetRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = ShopCosmeticsRarityPalette.fromRarity(rarity);

    return Container(
      key: Key('shopCosmeticsRarity-${rarity.key}'),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: ShopUiTokens.radiusXlShape,
        border: Border.all(color: palette.border),
      ),
      child: Text(
        l10n.shopAssetRarityLabel(rarity),
        style: ShopUiTextStyles.labelSmall.copyWith(color: palette.foreground),
      ),
    );
  }
}

class ShopCosmeticsRarityPalette {
  const ShopCosmeticsRarityPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;

  static ShopCosmeticsRarityPalette fromRarity(ShopAssetRarity rarity) {
    switch (rarity) {
      case ShopAssetRarity.common:
        return const ShopCosmeticsRarityPalette(
          background: Color(0x1F7A9A70),
          border: Color(0x337A9A70),
          foreground: Color(0xFF5B7654),
        );
      case ShopAssetRarity.rare:
        return const ShopCosmeticsRarityPalette(
          background: Color(0x1F8AA9C4),
          border: Color(0x338AA9C4),
          foreground: Color(0xFF5F7C95),
        );
      case ShopAssetRarity.epic:
        return const ShopCosmeticsRarityPalette(
          background: Color(0x1FB7A3C9),
          border: Color(0x33B7A3C9),
          foreground: Color(0xFF7A688D),
        );
      case ShopAssetRarity.legendary:
        return const ShopCosmeticsRarityPalette(
          background: Color(0x1FD1B179),
          border: Color(0x33D1B179),
          foreground: Color(0xFF9A7440),
        );
    }
  }
}
