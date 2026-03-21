import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

class TodoProgressCard extends StatelessWidget {
  const TodoProgressCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final baseStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 13,
      color: Colors.black.withValues(alpha: 0.68),
    );

    final valueStyle = TextStyle(
      fontWeight: FontWeight.w900,
      fontSize: 13,
      color: Colors.black.withValues(alpha: 0.78),
    );

    final totalStyle = TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: Colors.black.withValues(alpha: 0.45),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.homeCompletedLabel, style: baseStyle),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation);

              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              '$completedCount',
              key: ValueKey<int>(completedCount),
              style: valueStyle,
            ),
          ),
          Text('/$totalCount', style: totalStyle),
        ],
      ),
    );
  }
}
