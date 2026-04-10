import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/app_theme.dart';

class HomeAddFab extends StatefulWidget {
  const HomeAddFab({
    super.key,
    required this.onPressed,
    this.heroTag = 'home_add_fab',
    this.tooltip,
    this.isHighlighted = false,
  });

  final VoidCallback onPressed;
  final Object heroTag;
  final String? tooltip;
  final bool isHighlighted;

  @override
  State<HomeAddFab> createState() => _HomeAddFabState();
}

class _HomeAddFabState extends State<HomeAddFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.isHighlighted) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HomeAddFab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHighlighted == oldWidget.isHighlighted) {
      return;
    }

    if (widget.isHighlighted) {
      _pulseController
        ..reset()
        ..repeat();
      return;
    }

    _pulseController
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetGlowColor = AppColors.earth.withValues(alpha: 0.22);
    final targetRingColor = AppColors.earth.withValues(alpha: 0.18);

    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (widget.isHighlighted)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final curve = Curves.easeOutCubic;
                  final pulseValue = curve.transform(_pulseController.value);
                  final pulseScale = lerpDouble(0.94, 1.18, pulseValue) ?? 1;
                  final pulseOpacity = lerpDouble(0.18, 0.0, pulseValue) ?? 0.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: targetGlowColor,
                              blurRadius: 22,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: targetRingColor.withValues(
                                alpha: pulseOpacity,
                              ),
                              width: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          FloatingActionButton(
            heroTag: widget.heroTag,
            tooltip: widget.tooltip ?? context.l10n.homeAddFabTooltip,
            onPressed: widget.onPressed,
            elevation: widget.isHighlighted ? 10 : null,
            highlightElevation: widget.isHighlighted ? 12 : null,
            child: const Icon(CupertinoIcons.add),
          ),
        ],
      ),
    );
  }
}
