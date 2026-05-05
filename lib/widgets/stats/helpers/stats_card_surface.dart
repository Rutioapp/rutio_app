import 'package:flutter/material.dart';

class StatsCardSurface {
  const StatsCardSurface._();

  static const radius = 24.0;
  static const padding = EdgeInsets.fromLTRB(16, 15, 16, 16);

  static BoxDecoration decoration(BuildContext context, {Color? tint}) {
    final tintColor = tint ?? const Color(0xFFFFFCF7);
    return BoxDecoration(
      color: tintColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.055)),
      boxShadow: [
        BoxShadow(
          blurRadius: 18,
          offset: const Offset(0, 8),
          color: Colors.black.withValues(alpha: 0.045),
        ),
      ],
    );
  }
}
