import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_badge_zone.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

class HabitCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String? emoji;
  final VoidCallback? onEmojiTap;

  final Color familyColor;
  final double progress;

  final bool isCompleted;
  final VoidCallback? onCheckTap;

  final bool isCounting;
  final bool compact;

  final VoidCallback? onMenuTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onStatsTap;
  final void Function(int initialTab)? onOpenDetails;

  final VoidCallback? onTap;

  final num currentCount;
  final num targetCount;
  final String? unitLabel;
  final String? reminderLabel;

  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onCountTap;

  final String completionBurstText;

  const HabitCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.familyColor,
    required this.progress,
    this.emoji,
    this.onEmojiTap,
    this.isCompleted = false,
    this.onCheckTap,
    this.isCounting = false,
    this.compact = false,
    this.onMenuTap,
    this.onEditTap,
    this.onStatsTap,
    this.onOpenDetails,
    this.onTap,
    this.currentCount = 0,
    this.targetCount = 1,
    this.unitLabel,
    this.reminderLabel,
    this.onIncrement,
    this.onDecrement,
    this.onCountTap,
    this.completionBurstText = '+XP',
  });

  @override
  State<HabitCardWidget> createState() => _HabitCardWidgetState();
}

class _HabitCardWidgetState extends State<HabitCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fxController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _burstOpacity;
  late final Animation<Offset> _burstOffset;

  bool _showBurst = false;

  String _formatCountLabel(num value) {
    if (value is double && !value.isFinite) return '0';
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }

  bool get _logicalCompleted =>
      widget.isCompleted || (widget.isCounting && widget.progress >= 1.0);

  Widget _buildEmoji(double fontSize) {
    final emoji = widget.emoji;
    if (emoji == null) {
      return const SizedBox.shrink();
    }

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(emoji, style: TextStyle(fontSize: fontSize)),
    );

    if (widget.onEmojiTap == null) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onEmojiTap,
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();

    _fxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.035)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.035, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
    ]).animate(_fxController);

    _burstOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fxController,
        curve: const Interval(0.10, 0.35, curve: Curves.easeOut),
        reverseCurve: const Interval(0.45, 1.0, curve: Curves.easeIn),
      ),
    );

    _burstOffset = Tween<Offset>(
      begin: const Offset(0.0, 0.18),
      end: const Offset(0.0, -0.90),
    ).animate(
      CurvedAnimation(
        parent: _fxController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fxController.addStatusListener((status) {
      if (!mounted) return;
      if (status == AnimationStatus.forward) {
        setState(() => _showBurst = true);
      } else if (status == AnimationStatus.completed) {
        setState(() => _showBurst = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HabitCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldDone = oldWidget.isCompleted ||
        (oldWidget.isCounting && oldWidget.progress >= 1.0);
    final newDone = _logicalCompleted;

    if (!oldDone && newDone) {
      _playCompleteFx();
    }
  }

  void _playCompleteFx() {
    _fxController.forward(from: 0);
  }

  @override
  void dispose() {
    _fxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IOS-FIRST IMPROVEMENT START
    final radius = widget.compact ? 18.0 : 20.0;
    final verticalPadding = widget.compact ? 8.0 : 10.0;
    // IOS-FIRST IMPROVEMENT END
    final reminderLabel = widget.reminderLabel?.trim();
    final hasReminder = reminderLabel != null && reminderLabel.isNotEmpty;
    final compactCountLabel =
        '${_formatCountLabel(widget.currentCount)}/${_formatCountLabel(widget.targetCount)}';
    final countInfoLabel = widget.isCounting
        ? hasReminder
            ? compactCountLabel
            : (widget.unitLabel ?? '').trim().isEmpty
            ? context.l10n.homeHabitCountProgress(
                _formatCountLabel(widget.currentCount),
                _formatCountLabel(widget.targetCount),
              )
            : context.l10n.homeHabitCountProgressWithUnit(
                _formatCountLabel(widget.currentCount),
                _formatCountLabel(widget.targetCount),
                widget.unitLabel!.trim(),
              )
        : null;
    final badgeZone = hasReminder || widget.isCounting
        ? HabitCardBadgeZone(
            familyColor: widget.familyColor,
            compact: widget.compact,
            reminderLabel: reminderLabel,
            countLabel: countInfoLabel,
          )
        : null;

    void openDefault() {
      if (widget.onOpenDetails != null) {
        widget.onOpenDetails!.call(0);
        return;
      }
      if (widget.onEditTap != null) {
        widget.onEditTap!.call();
        return;
      }
      if (widget.onMenuTap != null) {
        widget.onMenuTap!.call();
      }
    }

    Widget content;

    if (!widget.isCounting) {
      content = Row(
        children: [
          const SizedBox(width: 16),
          if (widget.emoji != null) ...[
            _buildEmoji(widget.compact ? 20 : 22),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: widget.compact ? 14 : 15,
                  ),
                ),
                if (badgeZone != null) ...[
                  SizedBox(height: widget.compact ? 2 : 4),
                  badgeZone,
                ],
                if (widget.description.isNotEmpty)
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 13,
                      color: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCheckTap,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.familyColor, width: 1.6),
                    color: widget.isCompleted
                        ? widget.familyColor
                        : Colors.transparent,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: widget.isCompleted
                        ? const Icon(
                            CupertinoIcons.check_mark,
                            key: ValueKey('done'),
                            size: 17,
                            color: Colors.white,
                          )
                        : const SizedBox(
                            key: ValueKey('empty'),
                            width: 18,
                            height: 18,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      );
    } else {
      final ringProgress = widget.progress.clamp(0.0, 1.0);

      content = Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(radius),
                onTap: openDefault,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(
                    children: [
                      if (widget.emoji != null) ...[
                        _buildEmoji(widget.compact ? 20 : 22),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.compact ? 14 : 15,
                              ),
                            ),
                            if (badgeZone != null) ...[
                              SizedBox(height: widget.compact ? 2 : 4),
                              badgeZone,
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _CircleButton(
            icon: CupertinoIcons.minus,
            onTap: widget.onDecrement,
          ),
          const SizedBox(width: IosSpacing.xs),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCountTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _ProgressRingPainter(
                  progress: ringProgress,
                  progressColor: widget.familyColor,
                ),
                child: Center(
                  child: Text(
                    '${_formatCountLabel(widget.currentCount)}/${_formatCountLabel(widget.targetCount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: IosSpacing.xs),
          _CircleButton(
            icon: CupertinoIcons.add,
            onTap: widget.onIncrement,
          ),
          const SizedBox(width: 12),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _fxController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: widget.onTap ?? openDefault,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  constraints: BoxConstraints(
                    minHeight: widget.compact ? 68 : 76,
                  ),
                  padding: EdgeInsets.symmetric(vertical: verticalPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(radius),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: content,
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 10,
                        decoration: BoxDecoration(
                          color: widget.familyColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(radius),
                            bottomLeft: Radius.circular(radius),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showBurst)
                  Positioned(
                    top: -8,
                    right: 16,
                    child: SlideTransition(
                      position: _burstOffset,
                      child: FadeTransition(
                        opacity: _burstOpacity,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.familyColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(
                              IosCornerRadius.pill,
                            ),
                            border: Border.all(
                              color: widget.familyColor.withValues(alpha: 0.28),
                            ),
                          ),
                          child: Text(
                            widget.completionBurstText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: widget.familyColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              IosFeedback.selection();
              onTap!.call();
            },
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.72),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: Icon(
              icon,
              size: 17,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color progressColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.5;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    final sweep = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
