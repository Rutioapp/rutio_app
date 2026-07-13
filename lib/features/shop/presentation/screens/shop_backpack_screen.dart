import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/models/backpack_item_view_model.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_empty_state.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_backpack_section.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';

class ShopBackpackScreen extends StatelessWidget {
  const ShopBackpackScreen({
    super.key,
    required this.walletCoins,
    required this.items,
    required this.onBackPressed,
    required this.onItemPressed,
    required this.onUsePressed,
    this.onOpenUtilities,
  });

  final int walletCoins;
  final List<BackpackItemViewModel> items;
  final VoidCallback onBackPressed;
  final ValueChanged<String> onItemPressed;
  final ValueChanged<String> onUsePressed;
  final VoidCallback? onOpenUtilities;

  @override
  Widget build(BuildContext context) {
    final List<_BackpackSectionData> sections = _groupSections(items);

    return ShopPageShell(
      header: ShopHeader(
        title: 'Mochila',
        subtitle: 'Gestiona tus consumibles',
        leadingIcon: Icons.arrow_back_ios_new_rounded,
        onLeadingPressed: onBackPressed,
        walletCoins: walletCoins,
      ),
      child: sections.isEmpty
          ? ShopBackpackEmptyState(onOpenUtilities: onOpenUtilities)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int index = 0;
                    index < sections.length;
                    index++) ...<Widget>[
                  ShopBackpackSection(
                    title: sections[index].title,
                    subtitle: sections[index].subtitle,
                    items: sections[index].items,
                    onItemPressed: onItemPressed,
                    onUsePressed: onUsePressed,
                  ),
                  if (index < sections.length - 1)
                    const SizedBox(height: ShopUiTokens.sectionSpacing),
                ],
              ],
            ),
    );
  }

  List<_BackpackSectionData> _groupSections(List<BackpackItemViewModel> items) {
    final Map<_BackpackSectionKind, List<BackpackItemViewModel>> grouped =
        <_BackpackSectionKind, List<BackpackItemViewModel>>{
      _BackpackSectionKind.boosts: <BackpackItemViewModel>[],
      _BackpackSectionKind.streaks: <BackpackItemViewModel>[],
      _BackpackSectionKind.boxes: <BackpackItemViewModel>[],
      _BackpackSectionKind.other: <BackpackItemViewModel>[],
    };

    for (final BackpackItemViewModel item in items) {
      grouped[_sectionForType(item.type)]!.add(item);
    }

    return <_BackpackSectionData>[
      _BackpackSectionData(
        title: 'Boosts',
        subtitle: 'XP y monedas temporales',
        items: grouped[_BackpackSectionKind.boosts]!,
      ),
      _BackpackSectionData(
        title: 'Rachas',
        subtitle: 'Recupera y protege rachas',
        items: grouped[_BackpackSectionKind.streaks]!,
      ),
      _BackpackSectionData(
        title: 'Cajas',
        subtitle: 'Sorpresas pendientes',
        items: grouped[_BackpackSectionKind.boxes]!,
      ),
      _BackpackSectionData(
        title: 'Otros',
        subtitle: 'Items adicionales',
        items: grouped[_BackpackSectionKind.other]!,
      ),
    ].where((_BackpackSectionData section) => section.items.isNotEmpty).toList(
          growable: false,
        );
  }

  _BackpackSectionKind _sectionForType(ShopItemType type) {
    switch (type) {
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
        return _BackpackSectionKind.boosts;
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
        return _BackpackSectionKind.streaks;
      case ShopItemType.mysteryBox:
        return _BackpackSectionKind.boxes;
      case ShopItemType.background:
      case ShopItemType.habitCard:
      case ShopItemType.userCard:
        return _BackpackSectionKind.other;
    }
  }
}

enum _BackpackSectionKind {
  boosts,
  streaks,
  boxes,
  other,
}

class _BackpackSectionData {
  const _BackpackSectionData({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final String title;
  final String subtitle;
  final List<BackpackItemViewModel> items;
}
