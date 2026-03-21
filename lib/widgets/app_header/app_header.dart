import 'package:flutter/material.dart';

import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

/// Header base reusable.
///
/// Uses a Stack so LEFT / CENTER / RIGHT don't fight for width.
/// This avoids the common issue where the CENTER Expanded steals width
/// and RIGHT becomes 0px ("disappears").
class AppHeader extends StatelessWidget {
  final Widget? left;
  final Widget? center;
  final Widget? right;

  /// Height of the header (excluding SafeArea).
  final double height;

  /// Outer padding.
  final EdgeInsets padding;

  const AppHeader({
    super.key,
    this.left,
    this.center,
    this.right,
    this.height = 72,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (left != null)
              Align(
                alignment: Alignment.centerLeft,
                child: left!,
              ),
            if (center != null)
              Align(
                alignment: Alignment.center,
                child: center!,
              ),
            if (right != null)
              Align(
                alignment: Alignment.centerRight,
                child: right!,
              ),
          ],
        ),
      ),
    );
  }
}

/// Simple rounded icon button used in the header.
class HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size,
          color: Colors.black,
        ),
      ),
    );
  }
}

class AppDrawerButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? tooltip;
  final Color color;
  final double boxSize;
  final double iconSize;

  const AppDrawerButton({
    super.key,
    required this.onTap,
    this.tooltip,
    this.color = Colors.black,
    this.boxSize = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          IosFeedback.selection();
          onTap();
        },
        borderRadius: BorderRadius.circular(IosCornerRadius.control),
        child: Ink(
          width: boxSize,
          height: boxSize,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(IosCornerRadius.control),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.menu_rounded,
            size: iconSize,
            color: color.withValues(alpha: 0.82),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      child = Tooltip(message: tooltip!, child: child);
    }

    return child;
  }
}

class AppDrawerAppBarLeading extends StatelessWidget {
  static const double leadingWidth = 64;

  final VoidCallback onTap;
  final String? tooltip;
  final Color color;

  const AppDrawerAppBarLeading({
    super.key,
    required this.onTap,
    this.tooltip,
    this.color = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: IosSpacing.lg),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppDrawerButton(
          onTap: onTap,
          tooltip: tooltip,
          color: color,
        ),
      ),
    );
  }
}
