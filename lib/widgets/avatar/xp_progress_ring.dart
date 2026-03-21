import 'package:flutter/material.dart';

import 'avatar_ring_palette.dart';
import 'xp_ring_painter.dart';

class XpProgressRing extends StatefulWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final Curve curve;
  final AvatarRingPalette palette;
  final Widget child;

  const XpProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.strokeWidth,
    required this.palette,
    required this.child,
    this.duration = const Duration(milliseconds: 680),
    this.curve = Curves.easeInOutCubic,
  });

  @override
  State<XpProgressRing> createState() => _XpProgressRingState();
}

class _XpProgressRingState extends State<XpProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _from = 0;
  double _to = 0;

  @override
  void initState() {
    super.initState();
    _to = widget.progress.clamp(0.0, 1.0).toDouble();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = AlwaysStoppedAnimation<double>(_to);
  }

  @override
  void didUpdateWidget(covariant XpProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    final next = widget.progress.clamp(0.0, 1.0).toDouble();
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }

    if ((next - _to).abs() < 0.0001) return;

    _from = _animation.value;
    _to = next;
    _controller
      ..stop()
      ..reset();
    _animation = Tween<double>(begin: _from, end: _to).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        child: Center(child: widget.child),
        builder: (context, child) {
          return RepaintBoundary(
            child: CustomPaint(
              painter: XpRingPainter(
                progress: _animation.value,
                strokeWidth: widget.strokeWidth,
                palette: widget.palette,
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

