import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_priority.dart';
import 'package:rutio/screens/todo/widgets/todo_section_label.dart';

class CreateTodoPriorityBlock extends StatelessWidget {
  const CreateTodoPriorityBlock({
    super.key,
    required this.sectionLabel,
    required this.selectedPriority,
    required this.onSelected,
  });

  final String sectionLabel;
  final TodoPriority selectedPriority;
  final ValueChanged<TodoPriority> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final priorities = TodoPriority.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TodoSectionLabel(label: sectionLabel),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: priorities.map((priority) {
              final isSelected = priority == selectedPriority;
              final foreground = TodoStyleResolver.priorityColor(priority);
              final background = isSelected
                  ? TodoStyleResolver.priorityBackground(priority)
                  : TodoStyleResolver.neutralChip;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(priority),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? foreground : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      TodoStyleResolver.priorityLabel(l10n, priority),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: foreground,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
