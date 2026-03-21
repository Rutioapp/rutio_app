import 'package:flutter/material.dart';
import 'package:rutio/utils/family_theme.dart';

/// Premium top toast (Option A: soft glass minimal)
///
/// Usage:
/// showTopToast(context, message: 'Se ha creado "Leer"');
/// showTopToast(context, message: 'Se ha creado "Leer"', familyId: 'mind');
/// showTopToast(context, message: 'Error', variant: TopToastVariant.error);
enum TopToastVariant { success, info, error }

void showTopToast(
  BuildContext context, {
  required String message,
  TopToastVariant variant = TopToastVariant.success,
  Duration duration = const Duration(seconds: 2),
  IconData? icon,
  String? familyId,
  Color? accentColor,
  Color? backgroundColor,
}) {
  final overlay = Overlay.of(context);

  final key = GlobalKey<_TopToastState>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (overlayContext) {
      return _TopToast(
        key: key,
        message: message,
        variant: variant,
        icon: icon,
        familyId: familyId,
        accentColor: accentColor,
        backgroundColor: backgroundColor,
        onDismissed: () => entry.remove(),
      );
    },
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    // Animate out if still mounted.
    final st = key.currentState;
    if (st != null && st.mounted) {
      st.dismiss();
    } else {
      if (entry.mounted) entry.remove();
    }
  });
}

class _TopToast extends StatefulWidget {
  final String message;
  final TopToastVariant variant;
  final IconData? icon;
  final String? familyId;
  final Color? accentColor;
  final Color? backgroundColor;
  final VoidCallback onDismissed;

  const _TopToast({
    super.key,
    required this.message,
    required this.variant,
    required this.onDismissed,
    this.icon,
    this.familyId,
    this.accentColor,
    this.backgroundColor,
  });

  @override
  State<_TopToast> createState() => _TopToastState();
}

class _TopToastState extends State<_TopToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;

  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (_isDismissing) return;
    _isDismissing = true;

    try {
      await _controller.reverse();
    } finally {
      if (mounted) widget.onDismissed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Option A: soft glass minimal
    final Color resolvedAccent = widget.accentColor ??
        (widget.familyId != null
            ? FamilyTheme.colorOf(widget.familyId)
            : null) ??
        switch (widget.variant) {
          TopToastVariant.success => cs.primary,
          TopToastVariant.info => cs.primary,
          TopToastVariant.error => cs.error,
        };

    final Color resolvedBg = widget.backgroundColor ??
        cs.surface.withValues(
            alpha: theme.brightness == Brightness.dark ? 0.92 : 0.96);

    final IconData resolvedIcon = widget.icon ??
        switch (widget.variant) {
          TopToastVariant.success => Icons.check_circle_rounded,
          TopToastVariant.info => Icons.info_rounded,
          TopToastVariant.error => Icons.error_rounded,
        };

    final textStyle = theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w500,
        ) ??
        TextStyle(color: cs.onSurface, fontWeight: FontWeight.w500);

    return Positioned(
      top: topPadding + 12,
      left: 14,
      right: 14,
      child: SafeArea(
        top: false,
        bottom: false,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: _SwipeToDismiss(
              onDismiss: dismiss,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: resolvedBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: resolvedAccent.withValues(alpha: 0.22),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha:
                              theme.brightness == Brightness.dark ? 0.35 : 0.10,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: resolvedAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          resolvedIcon,
                          size: 20,
                          color: resolvedAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.message,
                          style: textStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: dismiss,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: cs.onSurface.withValues(alpha: 0.55),
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
      ),
    );
  }
}

/// Small helper to allow swipe-up dismissal without extra dependencies.
class _SwipeToDismiss extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onDismiss;

  const _SwipeToDismiss({
    required this.child,
    required this.onDismiss,
  });

  @override
  State<_SwipeToDismiss> createState() => _SwipeToDismissState();
}

class _SwipeToDismissState extends State<_SwipeToDismiss> {
  double _dy = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (d) {
        setState(() => _dy += d.delta.dy);
      },
      onVerticalDragEnd: (d) async {
        // Only dismiss if swiped up a bit.
        if (_dy < -18) {
          await widget.onDismiss();
        }
        setState(() => _dy = 0);
      },
      onVerticalDragCancel: () => setState(() => _dy = 0),
      child: widget.child,
    );
  }
}
