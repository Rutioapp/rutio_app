import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../features/shop/application/shop_cosmetics_controller.dart';
import '../../features/shop/domain/models/shop_asset.dart';

typedef ImagePrecacheCallback = Future<void> Function(
  ImageProvider<Object> provider,
  BuildContext context,
);

class HomeBackgroundBootstrapResult {
  const HomeBackgroundBootstrapResult({
    required this.wallpaperAsset,
    required this.usedFallback,
    required this.didPrecacheCustomWallpaper,
  });

  final ShopAsset? wallpaperAsset;
  final bool usedFallback;
  final bool didPrecacheCustomWallpaper;
}

class HomeBackgroundBootstrapper {
  HomeBackgroundBootstrapper({
    required ShopCosmeticsController controller,
    ImagePrecacheCallback? precacheImageCallback,
    this.wallpaperPreparationTimeout = const Duration(seconds: 3),
  })  : _controller = controller,
        _precacheImageCallback =
            precacheImageCallback ?? _defaultPrecacheImageCallback;

  final ShopCosmeticsController _controller;
  final ImagePrecacheCallback _precacheImageCallback;
  final Duration wallpaperPreparationTimeout;

  Future<HomeBackgroundBootstrapResult> prepare(BuildContext context) async {
    try {
      await _controller.hydrate();
      if (!context.mounted) {
        throw StateError('BuildContext disposed during wallpaper bootstrap');
      }
      final wallpaperAsset = _controller.getEquippedWallpaperAssetOrNullSync();
      if (wallpaperAsset == null) {
        return const HomeBackgroundBootstrapResult(
          wallpaperAsset: null,
          usedFallback: true,
          didPrecacheCustomWallpaper: false,
        );
      }

      final provider = AssetImage(wallpaperAsset.assetPath);
      await _precacheImageCallback(
        provider,
        context,
      ).timeout(wallpaperPreparationTimeout);

      return HomeBackgroundBootstrapResult(
        wallpaperAsset: wallpaperAsset,
        usedFallback: false,
        didPrecacheCustomWallpaper: true,
      );
    } catch (_) {
      return const HomeBackgroundBootstrapResult(
        wallpaperAsset: null,
        usedFallback: true,
        didPrecacheCustomWallpaper: false,
      );
    }
  }

  static Future<void> _defaultPrecacheImageCallback(
    ImageProvider<Object> provider,
    BuildContext context,
  ) {
    return precacheImage(provider, context);
  }
}
