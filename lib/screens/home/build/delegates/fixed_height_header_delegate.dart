/// FixedHeightHeaderDelegate fija una altura constante para un sliver header.
///
/// Sirve como utilidad reutilizable cuando una cabecera debe permanecer anclada
/// con la misma altura mínima y máxima durante todo el scroll.
library;

import 'package:flutter/material.dart';

class FixedHeightHeaderDelegate extends SliverPersistentHeaderDelegate {
  FixedHeightHeaderDelegate({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant FixedHeightHeaderDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}
