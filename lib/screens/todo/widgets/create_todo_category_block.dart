import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/widgets/todo_section_label.dart';

class CreateTodoCategoryBlock extends StatelessWidget {
  const CreateTodoCategoryBlock({
    super.key,
    required this.sectionLabel,
    required this.selectedCategoryId,
    required this.onSelected,
  });

  final String sectionLabel;
  final String selectedCategoryId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TodoSectionLabel(label: sectionLabel),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: TodoStyleResolver.categoryIds.map((categoryId) {
              final isSelected = categoryId == selectedCategoryId;
              final color = TodoStyleResolver.categoryColor(categoryId);
              return GestureDetector(
                onTap: () => onSelected(categoryId),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TodoStyleResolver.categoryBackground(categoryId)
                        : TodoStyleResolver.neutralChip,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        TodoStyleResolver.categoryName(context, categoryId),
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
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
