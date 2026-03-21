import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/models/todo_filter.dart';

class TodoFilterRow extends StatelessWidget {
  const TodoFilterRow({
    super.key,
    required this.selectedFilter,
    required this.onSelected,
  });

  final TodoFilter selectedFilter;
  final ValueChanged<TodoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = TodoFilter.values;
    final l10n = context.l10n;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => onSelected(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? TodoStyleResolver.accent
                    : TodoStyleResolver.surface.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : TodoStyleResolver.stroke,
                ),
              ),
              child: Text(
                TodoStyleResolver.filterLabel(l10n, filter),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      isSelected ? Colors.white : TodoStyleResolver.textPrimary,
                  height: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
