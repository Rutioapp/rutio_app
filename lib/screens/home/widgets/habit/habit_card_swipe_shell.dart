import 'package:flutter/cupertino.dart';

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

  static const double _actionWidth = 78;
  static const double _openThresholdRatio = 0.30;
  static const double _rightVisualLimit = 84;
  static const double _rightCompleteThreshold = 54;
  static const double _rightFlingMinOffset = 26;
  static const double _rightFlingVelocity = 520;

  @override
  State<HabitCardSwipeShell> createState() => _HabitCardSwipeShellState();
}

class _HabitCardSwipeShellState extends State<HabitCardSwipeShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _offsetAnimation;

  double _offset = 0;
  bool _isDragging = false;
  bool _startedFromOpenTray = false;

  double get _revealWidth => HabitCardSwipeShell._actionWidth * 3;
  double get _openOffset => -_revealWidth;

  @override
  void initState() {
    super.initState();
    _offset = widget.isOpen ? _openOffset : 0;
    _offsetAnimation = AlwaysStoppedAnimation<double>(_offset);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() {
          _offset = _offsetAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(covariant HabitCardSwipeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDragging) return;

    if (oldWidget.isOpen != widget.isOpen) {
      _animateTo(widget.isOpen ? _openOffset : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final clampedTarget =
        target.clamp(_openOffset, HabitCardSwipeShell._rightVisualLimit);
    if ((_offset - clampedTarget).abs() < 0.5) {
      setState(() => _offset = clampedTarget);
      return;
    }

    _controller.stop();
    _offsetAnimation = Tween<double>(
      begin: _offset,
      end: clampedTarget,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller
      ..value = 0
      ..forward();
  }

  Future<void> _handleAction(Future<void> Function() callback) async {
    widget.onRequestClose();
    await callback();
  }

  void _handleHorizontalStart(DragStartDetails details) {
    _isDragging = true;
    _startedFromOpenTray = widget.isOpen || _offset < -0.5;
    widget.onRequestCloseOtherCards(widget.cardId);
    _controller.stop();
  }

  void _handleHorizontalUpdate(DragUpdateDetails details) {
    final dx = details.delta.dx;
    if (dx == 0) return;

    if (dx > 0) {
      if (_offset < 0) {
        final nextOffset = (_offset + dx).clamp(_openOffset, 0.0);
        if (nextOffset == _offset) return;
        setState(() {
          _offset = nextOffset;
        });
        return;
      }

      if (!widget.canSwipeRightComplete ||
          widget.onSwipeRightComplete == null) {
        return;
      }

      final dragFactor =
          _offset > (HabitCardSwipeShell._rightVisualLimit * 0.55)
              ? 0.42
              : 0.72;
      final nextOffset = (_offset + (dx * dragFactor))
          .clamp(0.0, HabitCardSwipeShell._rightVisualLimit);
      if (nextOffset == _offset) return;
      setState(() {
        _offset = nextOffset;
      });
      return;
    }

    final nextOffset = (_offset + dx).clamp(_openOffset, 0.0);
    if (nextOffset == _offset) return;

    setState(() {
      _offset = nextOffset;
      if (_offset < -2 && !widget.isOpen) {
        widget.onRequestOpen(widget.cardId);
      }
    });
  }

  Future<void> _handleHorizontalEnd(DragEndDetails details) async {
    _isDragging = false;
    final rightVelocity = details.velocity.pixelsPerSecond.dx;
    final canCompleteFromSwipe = !_startedFromOpenTray &&
        widget.canSwipeRightComplete &&
        widget.onSwipeRightComplete != null;
    final passedRightThreshold =
        _offset >= HabitCardSwipeShell._rightCompleteThreshold;
    final flingRight =
        rightVelocity >= HabitCardSwipeShell._rightFlingVelocity &&
            _offset >= HabitCardSwipeShell._rightFlingMinOffset;

    if (canCompleteFromSwipe && (passedRightThreshold || flingRight)) {
      _startedFromOpenTray = false;
      _animateTo(0);
      await widget.onSwipeRightComplete!.call();
      return;
    }
    _startedFromOpenTray = false;

    if (_offset > 0) {
      _animateTo(0);
      return;
    }

    final openThreshold =
        _revealWidth * HabitCardSwipeShell._openThresholdRatio;
    final shouldOpen = _offset.abs() >= openThreshold ||
        details.velocity.pixelsPerSecond.dx < -320;

    if (shouldOpen) {
      widget.onRequestOpen(widget.cardId);
      _animateTo(_openOffset);
      return;
    }

    widget.onRequestClose();
    _animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final revealWidth = _revealWidth;
    final verticalInset = widget.compact ? 6.0 : 8.0;
    final radius = widget.compact ? 18.0 : 20.0;
    final revealProgress =
        ((_offset < 0 ? _offset.abs() : 0.0) / revealWidth).clamp(0.0, 1.0);
    final showTray = revealProgress > 0.001;
    final rightProgress =
        (_offset / HabitCardSwipeShell._rightVisualLimit).clamp(0.0, 1.0);
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
                        onTap: () => _handleAction(widget.onSkip),
                      ),
                      _SwipeTrayActionButton(
                        icon: CupertinoIcons.pencil,
                        label: widget.editLabel,
                        onTap: widget.onEdit == null
                            ? null
                            : () {
                                widget.onRequestClose();
                                widget.onEdit!.call();
                              },
                      ),
                      _SwipeTrayActionButton(
                        icon: CupertinoIcons.delete,
                        label: widget.deleteLabel,
                        isDestructive: true,
                        onTap: () => _handleAction(widget.onDelete),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(_offset, 0, 0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _handleHorizontalStart,
            onHorizontalDragUpdate: _handleHorizontalUpdate,
            onHorizontalDragEnd: _handleHorizontalEnd,
            onTap: widget.isOpen ? widget.onRequestClose : null,
            child: widget.child,
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
