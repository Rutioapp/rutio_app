import 'package:flutter/material.dart';

class DiaryEntrySwipeActionBackground extends StatelessWidget {
  const DiaryEntrySwipeActionBackground({
    super.key,
    required this.alignment,
    required this.color,
    required this.child,
  });

  final Alignment alignment;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
