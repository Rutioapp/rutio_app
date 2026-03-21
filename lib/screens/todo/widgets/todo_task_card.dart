import 'package:flutter/cupertino.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_date_formatter.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';
import 'package:rutio/screens/todo/models/todo_priority.dart';
import 'package:rutio/screens/todo/widgets/todo_category_chip.dart';
import 'package:rutio/screens/todo/widgets/todo_status_chip.dart';
import 'package:rutio/screens/todo/widgets/todo_trailing_indicator.dart';

class TodoTaskCard extends StatelessWidget {
  const TodoTaskCard({
    super.key,
    required this.item,
    required this.now,
    required this.onToggleCompleted,
    this.onTap,
  });

  final TodoItem item;
  final DateTime now;
  final VoidCallback onToggleCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final statusLabel = TodoDateFormatter.statusLabel(context, item, now);
    final isOverdue = TodoDateFormatter.isOverdue(item, now);
    final trailingIcon = item.dueDate == null
        ? CupertinoIcons.exclamationmark_circle
        : CupertinoIcons.clock;
    final trailingColor = item.dueDate == null
        ? TodoStyleResolver.warning
        : TodoStyleResolver.section;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
        decoration: BoxDecoration(
          color: TodoStyleResolver.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TodoStyleResolver.stroke),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: TodoStyleResolver.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            GestureDetector(
              onTap: onToggleCompleted,
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD5C5B4),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: TodoStyleResolver.cardTitleStyle(context),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      TodoCategoryChip(
                        label: TodoStyleResolver.categoryName(
                          context,
                          item.categoryId,
                        ),
                        categoryId: item.categoryId,
                      ),
                      if (statusLabel != null)
                        TodoStatusChip(
                          label: statusLabel,
                          foreground: isOverdue
                              ? TodoStyleResolver.warning
                              : TodoStyleResolver.neutralChipText,
                          background: isOverdue
                              ? TodoStyleResolver.warningSoft
                              : TodoStyleResolver.neutralChip,
                          icon: isOverdue
                              ? CupertinoIcons.exclamationmark_triangle_fill
                              : null,
                        ),
                      if (item.priority != TodoPriority.none)
                        TodoStatusChip(
                          label: TodoStyleResolver.priorityBadgeLabel(
                            l10n,
                            item.priority,
                          ),
                          foreground: TodoStyleResolver.priorityColor(
                            item.priority,
                          ),
                          background: TodoStyleResolver.priorityBackground(
                            item.priority,
                          ),
                          icon: item.priority == TodoPriority.urgent ||
                                  item.priority == TodoPriority.high
                              ? CupertinoIcons.exclamationmark
                              : null,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: TodoTrailingIndicator(
                icon: trailingIcon,
                iconColor: trailingColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
