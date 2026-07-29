import 'package:flutter/cupertino.dart';

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
    this.actionWidth = 78,
    this.openThresholdRatio = 0.30,
    this.rightVisualLimit = 84,
    this.rightCompleteThreshold = 54,
    this.rightFlingMinOffset = 26,
    this.rightFlingVelocity = 520,
    this.leftFlingVelocity = -320,
    this.overscrollResistance = 0.28,
    this.maxOverscroll = 36,
    this.settleDuration = const Duration(milliseconds: 220),
    this.settleCurve = Curves.easeOutCubic,
  });

  final double actionWidth;
  final double openThresholdRatio;
  final double rightVisualLimit;
  final double rightCompleteThreshold;
  final double rightFlingMinOffset;
  final double rightFlingVelocity;
  final double leftFlingVelocity;
  final double overscrollResistance;
  final double maxOverscroll;
  final Duration settleDuration;
  final Curve settleCurve;

  double get revealWidth => actionWidth * 3;
  double get openOffset => -revealWidth;
  double get leftOpenThreshold => revealWidth * openThresholdRatio;

  double applyDragDelta({
    required double currentOffset,
    required double delta,
    required bool canSwipeRightComplete,
  }) {
    return applyBounds(
      currentOffset + delta,
      canSwipeRightComplete: canSwipeRightComplete,
    );
  }

  double applyBounds(
    double rawOffset, {
    required bool canSwipeRightComplete,
  }) {
    final rightLimit = canSwipeRightComplete ? rightVisualLimit : 0.0;
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

  HabitCardSwipeSettleTarget resolveSettleTarget({
    required double offset,
    required double velocityX,
    required bool startedFromOpenTray,
    required bool canSwipeRightComplete,
    required bool hasRightCompleteCallback,
  }) {
    final canCompleteFromSwipe = !startedFromOpenTray &&
        canSwipeRightComplete &&
        hasRightCompleteCallback;
    final passedRightThreshold = offset >= rightCompleteThreshold;
    final flingRight =
        velocityX >= rightFlingVelocity && offset >= rightFlingMinOffset;

    if (canCompleteFromSwipe && (passedRightThreshold || flingRight)) {
      return HabitCardSwipeSettleTarget.rightCommit;
    }

    if (offset > 0) {
      return HabitCardSwipeSettleTarget.closed;
    }

    final shouldOpen =
        offset.abs() >= leftOpenThreshold || velocityX < leftFlingVelocity;
    if (shouldOpen) {
      return HabitCardSwipeSettleTarget.leftOpen;
    }

    return HabitCardSwipeSettleTarget.closed;
  }

  double progressForOffset(double offset, double targetExtent) {
    if (targetExtent <= 0) return 0;
    return (offset / targetExtent).clamp(0.0, 1.0);
  }

  double _resistedOverscroll(double excess) {
    return (excess * overscrollResistance).clamp(0.0, maxOverscroll);
  }
}

@visibleForTesting
enum HabitCardSwipeSettleTarget {
  closed,
  leftOpen,
  rightCommit,
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
  late Animation<double> _offsetAnimation;

  double _offset = 0;
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
    _offsetAnimation = AlwaysStoppedAnimation<double>(_offset);
    _controller = AnimationController(
      vsync: this,
      duration: _config.settleDuration,
    )..addListener(() {
        setState(() {
          _offset = _offsetAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(covariant HabitCardSwipeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motionConfig.settleDuration != _config.settleDuration) {
      _controller.duration = _config.settleDuration;
    }
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
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settleTo(double target, HabitCardSwipeVisualState settlingState) {
    final clampedTarget =
        target.clamp(_config.openOffset, _config.rightVisualLimit);
    if ((_offset - clampedTarget).abs() < 0.5) {
      setState(() {
        _offset = clampedTarget;
        if (settlingState != HabitCardSwipeVisualState.committingRight) {
          _visualState = HabitCardSwipeVisualState.idle;
        }
      });
      return;
    }

    _controller.stop();
    _offsetAnimation = Tween<double>(
      begin: _offset,
      end: clampedTarget,
    ).animate(CurvedAnimation(parent: _controller, curve: _config.settleCurve));
    setState(() => _visualState = settlingState);
    _controller
      ..value = 0
      ..forward().whenComplete(() {
        if (!mounted || _visualState != settlingState) return;
        if (settlingState == HabitCardSwipeVisualState.committingRight) {
          return;
        }
        setState(() => _visualState = HabitCardSwipeVisualState.idle);
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
    if (_controller.isAnimating) {
      _offset = _offsetAnimation.value;
    }
    _visualState = HabitCardSwipeVisualState.dragging;
    _startedFromOpenTray = widget.isOpen || _offset < -0.5;
    widget.onRequestCloseOtherCards(widget.cardId);
    _controller.stop();
  }

  void _handleHorizontalUpdate(DragUpdateDetails details) {
    if (_visualState != HabitCardSwipeVisualState.dragging) return;
    final dx = details.delta.dx;
    if (dx == 0) return;

    final nextOffset = _config.applyDragDelta(
      currentOffset: _offset,
      delta: dx,
      canSwipeRightComplete:
          widget.canSwipeRightComplete && widget.onSwipeRightComplete != null,
    );
    if (nextOffset == _offset) return;

    setState(() {
      _offset = nextOffset;
      if (_offset < -2 && !widget.isOpen) {
        widget.onRequestOpen(widget.cardId);
      }
    });
  }

  Future<void> _handleHorizontalEnd(DragEndDetails details) async {
    if (_visualState != HabitCardSwipeVisualState.dragging) return;
    final rightVelocity = details.velocity.pixelsPerSecond.dx;
    final target = _config.resolveSettleTarget(
      offset: _offset,
      velocityX: rightVelocity,
      startedFromOpenTray: _startedFromOpenTray,
      canSwipeRightComplete: widget.canSwipeRightComplete,
      hasRightCompleteCallback: widget.onSwipeRightComplete != null,
    );
    _startedFromOpenTray = false;

    if (target == HabitCardSwipeSettleTarget.rightCommit) {
      await _commitRight();
      return;
    }

    if (target == HabitCardSwipeSettleTarget.leftOpen) {
      widget.onRequestOpen(widget.cardId);
      _settleTo(
        _config.openOffset,
        HabitCardSwipeVisualState.settlingLeftOpen,
      );
      return;
    }

    widget.onRequestClose();
    _settleTo(0, HabitCardSwipeVisualState.settlingClosed);
  }

  Future<void> _commitRight() async {
    if (_isInteractionLocked || widget.onSwipeRightComplete == null) return;
    setState(() => _visualState = HabitCardSwipeVisualState.committingRight);
    _settleTo(0, HabitCardSwipeVisualState.committingRight);
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
    final revealProgress = _config.progressForOffset(
      _offset < 0 ? _offset.abs() : 0.0,
      revealWidth,
    );
    final showTray = revealProgress > 0.001;
    final rightProgress = _config.progressForOffset(
      _offset,
      _config.rightVisualLimit,
    );
    final showRightCue = widget.canSwipeRightComplete && rightProgress > 0.001;

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
                    color: CupertinoColors.systemGreen
                        .withValues(alpha: 0.34 + (0.22 * rightProgress)),
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
                color: CupertinoColors.systemGrey6.withValues(alpha: 0.95),
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
                        onTap: widget.onEdit == null || _isInteractionLocked
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
            offset: Offset(_offset, 0),
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
