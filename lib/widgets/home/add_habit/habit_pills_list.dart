import 'package:flutter/material.dart';
import 'package:rutio/l10n/l10n.dart';
import 'habit_pill.dart';

typedef HabitTap = Future<void> Function(
  Map<String, dynamic> habit,
  String name,
  String type,
);

class HabitPillsList extends StatelessWidget {
  const HabitPillsList({
    super.key,
    required this.habits,
    required this.color,
    required this.disabledIds,
    required this.onHabitTap,
  });

  final List<Map<String, dynamic>> habits;
  final Color color;
  final Set<String> disabledIds;
  final HabitTap onHabitTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: habits.asMap().entries.map((e) {
        final i = e.key;
        final h = e.value;

        final id = (h['id'] ?? '').toString();
        final rawName = (h['name'] ?? h['id'] ?? '').toString();
        final name = context.l10n.catalogHabitName(id, fallback: rawName);
        final type = (h['type'] ?? 'check').toString();
        final emoji = _habitEmoji(h);

        final disabled = id.isNotEmpty && disabledIds.contains(id);

        return Opacity(
          opacity: disabled ? 0.35 : 1,
          child: HabitPill(
            key: ValueKey(
                'habit-pill-${(id.isNotEmpty ? id : name).toString()}-$i'),
            label: name,
            emoji: emoji,
            color: color,
            onTap: disabled ? null : () => onHabitTap(h, name, type),
          ),
        );
      }).toList(),
    );
  }

  String _habitEmoji(Map<String, dynamic> habit) {
    final v = habit['emoji'];
    if (v == null) return '➕';
    final s = v.toString().trim();
    return s.isEmpty ? '➕' : s;
  }
}
