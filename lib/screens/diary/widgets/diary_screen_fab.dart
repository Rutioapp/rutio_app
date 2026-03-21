import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

class DiaryScreenFab extends StatelessWidget {
  const DiaryScreenFab({
    super.key,
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: collapsed ? 0.8 : 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        );
      },
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        extendedIconLabelSpacing: 8,
        icon: const Icon(Icons.add_rounded, size: 18),
        label: Text(context.l10n.diaryNewEntry),
      ),
    );
  }
}
