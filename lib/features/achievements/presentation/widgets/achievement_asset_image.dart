import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AchievementAssetImage extends StatelessWidget {
  const AchievementAssetImage({
    super.key,
    required this.assetPath,
    this.fit = BoxFit.contain,
    this.tintColor,
  });

  final String assetPath;
  final BoxFit fit;
  final Color? tintColor;

  static final RegExp _embeddedPngPattern = RegExp(
    r'data:image/png;base64,([^"]+)',
    caseSensitive: false,
  );

  static final Map<String, Future<Uint8List?>> _svgEmbeddedPngCache =
      <String, Future<Uint8List?>>{};

  @override
  Widget build(BuildContext context) {
    final image = _isRasterAsset(assetPath)
        ? _buildRasterAsset()
        : FutureBuilder<Uint8List?>(
            future: _svgEmbeddedPngCache.putIfAbsent(
              assetPath,
              () => _loadEmbeddedPngFromSvg(assetPath),
            ),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes != null && bytes.isNotEmpty) {
                return Image.memory(
                  bytes,
                  fit: fit,
                  gaplessPlayback: true,
                );
              }

              return SvgPicture.asset(
                assetPath,
                fit: fit,
                placeholderBuilder: (_) => _buildPlainPlaceholder(),
              );
            },
          );

    if (tintColor == null) return image;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(tintColor!, BlendMode.srcIn),
      child: image,
    );
  }

  Widget _buildRasterAsset() {
    return Image.asset(
      assetPath,
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _buildPlainPlaceholder(),
    );
  }

  Widget _buildPlainPlaceholder() {
    return const SizedBox.expand(
      child: ColoredBox(color: Color(0x11000000)),
    );
  }

  static bool _isRasterAsset(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  static Future<Uint8List?> _loadEmbeddedPngFromSvg(String assetPath) async {
    try {
      final rawSvg = await rootBundle.loadString(assetPath);
      final matches =
          _embeddedPngPattern.allMatches(rawSvg).toList(growable: false);
      if (matches.isEmpty) return null;

      final base64Data = matches.last.group(1);
      if (base64Data == null || base64Data.isEmpty) return null;

      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }
}
