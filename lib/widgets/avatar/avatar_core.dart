import 'dart:io';

import 'package:flutter/material.dart';

import 'avatar_ring_palette.dart';

class AvatarCore extends StatelessWidget {
  final String? avatarUrl;
  final String fallbackLabel;
  final double size;
  final AvatarRingPalette palette;
  final BoxFit fit;

  const AvatarCore({
    super.key,
    required this.avatarUrl,
    required this.fallbackLabel,
    required this.size,
    required this.palette,
    this.fit = BoxFit.fitHeight,
  });

  @override
  Widget build(BuildContext context) {
    final provider = _resolveAvatarProvider(avatarUrl?.trim());
    final borderWidth = (size * 0.01).clamp(0.35, 0.55).toDouble();

    return SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.surfaceColor,
          border: Border.all(
            color: palette.borderColor,
            width: borderWidth,
          ),
        ),
        child: ClipOval(
          child: provider == null
              ? _AvatarFallback(
                  fallbackLabel: fallbackLabel,
                  palette: palette,
                  size: size,
                )
              : FittedBox(
                  fit: fit,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: Image(
                      image: provider,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.medium,
                      errorBuilder: (_, __, ___) => _AvatarFallback(
                        fallbackLabel: fallbackLabel,
                        palette: palette,
                        size: size,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  ImageProvider<Object>? _resolveAvatarProvider(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return NetworkImage(raw);
    }

    final normalized = raw.startsWith('file://') ? raw.substring(7) : raw;
    return FileImage(File(normalized));
  }
}

class _AvatarFallback extends StatelessWidget {
  final String fallbackLabel;
  final AvatarRingPalette palette;
  final double size;

  const _AvatarFallback({
    required this.fallbackLabel,
    required this.palette,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = fallbackLabel.trim();
    final initial = trimmed.isEmpty ? 'U' : trimmed.substring(0, 1).toUpperCase();
    final fontSize = (size * 0.38).clamp(13.0, 24.0).toDouble();

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.fallbackStartColor,
            palette.fallbackEndColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontFamily: 'DMSans',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: palette.fallbackForegroundColor,
          ),
        ),
      ),
    );
  }
}
