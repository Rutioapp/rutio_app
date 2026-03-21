import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_type.dart';

class CreateTodoSegmentedToggle extends StatelessWidget {
  const CreateTodoSegmentedToggle({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  final TodoType selectedType;
  final ValueChanged<TodoType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    Widget segment(TodoType type) {
      final isSelected = type == selectedType;
      return Expanded(
        child: GestureDetector(
          onTap: () => onSelected(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? TodoStyleResolver.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              TodoStyleResolver.typeLabel(l10n, type),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : TodoStyleResolver.accentSoft,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0E7DA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          segment(TodoType.free),
          segment(TodoType.linkedHabit),
        ],
      ),
    );
  }
}
