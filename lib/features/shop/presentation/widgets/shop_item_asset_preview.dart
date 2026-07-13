import 'package:flutter/material.dart';
import 'package:rutio/features/shop/data/shop_assets_catalog.dart';
import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/features/shop/domain/models/shop_asset_enums.dart';
import 'package:rutio/features/shop/domain/models/shop_item.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_widget.dart';
import 'package:rutio/widgets/home/user_identity_row.dart';

enum ShopAssetPreviewMode {
  visual,
  applied,
}

class ShopItemAssetPreview extends StatelessWidget {
  const ShopItemAssetPreview({
    super.key,
    required this.item,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.fallbackLabel,
    this.height,
    this.fit = BoxFit.cover,
    this.mode = ShopAssetPreviewMode.visual,
  });

  final ShopItem? item;
  final ShopPreviewPlaceholderTone fallbackTone;
  final IconData fallbackIcon;
  final String? fallbackLabel;
  final double? height;
  final BoxFit fit;
  final ShopAssetPreviewMode mode;

  @override
  Widget build(BuildContext context) {
    final catalogAsset =
        item == null ? null : ShopAssetsCatalog.getAssetById(item!.id);
    if (catalogAsset != null) {
      return ShopVisualAssetPreview.asset(
        asset: catalogAsset,
        fallbackTone: fallbackTone,
        fallbackIcon: fallbackIcon,
        fallbackLabel: fallbackLabel ?? item?.title,
        height: height,
        fit: fit,
        mode: mode,
      );
    }

    final assetRef = item?.assetRef;
    if (assetRef != null && assetRef.startsWith('assets/shop/')) {
      final resolved = _FallbackAssetPreviewData(
        assetPath: assetRef,
        category: _categoryForItemType(item?.type),
      );
      return _buildResolvedFallback(resolved);
    }
    return _fallback();
  }

  Widget _buildResolvedFallback(_FallbackAssetPreviewData resolved) {
    if (mode == ShopAssetPreviewMode.applied &&
        resolved.category == ShopAssetCategory.habitCard) {
      return ShopHabitCardAppliedPreview.fallback(
        key: Key('shopHabitCardAppliedPreview-${resolved.assetPath}'),
        assetPath: resolved.assetPath,
        imageFit: fit,
        fallbackLabel: fallbackLabel,
      );
    }

    if (mode == ShopAssetPreviewMode.applied &&
        resolved.category == ShopAssetCategory.userCard) {
      return ShopUserCardAppliedPreview.fallback(
        key: Key('shopUserCardAppliedPreview-${resolved.assetPath}'),
        assetPath: resolved.assetPath,
      );
    }

    return ShopAssetSurfacePreview.fallback(
      key: Key('shopAssetVisualPreview-${resolved.assetPath}'),
      assetPath: resolved.assetPath,
      fit: fit,
      fallbackLabel: fallbackLabel,
      fallbackTone: fallbackTone,
      fallbackIcon: fallbackIcon,
      height: height,
    );
  }

  ShopAssetCategory _categoryForItemType(ShopItemType? type) {
    switch (type) {
      case ShopItemType.background:
        return ShopAssetCategory.wallpaper;
      case ShopItemType.habitCard:
        return ShopAssetCategory.habitCard;
      case ShopItemType.userCard:
        return ShopAssetCategory.userCard;
      case ShopItemType.xpBoost:
      case ShopItemType.coinBoost:
      case ShopItemType.streakRecover:
      case ShopItemType.streakShield:
      case ShopItemType.mysteryBox:
      case null:
        return ShopAssetCategory.wallpaper;
    }
  }

  Widget _fallback() {
    return ShopPreviewPlaceholder(
      label: fallbackLabel ?? item?.title,
      tone: fallbackTone,
      height: height ?? 120.0,
      icon: fallbackIcon,
    );
  }
}

class ShopVisualAssetPreview extends StatelessWidget {
  const ShopVisualAssetPreview.asset({
    super.key,
    required this.asset,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.fallbackLabel,
    this.height,
    this.fit = BoxFit.cover,
    this.mode = ShopAssetPreviewMode.visual,
  });

  final ShopAsset asset;
  final ShopPreviewPlaceholderTone fallbackTone;
  final IconData fallbackIcon;
  final String? fallbackLabel;
  final double? height;
  final BoxFit fit;
  final ShopAssetPreviewMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == ShopAssetPreviewMode.applied &&
        asset.category == ShopAssetCategory.habitCard) {
      return ShopHabitCardAppliedPreview.asset(
        key: Key('shopHabitCardAppliedPreview-${asset.id}'),
        asset: asset,
      );
    }

    if (mode == ShopAssetPreviewMode.applied &&
        asset.category == ShopAssetCategory.userCard) {
      return ShopUserCardAppliedPreview.asset(
        key: Key('shopUserCardAppliedPreview-${asset.id}'),
        asset: asset,
      );
    }

    return ShopAssetSurfacePreview.asset(
      key: Key('shopAssetVisualPreview-${asset.id}'),
      asset: asset,
      fit: fit,
      fallbackLabel: fallbackLabel,
      fallbackTone: fallbackTone,
      fallbackIcon: fallbackIcon,
      height: height,
    );
  }
}

class ShopAssetSurfacePreview extends StatelessWidget {
  const ShopAssetSurfacePreview.asset({
    super.key,
    required this.asset,
    required this.fit,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.fallbackLabel,
    this.height,
  })  : assetPath = null,
        imageProvider = null,
        imageAlignment = null;

  const ShopAssetSurfacePreview.fallback({
    super.key,
    required this.assetPath,
    required this.fit,
    required this.fallbackTone,
    required this.fallbackIcon,
    this.fallbackLabel,
    this.height,
  })  : asset = null,
        imageProvider = null,
        imageAlignment = null;

  final ShopAsset? asset;
  final String? assetPath;
  final ImageProvider<Object>? imageProvider;
  final Alignment? imageAlignment;
  final BoxFit fit;
  final ShopPreviewPlaceholderTone fallbackTone;
  final IconData fallbackIcon;
  final String? fallbackLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final provider = imageProvider ?? asset?.imageProvider;
    final resolvedPath = assetPath ?? asset?.assetPath;
    final alignment =
        imageAlignment ?? asset?.imageAlignment ?? Alignment.center;

    if (provider != null) {
      return Image(
        key: _previewKey(),
        image: provider,
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    if (resolvedPath != null && resolvedPath.isNotEmpty) {
      return Image.asset(
        resolvedPath,
        key: _previewKey(),
        height: height,
        fit: fit,
        alignment: alignment,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Key _previewKey() {
    if (asset != null) {
      return Key('shopAssetPreview-${asset!.id}');
    }
    return Key('shopAssetPreview-${assetPath ?? 'fallback'}');
  }

  Widget _fallback() {
    return ShopPreviewPlaceholder(
      label: fallbackLabel ?? asset?.nameEs,
      tone: fallbackTone,
      height: height ?? 120,
      icon: fallbackIcon,
    );
  }
}

class ShopHabitCardAppliedPreview extends StatelessWidget {
  const ShopHabitCardAppliedPreview.asset({
    super.key,
    required this.asset,
  })  : assetPath = null,
        backgroundImageProvider = null,
        imageFit = null,
        backgroundImageAlignment = null,
        backgroundOverlayColor = null,
        backgroundOverlayOpacity = null,
        contentTone = null,
        useContentScrim = null,
        fallbackLabel = null;

  const ShopHabitCardAppliedPreview.fallback({
    super.key,
    required this.assetPath,
    required this.imageFit,
    this.fallbackLabel,
  })  : asset = null,
        backgroundImageProvider = null,
        backgroundImageAlignment = null,
        backgroundOverlayColor = null,
        backgroundOverlayOpacity = null,
        contentTone = null,
        useContentScrim = null;

  final ShopAsset? asset;
  final String? assetPath;
  final ImageProvider<Object>? backgroundImageProvider;
  final BoxFit? imageFit;
  final Alignment? backgroundImageAlignment;
  final Color? backgroundOverlayColor;
  final double? backgroundOverlayOpacity;
  final HabitCardContentTone? contentTone;
  final bool? useContentScrim;
  final String? fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: _resolvePreviewHeight(constraints.maxHeight),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: IgnorePointer(
                child: HabitCardWidget(
                  key: Key(
                    'shopAssetPreview-${asset?.id ?? assetPath ?? 'fallback'}',
                  ),
                  title: 'Leer 10 min',
                  description: 'Vista previa del estilo aplicado.',
                  familyColor: ShopUiTokens.accent,
                  progress: 0.35,
                  backgroundImageAssetPath: assetPath ?? asset?.assetPath,
                  backgroundImageProvider:
                      backgroundImageProvider ?? asset?.imageProvider,
                  backgroundImageFit:
                      imageFit ?? asset?.imageFit ?? BoxFit.cover,
                  backgroundImageAlignment: backgroundImageAlignment ??
                      asset?.imageAlignment ??
                      Alignment.center,
                  backgroundOverlayColor:
                      backgroundOverlayColor ?? asset?.overlayColor,
                  backgroundOverlayOpacity:
                      backgroundOverlayOpacity ?? asset?.overlayOpacity ?? 0,
                  contentTone: contentTone ??
                      asset?.contentTone ??
                      HabitCardContentTone.dark,
                  useContentScrim:
                      useContentScrim ?? asset?.useContentScrim ?? false,
                  reminderLabel: '07:30',
                  weeklyProgressLabel: '3/7 esta semana',
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _resolvePreviewHeight(double maxHeight) {
    if (maxHeight.isFinite && maxHeight > 0) {
      return maxHeight;
    }
    return 120;
  }
}

class ShopUserCardAppliedPreview extends StatelessWidget {
  const ShopUserCardAppliedPreview.asset({
    super.key,
    required this.asset,
  }) : assetPath = null;

  const ShopUserCardAppliedPreview.fallback({
    super.key,
    required this.assetPath,
  }) : asset = null;

  final ShopAsset? asset;
  final String? assetPath;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final height = _resolvePreviewHeight(constraints.maxHeight);
        return SizedBox(
          height: height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  width: double.infinity,
                  child: UserIdentityRow(
                    key: Key(
                      'shopAssetPreview-${asset?.id ?? assetPath ?? 'fallback'}',
                    ),
                    username: 'Rutio User',
                    level: 12,
                    coins: 640,
                    xpProgress: 0.68,
                    backgroundImageAssetPath: assetPath ?? asset?.assetPath,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _resolvePreviewHeight(double maxHeight) {
    if (maxHeight.isFinite && maxHeight > 0) {
      return maxHeight;
    }
    return 120;
  }
}

class _FallbackAssetPreviewData {
  const _FallbackAssetPreviewData({
    required this.assetPath,
    required this.category,
  });

  final String assetPath;
  final ShopAssetCategory category;
}
