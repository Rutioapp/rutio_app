import 'package:flutter/material.dart';

/// (DEPRECATED)
/// Menú de los tres puntos para una Habit Card.
///
/// Nuevo UX:
/// - Los 3 puntos desaparecen.
/// - Para editar/ver estadísticas se toca la card (y se abre un selector).
///
/// Mantenemos este widget para no romper imports/compilación en archivos antiguos.
/// Si todavía lo tienes en tu Home, simplemente dejará de renderizar nada.
class HabitCardMoreMenu extends StatelessWidget {
  const HabitCardMoreMenu({
    super.key,
    required this.habitId,
    this.iconColor,
    this.iconSize = 22,
    this.onEditHabit,
    this.onViewStats,
    this.onOpenDetailTab,
  });

  final String habitId;

  final Color? iconColor;
  final double iconSize;

  final VoidCallback? onEditHabit;
  final VoidCallback? onViewStats;

  /// tabIndex: 0=Editar, 1=Estadísticas
  final void Function(BuildContext context, int tabIndex)? onOpenDetailTab;

  @override
  Widget build(BuildContext context) {
    // No renderizamos nada por el cambio de UX.
    return const SizedBox.shrink();
  }
}
