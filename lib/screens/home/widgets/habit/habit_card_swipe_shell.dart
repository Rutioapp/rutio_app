import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

@visibleForTesting
enum HabitCardSwipeVisualState {
  idle,
  dragging,
  settlingClosed,
  settlingLeftOpen,
  committingRight,
  actionInFlight,
}

@visibleForTesting
class HabitCardSwipeMotionConfig {
  const HabitCardSwipeMotionConfig({
    this.leftActionsExtent = 234,
    this.leftOpenThresholdFraction = 0.45,
    this.rightCommitThresholdFraction = 0.50,
    this.rightFlickMinDistanceFraction = 0.08,
    this.rightFlickVelocity = 700,
    this.leftFlickVelocity = 700,
    this.rightVisualLimitFraction = 0.60,
    this.overdragResistance = 0.20,
    this.maxOverscroll = 36,
    this.settleTolerance = 0.5,
    this.springMass = 1.0,
    this.springStiffness = 480.0,
    this.springDamping = 42.0,
    this.springToleranceDistance = 0.5,
    this.springToleranceVelocity = 5.0,
  });

  final double leftActionsExtent;
  final double leftOpenThresholdFraction;
  final double rightCommitThresholdFraction;
  final double rightFlickMinDistanceFraction;
  final double rightFlickVelocity;
  final double leftFlickVelocity;
  final double rightVisualLimitFraction;
  final double overdragResistance;
  final double maxOverscroll;
  final double settleTolerance;
  final double springMass;
  final double springStiffness;
  final double springDamping;
  final double springToleranceDistance;
  final double springToleranceVelocity;

  double get revealWidth => leftActionsExtent;
  double get closedOffset => 0;
  double get openOffset => -leftActionsExtent;
  double get leftOpenThreshold => leftActionsExtent * leftOpenThresholdFraction;

  double rightCommitThreshold(double cardWidth) {
    return cardWidth * rightCommitThresholdFraction;
  }

  double rightFlickMinDistance(double cardWidth) {
    return cardWidth * rightFlickMinDistanceFraction;
  }

  double rightVisualLimit(double cardWidth) {
    return cardWidth * rightVisualLimitFraction;
  }

  SpringDescription get springDescription {
    return SpringDescription(
      mass: springMass,
      stiffness: springStiffness,
      damping: springDamping,
    );
  }

  Tolerance get springTolerance {
    return Tolerance(
      distance: springToleranceDistance,
      velocity: springToleranceVelocity,
    );
  }

  SpringSimulation springSimulation({
    required double start,
    required double target,
    required double velocity,
  }) {
    return SpringSimulation(
      springDescription,
      start,
      target,
      velocity,
      snapToEnd: true,
      tolerance: springTolerance,
    );
  }

  double applyDragDelta({
    required double currentOffset,
    required double delta,
    required double cardWidth,
    required bool canSwipeRightComplete,
  }) {
    return applyBounds(
      currentOffset + delta,
      cardWidth: cardWidth,
      canSwipeRightComplete: canSwipeRightComplete,
    );
  }

  double applyBounds(
    double rawOffset, {
    required double cardWidth,
    required bool canSwipeRightComplete,
  }) {
    final rightLimit =
        canSwipeRightComplete ? rightVisualLimit(cardWidth) : 0.0;
    if (rawOffset < openOffset) {
      final excess = openOffset - rawOffset;
      return openOffset - _resistedOverscroll(excess);
    }
    if (rawOffset > rightLimit) {
      final excess = rawOffset - rightLimit;
      return rightLimit + _resistedOverscroll(excess);
    }
    return rawOffset;
  }

  HabitCardSwipeDestination resolveSwipeDestination({
    required double offset,
    required double velocity,
    required double cardWidth,
    required double leftActionsExtent,
    required bool startedFromOpenTray,
    required bool canSwipeRightComplete,
    required bool hasRightCompleteCallback,
  }) {
    final canCompleteFromSwipe = !startedFromOpenTray &&
        canSwipeRightComplete &&
        hasRightCompleteCallback;
    final passedRightThreshold = offset >= rightCommitThreshold(cardWidth);
    final flingRight = velocity >= rightFlickVelocity &&
        offset >= rightFlickMinDistance(cardWidth);

    if (canCompleteFromSwipe && (passedRightThreshold || flingRight)) {
      return HabitCardSwipeDestination.rightCommit;
    }

    if (offset > 0) {
      return HabitCardSwipeDestination.closed;
    }

    final shouldOpen =
        offset.abs() >= leftActionsExtent * leftOpenThresholdFraction ||
            velocity <= -leftFlickVelocity;
    if (shouldOpen) {
      return HabitCardSwipeDestination.leftOpen;
    }

    return HabitCardSwipeDestination.closed;
  }

  double progressForOffset(double offset, double targetExtent) {
    if (targetExtent <= 0) return 0;
    return (offset / targetExtent).clamp(0.0, 1.0);
  }

  double _resistedOverscroll(double excess) {
    return (excess * overdragResistance).clamp(0.0, maxOverscroll);
  }
}

@visibleForTesting
enum HabitCardSwipeDestination {
  closed,
  leftOpen,
  rightCommit,
}

@visibleForTesting
HabitCardSwipeDestination resolveSwipeDestination({
  required double offset,
  required double velocity,
  required double cardWidth,
  required double leftActionsExtent,
  required bool startedOpen,
  required bool canSwipeRightComplete,
  required bool hasRightCompleteCallback,
  required HabitCardSwipeMotionConfig config,
}) {
  return config.resolveSwipeDestination(
    offset: offset,
    velocity: velocity,
    cardWidth: cardWidth,
    leftActionsExtent: leftActionsExtent,
    startedFromOpenTray: startedOpen,
    canSwipeRightComplete: canSwipeRightComplete,
    hasRightCompleteCallback: hasRightCompleteCallback,
  );
}

class HabitCardSwipeShell extends StatefulWidget {
  const HabitCardSwipeShell({
    super.key,
    required this.cardId,
    required this.child,
    required this.isOpen,
    required this.compact,
    required this.canSwipeRightComplete,
    required this.skipLabel,
    required this.editLabel,
    required this.deleteLabel,
    required this.onRequestCloseOtherCards,
    required this.onRequestOpen,
    required this.onRequestClose,
    required this.onSwipeRightComplete,
    required this.onSkip,
    required this.onEdit,
    required this.onDelete,
    this.motionConfig = const HabitCardSwipeMotionConfig(),
  });

  final String cardId;
  final Widget child;
  final bool isOpen;
  final bool compact;
  final bool canSwipeRightComplete;
  final String skipLabel;
  final String editLabel;
  final String deleteLabel;
  final void Function(String cardId) onRequestCloseOtherCards;
  final void Function(String cardId) onRequestOpen;
  final VoidCallback onRequestClose;
  final Future<void> Function()? onSwipeRightComplete;
  final Future<void> Function() onSkip;
  final VoidCallback? onEdit;
  final Future<void> Function() onDelete;
  final HabitCardSwipeMotionConfig motionConfig;

  @override
  State<HabitCardSwipeShell> createState() => _HabitCardSwipeShellState();
}

class _HabitCardSwipeShellState extends State<HabitCardSwipeShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  double _offset = 0;
  double _cardWidth = 0;
  int _settleGeneration = 0;
  HabitCardSwipeVisualState _visualState = HabitCardSwipeVisualState.idle;
  bool _startedFromOpenTray = false;

  HabitCardSwipeMotionConfig get _config => widget.motionConfig;
  bool get _isInteractionLocked =>
      _visualState == HabitCardSwipeVisualState.committingRight ||
      _visualState == HabitCardSwipeVisualState.actionInFlight;

  @override
  void initState() {
    super.initState();
    _offset = widget.isOpen ? _config.openOffset : 0;
    _controller = AnimationController.unbounded(vsync: this, value: _offset)
      ..addListener(() {
        _offset = _controller.value;
      });
  }

  @override
  void didUpdateWidget(covariant HabitCardSwipeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_visualState == HabitCardSwipeVisualState.dragging ||
        _isInteractionLocked) {
      return;
    }

    if (oldWidget.isOpen != widget.isOpen) {
      _settleTo(
        widget.isOpen ? _config.openOffset : 0,
        widget.isOpen
            ? HabitCardSwipeVisualState.settlingLeftOpen
            : HabitCardSwipeVisualState.settlingClosed,
        velocity: 0,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settleTo(
    double target,
    HabitCardSwipeVisualState settlingState, {
    required double velocity,
  }) {
    final clampedTarget =
        target.clamp(_config.openOffset, _config.rightVisualLimit(_cardWidth));
    final currentOffset = _controller.value;
    _offset = currentOffset;
    _settleGeneration += 1;
    final generation = _settleGeneration;

    if ((currentOffset - clampedTarget).abs() < _config.settleTolerance &&
        velocity.abs() < _config.springToleranceVelocity) {
      setState(() {
        _offset = clampedTarget;
        _controller.value = clampedTarget;
        if (settlingState != HabitCardSwipeVisualState.committingRight) {
          _visualState = HabitCardSwipeVisualState.idle;
        }
      });
      return;
    }

    _controller.stop();
    _controller.value = currentOffset;
    setState(() => _visualState = settlingState);
    final simulation = _config.springSimulation(
      start: currentOffset,
      target: clampedTarget,
      velocity: velocity,
    );
    _controller.animateWith(simulation).whenComplete(() {
      if (!mounted ||
          _visualState != settlingState ||
          generation != _settleGeneration) {
        return;
      }
      setState(() {
        _offset = clampedTarget;
        _controller.value = clampedTarget;
        if (settlingState == HabitCardSwipeVisualState.committingRight) {
          return;
        }
        _visualState = HabitCardSwipeVisualState.idle;
      });
    });
  }

  Future<void> _handleAction(Future<void> Function() callback) async {
    if (_isInteractionLocked) return;
    setState(() => _visualState = HabitCardSwipeVisualState.actionInFlight);
    try {
      widget.onRequestClose();
      await callback();
    } finally {
      if (mounted && _visualState == HabitCardSwipeVisualState.actionInFlight) {
        setState(() => _visualState = HabitCardSwipeVisualState.idle);
      }
    }
  }

  Future<void> _handleSyncAction(VoidCallback callback) async {
    if (_isInteractionLocked) return;
    setState(() => _visualState = HabitCardSwipeVisualState.actionInFlight);
    try {
      widget.onRequestClose();
      callback();
    } finally {
      if (mounted && _visualState == HabitCardSwipeVisualState.actionInFlight) {
        setState(() => _visualState = HabitCardSwipeVisualState.idle);
      }
    }
  }

  void _handleHorizontalStart(DragStartDetails details) {
    if (_isInteractionLocked) return;
    _settleGeneration += 1;
    if (_controller.isAnimating) {
      _offset = _controller.value;
    }
    _controller.stop();
    _controller.value = _offset;
    _visualState = HabitCardSwipeVisualState.dragging;
    _startedFromOpenTray = widget.isOpen || _offset < -0.5;
    widget.onRequestCloseOtherCards(widget.cardId);
  }

  void _handleHorizontalUpdate(DragUpdateDetails details) {
    if (_visualState != HabitCardSwipeVisualState.dragging) return;
    final dx = details.delta.dx;
    if (dx == 0) return;

    final nextOffset = _config.applyDragDelta(
      currentOffset: _offset,
      delta: dx,
      cardWidth: _cardWidth,
      canSwipeRightComplete:
          widget.canSwipeRightComplete && widget.onSwipeRightComplete != null,
    );
    if (nextOffset == _offset) return;

    setState(() {
      _offset = nextOffset;
      _controller.value = nextOffset;
      if (_offset < -2 && !widget.isOpen) {
        widget.onRequestOpen(widget.cardId);
      }
    });
  }

  Future<void> _handleHorizontalEnd(DragEndDetails details) async {
    if (_visualState != HabitCardSwipeVisualState.dragging) return;
    final rightVelocity = details.velocity.pixelsPerSecond.dx;
    final target = resolveSwipeDestination(
      offset: _offset,
      velocity: rightVelocity,
      cardWidth: _cardWidth,
      leftActionsExtent: _config.leftActionsExtent,
      startedOpen: _startedFromOpenTray,
      canSwipeRightComplete: widget.canSwipeRightComplete,
      hasRightCompleteCallback: widget.onSwipeRightComplete != null,
      config: _config,
    );
    _startedFromOpenTray = false;

    if (target == HabitCardSwipeDestination.rightCommit) {
      await _commitRight(rightVelocity);
      return;
    }

    if (target == HabitCardSwipeDestination.leftOpen) {
      widget.onRequestOpen(widget.cardId);
      _settleTo(
        _config.openOffset,
        HabitCardSwipeVisualState.settlingLeftOpen,
        velocity: rightVelocity,
      );
      return;
    }

    widget.onRequestClose();
    _settleTo(
      0,
      HabitCardSwipeVisualState.settlingClosed,
      velocity: rightVelocity,
    );
  }

  Future<void> _commitRight(double velocity) async {
    if (_isInteractionLocked || widget.onSwipeRightComplete == null) return;
    setState(() => _visualState = HabitCardSwipeVisualState.committingRight);
    _settleTo(0, HabitCardSwipeVisualState.committingRight, velocity: velocity);
    try {
      await widget.onSwipeRightComplete!.call();
    } finally {
      if (mounted &&
          _visualState == HabitCardSwipeVisualState.committingRight) {
        setState(() => _visualState = HabitCardSwipeVisualState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final revealWidth = _config.revealWidth;
    final verticalInset = widget.compact ? 6.0 : 8.0;
    final radius = widget.compact ? 18.0 : 20.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        _cardWidth = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : _cardWidth;
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = _controller.value;
            final revealProgress = _config.progressForOffset(
              offset < 0 ? offset.abs() : 0.0,
              revealWidth,
            );
            final showTray = revealProgress > 0.001;
            final rightProgress = _config.progressForOffset(
              offset,
              _config.rightVisualLimit(_cardWidth),
            );
            final showRightCue =
                widget.canSwipeRightComplete && rightProgress > 0.001;

            return Stack(
              children: [
                if (showRightCue)
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: verticalInset),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen
                            .withValues(alpha: 0.04 + (0.06 * rightProgress)),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            size: 20,
                            color: CupertinoColors.systemGreen.withValues(
                                alpha: 0.34 + (0.22 * rightProgress)),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (showTray)
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: verticalInset),
                      decoration: BoxDecoration(
                        color:
                            CupertinoColors.systemGrey6.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(radius),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: revealWidth,
                          child: Row(
                            children: [
                              _SwipeTrayActionButton(
                                icon: CupertinoIcons.forward_end_fill,
                                label: widget.skipLabel,
                                onTap: _isInteractionLocked
                                    ? null
                                    : () => _handleAction(widget.onSkip),
                              ),
                              _SwipeTrayActionButton(
                                icon: CupertinoIcons.pencil,
                                label: widget.editLabel,
                                onTap: widget.onEdit == null ||
                                        _isInteractionLocked
                                    ? null
                                    : () => _handleSyncAction(widget.onEdit!),
                              ),
                              _SwipeTrayActionButton(
                                icon: CupertinoIcons.delete,
                                label: widget.deleteLabel,
                                isDestructive: true,
                                onTap: _isInteractionLocked
                                    ? null
                                    : () => _handleAction(widget.onDelete),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                RepaintBoundary(
                  child: Transform.translate(
                    offset: Offset(offset, 0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _handleHorizontalStart,
                      onHorizontalDragUpdate: _handleHorizontalUpdate,
                      onHorizontalDragEnd: _handleHorizontalEnd,
                      onTap: widget.isOpen && !_isInteractionLocked
                          ? widget.onRequestClose
                          : null,
                      child: widget.child,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _SwipeTrayActionButton extends StatelessWidget {
  const _SwipeTrayActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? CupertinoColors.destructiveRed
        : CupertinoColors.label.withValues(alpha: 0.82);

    return Expanded(
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        minimumSize: const Size(42, 42),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
