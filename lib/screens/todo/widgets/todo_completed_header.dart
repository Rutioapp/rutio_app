import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';

class TodoCompletedHeader extends StatelessWidget {
  const TodoCompletedHeader({
    super.key,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final int count;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: Colors.black.withValues(alpha: 0.60),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.homeCompletedCount(count.toString()),
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.72),
                ),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: Colors.black.withValues(alpha: 0.70),
            ),
          ],
        ),
      ),
    );
  }
}
