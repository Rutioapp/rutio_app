/// FamilyChip muestra una etiqueta corta para la familia de un hábito.
///
/// Admite modo compacto y color opcional para reutilizarse tanto en cards como
/// en cabeceras o resúmenes sin duplicar estilos.
library;

import 'package:flutter/material.dart';

class FamilyChip extends StatelessWidget {
  const FamilyChip({
    super.key,
    required this.text,
    this.backgroundColor,
    this.compact = false,
  });

  final String text;
  final Color? backgroundColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor;
    if (bg == null) {
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style:
            const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}
