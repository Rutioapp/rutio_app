import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rutio/features/shop/domain/models/habit_card_content_tone.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_badge_zone.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_foreground_style.dart';
import 'package:rutio/ui/behaviours/ios_feedback.dart';
import 'package:rutio/ui/foundations/ios_foundations.dart';

const double _habitCardBorderWidth = 1.0;
const Color _habitCardBorderColor = Color(0x57FFFFFF);

enum HabitCompletionVisualIntent {
  complete,
  uncomplete,
}

class HabitCardWidget extends StatefulWidget {
  final String title;
  final String description;
  final String? emoji;
  final VoidCallback? onEmojiTap;

  final Color familyColor;
  final double progress;

  final bool isCompleted;
  final bool isSkipped;
  final FutureOr<void> Function()? onCheckTap;

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
  final String? weeklyProgressLabel;

  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onCountTap;

  final String completionBurstText;
  final String? backgroundImageAssetPath;
  final ImageProvider<Object>? backgroundImageProvider;
  final BoxFit backgroundImageFit;
  final Alignment backgroundImageAlignment;
  final Color? backgroundOverlayColor;
  final double backgroundOverlayOpacity;
  final HabitCardContentTone contentTone;
  final bool useContentScrim;

  const HabitCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.familyColor,
    required this.progress,
    this.emoji,
    this.onEmojiTap,
    this.isCompleted = false,
    this.isSkipped = false,
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
    this.weeklyProgressLabel,
    this.onIncrement,
    this.onDecrement,
    this.onCountTap,
    this.completionBurstText = '+XP',
    this.backgroundImageAssetPath,
    this.backgroundImageProvider,
    this.backgroundImageFit = BoxFit.cover,
    this.backgroundImageAlignment = Alignment.center,
    this.backgroundOverlayColor,
    this.backgroundOverlayOpacity = 0,
    this.contentTone = HabitCardContentTone.dark,
    this.useContentScrim = false,
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
  bool _isCheckTapInFlight = false;
  ImageProvider<Object>? _lastPrecachedBackgroundProvider;

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
      key: const Key('habitCardEmoji'),
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheBackgroundIfNeeded();
  }

  @override
  void didUpdateWidget(covariant HabitCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _precacheBackgroundIfNeeded();

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

  Future<void> _handleCheckTap() async {
    final callback = widget.onCheckTap;
    if (callback == null || _isCheckTapInFlight) return;
    setState(() => _isCheckTapInFlight = true);
    try {
      await Future<void>.sync(callback);
    } finally {
      if (mounted) {
        setState(() => _isCheckTapInFlight = false);
      }
    }
  }

  void _precacheBackgroundIfNeeded() {
    final provider = widget.backgroundImageProvider ??
        (widget.backgroundImageAssetPath == null
            ? null
            : buildShopAssetImageProvider(widget.backgroundImageAssetPath!));
    if (provider == null || provider == _lastPrecachedBackgroundProvider) {
      return;
    }
    _lastPrecachedBackgroundProvider = provider;
    precacheImage(provider, context);
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
    final innerRadius = math.max(0.0, radius - _habitCardBorderWidth);
    // IOS-FIRST IMPROVEMENT END
    final isSkipped = widget.isSkipped;
    final controlOpacity = isSkipped ? 0.82 : 1.0;
    final backgroundImageProvider = widget.backgroundImageProvider ??
        (widget.backgroundImageAssetPath == null
            ? null
            : buildShopAssetImageProvider(widget.backgroundImageAssetPath!));
    _logFirstFrame(backgroundImageProvider != null);
    final hasBackgroundOverlay = backgroundImageProvider != null &&
        widget.backgroundOverlayColor != null &&
        widget.backgroundOverlayOpacity > 0;
    final foregroundStyle = resolveHabitCardForegroundStyle(widget.contentTone);
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
    final weeklyProgressLabel = widget.weeklyProgressLabel?.trim();
    final hasWeeklyProgress =
        weeklyProgressLabel != null && weeklyProgressLabel.isNotEmpty;
    final badgeZone =
        hasReminder || widget.isCounting || isSkipped || hasWeeklyProgress
            ? HabitCardBadgeZone(
                familyColor: widget.familyColor,
                compact: widget.compact,
                foregroundStyle: foregroundStyle,
                reminderLabel: reminderLabel,
                countLabel: countInfoLabel,
                progressLabel: hasWeeklyProgress ? weeklyProgressLabel : null,
                extraBadges: isSkipped
                    ? [
                        HabitSkippedBadge(
                          label: context.l10n.homeSkippedToday,
                          compact: widget.compact,
                          foregroundStyle: foregroundStyle,
                        ),
                      ]
                    : const <Widget>[],
              )
            : null;

    void openDefault() {
      if (widget.onOpenDetails != null) {
        widget.onOpenDetails!.call(1);
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
                  key: const Key('habitCardTitle'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: widget.compact ? 14 : 15,
                    color: foregroundStyle.primaryText,
                    shadows: foregroundStyle.emphasisShadows,
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
                      color: foregroundStyle.secondaryText,
                      shadows: foregroundStyle.emphasisShadows,
                    ),
                  ),
              ],
            ),
          ),
          Opacity(
            opacity: controlOpacity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCheckTap == null || _isCheckTapInFlight
                  ? null
                  : () {
                      unawaited(_handleCheckTap());
                    },
              child: SizedBox(
                key: const Key('habitCardCheckControl'),
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
                      border: Border.all(
                        color: foregroundStyle.accentColor(widget.familyColor),
                        width: 1.6,
                      ),
                      color: widget.isCompleted
                          ? foregroundStyle.accentColor(widget.familyColor)
                          : Colors.transparent,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child:
                              FadeTransition(opacity: animation, child: child),
                        );
                      },
                      child: widget.isCompleted
                          ? Icon(
                              CupertinoIcons.check_mark,
                              key: const ValueKey('done'),
                              size: 17,
                              color: foregroundStyle.iconColor,
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
                onTap: widget.onTap ?? openDefault,
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
                              key: const Key('habitCardTitle'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: widget.compact ? 14 : 15,
                                color: foregroundStyle.primaryText,
                                shadows: foregroundStyle.emphasisShadows,
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
          Opacity(
            opacity: controlOpacity,
            child: _CircleButton(
              key: const Key('habitCardCountDecrementControl'),
              icon: CupertinoIcons.minus,
              onTap: widget.onDecrement,
              foregroundStyle: foregroundStyle,
            ),
          ),
          const SizedBox(width: IosSpacing.xs),
          Opacity(
            opacity: controlOpacity,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCountTap,
              child: SizedBox(
                key: const Key('habitCardCountValueControl'),
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: ringProgress,
                    progressColor: widget.familyColor,
                    foregroundStyle: foregroundStyle,
                  ),
                  child: Center(
                    child: Text(
                      '${_formatCountLabel(widget.currentCount)}/${_formatCountLabel(widget.targetCount)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: foregroundStyle.primaryText,
                        shadows: foregroundStyle.emphasisShadows,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: IosSpacing.xs),
          Opacity(
            opacity: controlOpacity,
            child: _CircleButton(
              key: const Key('habitCardCountIncrementControl'),
              icon: CupertinoIcons.add,
              onTap: widget.onIncrement,
              foregroundStyle: foregroundStyle,
            ),
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
          child: Container(
            key: const Key('habitCardSurface'),
            constraints: BoxConstraints(
              minHeight: widget.compact ? 68 : 76,
            ),
            decoration: BoxDecoration(
              color: backgroundImageProvider == null
                  ? Colors.white.withValues(alpha: 0.74)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: _habitCardBorderColor,
                width: _habitCardBorderWidth,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_habitCardBorderWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (backgroundImageProvider != null)
                      Positioned.fill(
                        child: Image(
                          key: const Key('habitCardBackgroundImage'),
                          image: backgroundImageProvider,
                          fit: widget.backgroundImageFit,
                          alignment: widget.backgroundImageAlignment,
                          gaplessPlayback: true,
                          errorBuilder: (_, error, stackTrace) {
                            if (kDebugMode) {
                              debugPrint(
                                '[ShopCosmetics] HabitCardWidget failed to load '
                                'backgroundImageAssetPath=${widget.backgroundImageAssetPath} '
                                'error=$error',
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    if (hasBackgroundOverlay)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: widget.backgroundOverlayColor!.withValues(
                              alpha: widget.backgroundOverlayOpacity,
                            ),
                          ),
                        ),
                      ),
                    if (widget.useContentScrim)
                      const Positioned.fill(
                        child: DecoratedBox(
                          key: Key('habitCardContentScrim'),
                          decoration: BoxDecoration(
                            gradient: habitCardContentScrim,
                          ),
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: verticalPadding),
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
                                topLeft: Radius.circular(innerRadius),
                                bottomLeft: Radius.circular(innerRadius),
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
                                color: foregroundStyle
                                    .accentSurface(widget.familyColor),
                                borderRadius: BorderRadius.circular(
                                  IosCornerRadius.pill,
                                ),
                                border: Border.all(
                                  color: foregroundStyle
                                      .accentBorder(widget.familyColor),
                                ),
                              ),
                              child: Text(
                                widget.completionBurstText,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: foregroundStyle
                                      .accentColor(widget.familyColor),
                                  shadows: foregroundStyle.emphasisShadows,
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
        ),
      ),
    );
  }

  void _logFirstFrame(bool hasBackgroundImage) {
    if (!kDebugMode) return;
    debugPrint(
      '[HomeFirstFrame] component=habit_card '
      'inputAsset=${widget.backgroundImageAssetPath == null ? 'null' : 'present'} '
      'displayedAsset=${hasBackgroundImage ? 'present' : 'null'} '
      'fallback=${!hasBackgroundImage}',
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final HabitCardForegroundStyle foregroundStyle;

  const _CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.foregroundStyle,
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
              color: foregroundStyle.controlSurface,
              border: Border.all(color: foregroundStyle.controlBorder),
            ),
            child: Icon(
              icon,
              size: 17,
              color: foregroundStyle.controlIcon,
              shadows: foregroundStyle.emphasisShadows,
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
  final HabitCardForegroundStyle foregroundStyle;

  const _ProgressRingPainter({
    required this.progress,
    required this.progressColor,
    required this.foregroundStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 4.5;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final trackPaint = Paint()
      ..color = foregroundStyle.progressTrackColor
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
        oldDelegate.progressColor != progressColor ||
        oldDelegate.foregroundStyle != foregroundStyle;
  }
}
