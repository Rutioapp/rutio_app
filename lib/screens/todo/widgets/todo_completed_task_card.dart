import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_date_formatter.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';
import 'package:rutio/screens/todo/widgets/todo_category_chip.dart';
import 'package:rutio/screens/todo/widgets/todo_trailing_indicator.dart';

class TodoCompletedTaskCard extends StatelessWidget {
  const TodoCompletedTaskCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final TodoItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          color: TodoStyleResolver.surface.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TodoStyleResolver.stroke),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(top: 1),
              decoration: const BoxDecoration(
                color: TodoStyleResolver.success,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                CupertinoIcons.check_mark,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: TodoStyleResolver.cardTitleStyle(context).copyWith(
                      color: TodoStyleResolver.textMuted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor:
                          TodoStyleResolver.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Opacity(
                    opacity: 0.82,
                    child: TodoCategoryChip(
                      label: TodoStyleResolver.categoryName(
                        context,
                        item.categoryId,
                      ),
                      categoryId: item.categoryId,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TodoTrailingIndicator(
              label: TodoDateFormatter.completedTimeLabel(context, item),
            ),
          ],
        ),
      ),
    );
  }
}
