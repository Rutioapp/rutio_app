import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_header.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_home_entry_tile.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_home_hero.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_page_shell.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_section_header.dart';
import 'package:rutio/l10n/l10n.dart';

class ShopHomeScreen extends StatelessWidget {
  const ShopHomeScreen({
    super.key,
    required this.walletCoins,
    required this.onOpenCosmetics,
    required this.onOpenUtilities,
    this.onOpenBackpack,
    this.onOpenCustomization,
    this.onMenuPressed,
    this.onBackPressed,
    this.drawer,
  });

  final int walletCoins;
  final VoidCallback onOpenCosmetics;
  final VoidCallback onOpenUtilities;
  final VoidCallback? onOpenBackpack;
  final VoidCallback? onOpenCustomization;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    return ShopPageShell(
      drawer: drawer,
      header: Builder(
        builder: (BuildContext context) => ShopHeader(
          title: context.l10n.shopTitle,
          subtitle: context.l10n.shopHomeSubtitle,
          leadingIcon: onBackPressed != null
              ? Icons.arrow_back_ios_new_rounded
              : Icons.menu_rounded,
          onLeadingPressed: onBackPressed ??
              onMenuPressed ??
              () => Scaffold.of(context).openDrawer(),
          walletCoins: walletCoins,
          useDrawerLeadingStyle: onBackPressed == null,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ShopHomeHero(
            onOpenBackpack: onOpenBackpack,
            onOpenCustomization: onOpenCustomization,
          ),
          const SizedBox(height: ShopUiTokens.sectionSpacing),
          Builder(
            builder: (BuildContext context) => ShopSectionHeader(
              title: context.l10n.shopExploreTitle,
              subtitle: context.l10n.shopExploreSubtitle,
            ),
          ),
          const SizedBox(height: 4),
          ShopHomeEntryTile(
            key: const Key('shopHomeEntryCosmetics'),
            title: context.l10n.shopCosmeticsTitle,
            subtitle: context.l10n.shopCosmeticsSubtitle,
            onTap: onOpenCosmetics,
            icon: Icons.palette_outlined,
            placeholderTone: ShopPreviewPlaceholderTone.camel,
          ),
          const SizedBox(height: 12),
          ShopHomeEntryTile(
            key: const Key('shopHomeEntryUtilities'),
            title: context.l10n.shopUtilitiesTitle,
            subtitle: context.l10n.shopUtilitiesSubtitle,
            onTap: onOpenUtilities,
            icon: Icons.bolt_rounded,
            placeholderTone: ShopPreviewPlaceholderTone.sage,
          ),
        ],
      ),
    );
  }
}
