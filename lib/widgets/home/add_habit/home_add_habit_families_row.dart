import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'package:rutio/utils/family_theme.dart';

class HomeAddHabitFamiliesRow extends StatelessWidget {
  const HomeAddHabitFamiliesRow({
    super.key,
    required this.familyIds,
    required this.selectedId,
    required this.controller,
    required this.itemKeys,
    required this.onSelected,
  });

  final List<String> familyIds;
  final String selectedId;
  final ScrollController controller;
  final Map<String, GlobalKey> itemKeys;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        controller: controller,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: familyIds.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final id = familyIds[i];
          final selected = id == selectedId;

          final label =
              '${FamilyTheme.emojiOf(id)} ${context.l10n.familyName(id)}';
          final color = FamilyTheme.colorOf(id);

          return ChoiceChip(
            key: itemKeys[id],
            selected: selected,
            showCheckmark: false,
            label: Text(
              label,
              style: TextStyle(
                color: selected ? color : color.withValues(alpha: 0.85),
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            selectedColor: color.withValues(alpha: 0.18),
            backgroundColor: color.withValues(alpha: 0.08),
            side: BorderSide(
              color: color.withValues(alpha: selected ? 0.55 : 0.22),
            ),
            elevation: selected ? 2 : 0,
            pressElevation: 0,
            onSelected: (_) => onSelected(id),
          );
        },
      ),
    );
  }
}
