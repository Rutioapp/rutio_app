import 'package:flutter/material.dart';

class StatsCardSurface {
  const StatsCardSurface._();

  static const radius = 22.0;
  static const padding = EdgeInsets.fromLTRB(16, 14, 16, 16);

  static BoxDecoration decoration(BuildContext context, {Color? tint}) {
    final tintColor = tint ?? Colors.white;
    return BoxDecoration(
      color: tintColor,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          blurRadius: 14,
          offset: const Offset(0, 6),
          color: Colors.black.withValues(alpha: 0.04),
        ),
      ],
    );
  }
}
