import 'package:flutter/widgets.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class TodoTrailingIndicator extends StatelessWidget {
  const TodoTrailingIndicator({
    super.key,
    this.icon,
    this.label,
    this.iconColor = TodoStyleResolver.section,
    this.iconBackground = const Color(0x14B78048),
  });

  final IconData? icon;
  final String? label;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    if (label != null && icon == null) {
      return Text(
        label!,
        style: const TextStyle(
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: TodoStyleResolver.accentSoft,
        ),
      );
    }

    if (icon == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: iconBackground,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 12, color: iconColor),
    );
  }
}
