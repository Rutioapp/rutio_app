import 'package:flutter/material.dart';
import 'package:rutio/widgets/backgrounds/home_landscape_background.dart';

class DiaryScreenBackground extends StatelessWidget {
  const DiaryScreenBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const HomeBackground(),
        Positioned.fill(child: child),
      ],
    );
  }
}
