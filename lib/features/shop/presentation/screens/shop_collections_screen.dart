import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/models/shop_collection.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_collection_card.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_collection_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';

class ShopCollectionsScreen extends StatelessWidget {
  const ShopCollectionsScreen({
    super.key,
    required this.walletCoins,
    required this.collections,
    required this.ownedItemIds,
    required this.onBackPressed,
    required this.onCollectionPressed,
  });

  final int walletCoins;
  final List<ShopCollection> collections;
  final Set<String> ownedItemIds;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onCollectionPressed;

  @override
  Widget build(BuildContext context) {
    final List<_CollectionCardData> cards = _buildCards();

    return ShopPageShell(
      header: ShopHeader(
        title: 'Colecciones',
        subtitle: 'Cada coleccion es un pequeno universo',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: cards.isEmpty
          ? const ShopCollectionEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const ShopSectionHeader(
                  title: 'Explora',
                  subtitle: 'Ordenadas por progreso y por sortOrder del catalogo.',
                ),
                const SizedBox(height: 4),
                for (int index = 0; index < cards.length; index++) ...<Widget>[
                  ShopCollectionCard(
                    key: Key('shopCollectionCard-${cards[index].collection.id}'),
                    collection: cards[index].collection,
                    totalItems: cards[index].totalItems,
                    ownedItems: cards[index].ownedItems,
                    isUnlocked: cards[index].isUnlocked,
                    featuredItem: cards[index].featuredItem,
                    onTap: () => onCollectionPressed(cards[index].collection.id),
                  ),
                  if (index < cards.length - 1)
                    const SizedBox(height: ShopUiTokens.sectionSpacing),
                ],
              ],
            ),
    );
  }

  List<_CollectionCardData> _buildCards() {
    final Map<String, ShopCollection> collectionById = <String, ShopCollection>{
      for (final ShopCollection collection in collections) collection.id: collection,
    };

    final List<_CollectionCardData> cards = collections
        .where((ShopCollection collection) => collection.isEnabled)
        .map((ShopCollection collection) {
          final List<ShopItem> items = ShopCatalog.itemsByCollection(collection.id);
          final int ownedItemsCount = items
              .where((ShopItem item) => ownedItemIds.contains(item.id))
              .length;
          final ShopItem? featuredItem = items.isNotEmpty
              ? items.firstWhere(
                  (ShopItem item) => ownedItemIds.contains(item.id),
                  orElse: () => items.first,
                )
              : null;
          return _CollectionCardData(
            collection: collectionById[collection.id] ?? collection,
            totalItems: items.length,
            ownedItems: ownedItemsCount,
            isUnlocked: ownedItemsCount > 0,
            featuredItem: featuredItem,
          );
        })
        .toList(growable: false);

    cards.sort((_CollectionCardData a, _CollectionCardData b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return a.collection.sortOrder.compareTo(b.collection.sortOrder);
    });

    return cards;
  }
}

class _CollectionCardData {
  const _CollectionCardData({
    required this.collection,
    required this.totalItems,
    required this.ownedItems,
    required this.isUnlocked,
    required this.featuredItem,
  });

  final ShopCollection collection;
  final int totalItems;
  final int ownedItems;
  final bool isUnlocked;
  final ShopItem? featuredItem;
}
