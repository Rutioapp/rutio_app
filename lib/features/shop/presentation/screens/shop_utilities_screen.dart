import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_utility_item_card.dart';

class ShopUtilitiesScreen extends StatelessWidget {
  const ShopUtilitiesScreen({
    super.key,
    required this.walletCoins,
    required this.items,
    required this.onItemPressed,
    this.onBackPressed,
  });

  final int walletCoins;
  final List<ShopItem> items;
  final VoidCallback? onBackPressed;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    final List<ShopItem> boosts = items
        .where((ShopItem item) =>
            item.type == ShopItemType.xpBoost || item.type == ShopItemType.coinBoost)
        .toList(growable: false);
    final List<ShopItem> streaks = items
        .where((ShopItem item) =>
            item.type == ShopItemType.streakRecover ||
            item.type == ShopItemType.streakShield)
        .toList(growable: false);
    final List<ShopItem> boxes = items
        .where((ShopItem item) => item.type == ShopItemType.mysteryBox)
        .toList(growable: false);

    return ShopPageShell(
      header: ShopHeader(
        title: 'Utilidades',
        subtitle: 'Ayudas suaves para Rutio',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (boosts.isNotEmpty) ...<Widget>[
            _Section(
              title: 'Boosts',
              items: boosts,
              onItemPressed: onItemPressed,
            ),
            const SizedBox(height: ShopUiTokens.sectionSpacing),
          ],
          if (streaks.isNotEmpty) ...<Widget>[
            _Section(
              title: 'Rachas',
              items: streaks,
              onItemPressed: onItemPressed,
            ),
            const SizedBox(height: ShopUiTokens.sectionSpacing),
          ],
          if (boxes.isNotEmpty)
            _Section(
              title: 'Cajas',
              items: boxes,
              onItemPressed: onItemPressed,
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onItemPressed,
  });

  final String title;
  final List<ShopItem> items;
  final ValueChanged<String> onItemPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: Key('shopUtilitiesSection-$title'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ShopSectionHeader(
          title: title,
          subtitle: '${items.length} utilidades',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final int crossAxisCount = constraints.maxWidth >= 560 ? 3 : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.48,
              ),
              itemBuilder: (BuildContext context, int index) {
                final ShopItem item = items[index];
                return ShopUtilityItemCard(
                  key: Key('shopUtilityCard-${item.id}'),
                  item: item,
                  onTap: () => onItemPressed(item.id),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
