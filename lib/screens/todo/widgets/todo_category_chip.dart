import 'package:flutter/widgets.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class TodoCategoryChip extends StatelessWidget {
  const TodoCategoryChip({
    super.key,
    required this.label,
    required this.categoryId,
  });

  final String label;
  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final color = TodoStyleResolver.categoryColor(categoryId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TodoStyleResolver.categoryBackground(categoryId),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
