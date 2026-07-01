import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_featured_collection_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_home_entry_tile.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_home_hero.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

class ShopHomeScreen extends StatelessWidget {
  const ShopHomeScreen({
    super.key,
    required this.walletCoins,
    required this.onOpenCosmetics,
    required this.onOpenUtilities,
    required this.onOpenCollections,
    this.onOpenBackpack,
    this.onOpenCustomization,
    this.onMenuPressed,
    this.onBackPressed,
  });

  final int walletCoins;
  final VoidCallback onOpenCosmetics;
  final VoidCallback onOpenUtilities;
  final VoidCallback onOpenCollections;
  final VoidCallback? onOpenBackpack;
  final VoidCallback? onOpenCustomization;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    final featuredCollection = _featuredCollection;
    final featuredItem = _featuredItemForCollection(featuredCollection);

    return ShopPageShell(
      header: ShopHeader(
        title: 'Tienda',
        subtitle: 'Mejora tu experiencia Rutio',
        leadingIcon: onBackPressed != null
            ? Icons.arrow_back_ios_new_rounded
            : Icons.menu_rounded,
        onLeadingPressed: onBackPressed ?? onMenuPressed,
        trailingIcon: onBackPressed != null && onMenuPressed != null
            ? Icons.menu_rounded
            : null,
        onTrailingPressed: onBackPressed != null ? onMenuPressed : null,
        walletCoins: walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShopHomeHero(
            onOpenBackpack: onOpenBackpack,
            onOpenCustomization: onOpenCustomization,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          const ShopSectionHeader(
            title: 'Explora',
            subtitle: 'Tres accesos rapidos para entrar en la nueva tienda.',
          ),
          const SizedBox(height: 4),
          ShopHomeEntryTile(
            key: const Key('shopHomeEntryCosmetics'),
            title: 'Cosméticos',
            subtitle: 'Fondos, habit cards y user cards con estilo Rutio.',
            onTap: onOpenCosmetics,
            icon: Icons.palette_outlined,
            placeholderTone: ShopPreviewPlaceholderTone.camel,
          ),
          const SizedBox(height: 12),
          ShopHomeEntryTile(
            key: const Key('shopHomeEntryUtilities'),
            title: 'Utilidades',
            subtitle: 'Boosts y ayudas listas para integrarse mas adelante.',
            onTap: onOpenUtilities,
            icon: Icons.bolt_rounded,
            placeholderTone: ShopPreviewPlaceholderTone.sage,
          ),
          const SizedBox(height: 12),
          ShopHomeEntryTile(
            key: const Key('shopHomeEntryCollections'),
            title: 'Colecciones',
            subtitle: 'Agrupaciones visuales para navegar por temática.',
            onTap: onOpenCollections,
            icon: Icons.view_carousel_outlined,
            placeholderTone: ShopPreviewPlaceholderTone.ice,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          const ShopSectionHeader(
            title: 'Destacado',
            subtitle: 'Un vistazo rapido a una coleccion real del catalogo.',
          ),
          ShopFeaturedCollectionCard(
            collection: featuredCollection,
            featuredItem: featuredItem,
            onTap: onOpenCollections,
          ),
        ],
      ),
    );
  }

  ShopCollection get _featuredCollection {
    return ShopCatalog.allCollections.firstWhere(
      (ShopCollection collection) => collection.id == 'landscape',
      orElse: () => ShopCatalog.allCollections.first,
    );
  }

  ShopItem? _featuredItemForCollection(ShopCollection collection) {
    final List<ShopItem> collectionItems = ShopCatalog.itemsByCollection(
      collection.id,
    );
    for (final ShopItem item in collectionItems) {
      if (item.category == ShopItemCategory.cosmetic &&
          item.rarity == ShopItemRarity.epic) {
        return item;
      }
    }
    return collectionItems.isNotEmpty ? collectionItems.first : null;
  }
}
