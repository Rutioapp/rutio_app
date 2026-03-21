import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// Heatmap mensual en rejilla 10 columnas x 3 filas (30 celdas) + soporte para día 31.
///
/// - Cada celda es un cuadrado con border-radius 6.
/// - Intensidad 0 => gris claro.
/// - Intensidad >0 => color acento con opacidad según intensidad + sombra.
/// - Hover (web/desktop): escala a 1.2.
/// - Leyenda: 3 celdas con intensidad creciente + etiquetas "Menos"/"Más".
///
/// intensityByDay: día del mes (1..31) -> intensidad 0..1
class StatsMonthHeatmap extends StatelessWidget {
  const StatsMonthHeatmap({
    super.key,
    required this.month,
    required this.accent,
    required this.intensityByDay,
    this.columns = 10,
    this.cellSize = 18,
    this.gap = 8,
    this.radius = 6,
  });

  final DateTime month;
  final Color accent;
  final Map<int, double> intensityByDay;

  final int columns;
  final double cellSize;
  final double gap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = _daysInMonth(month);
    final showDay31 = daysInMonth == 31;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Queremos 10 columnas ocupando TODO el ancho disponible.
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (columns * cellSize) + ((columns - 1) * gap);

        final resolvedCellSize =
            ((maxW - ((columns - 1) * gap)) / columns).clamp(10.0, 40.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeatmapGrid(
              daysInMonth: math.min(daysInMonth, 30), // dentro del grid 10x3
              columns: columns,
              rows: 3,
              cellSize: resolvedCellSize,
              gap: gap,
              radius: radius,
              accent: accent,
              intensityByDay: intensityByDay,
            ),
            if (showDay31) ...[
              SizedBox(height: gap),
              // Día 31: SOLO una celda extra, alineada con el inicio del grid.
              _HeatmapDay31Row(
                day: 31,
                columns: columns,
                cellSize: resolvedCellSize,
                gap: gap,
                radius: radius,
                accent: accent,
                intensity: _clamp01(intensityByDay[31] ?? 0),
              ),
            ],
            SizedBox(height: gap),
            _Legend(accent: accent, cellSize: resolvedCellSize, radius: radius),
          ],
        );
      },
    );
  }

  int _daysInMonth(DateTime m) {
    // Calculates days in the given month (28/29/30/31) even if 'm' isn't day 1.
    final year = m.year;
    final month = m.month;

    final firstDayNextMonth =
        (month < 12) ? DateTime(year, month + 1, 1) : DateTime(year + 1, 1, 1);

    return firstDayNextMonth.subtract(const Duration(days: 1)).day;
  }

  static double _clamp01(double v) => v.clamp(0.0, 1.0);
}

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.daysInMonth,
    required this.columns,
    required this.rows,
    required this.cellSize,
    required this.gap,
    required this.radius,
    required this.accent,
    required this.intensityByDay,
  });

  /// Días reales que existen dentro del mes (28/29/30) que se pintan en el grid 10x3.
  /// El resto de celdas (hasta 30) se muestran como vacías.
  final int daysInMonth;
  final int columns;
  final int rows;
  final double cellSize;
  final double gap;
  final double radius;
  final Color accent;
  final Map<int, double> intensityByDay;

  @override
  Widget build(BuildContext context) {
    final totalCells = columns * rows; // 30

    return GridView.builder(
      padding: EdgeInsets.zero,
      primary: false,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, i) {
        final day = i + 1;
        if (day > daysInMonth) {
          return _EmptyCell(size: cellSize, radius: radius);
        }
        final intensity = (intensityByDay[day] ?? 0).clamp(0.0, 1.0);
        return _HeatCell(
          day: day,
          size: cellSize,
          radius: radius,
          accent: accent,
          intensity: intensity,
        );
      },
    );
  }
}

class _HeatmapDay31Row extends StatelessWidget {
  const _HeatmapDay31Row({
    required this.day,
    required this.columns,
    required this.cellSize,
    required this.gap,
    required this.radius,
    required this.accent,
    required this.intensity,
  });

  final int day;
  final int columns;
  final double cellSize;
  final double gap;
  final double radius;
  final Color accent;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    // Solo una celda (sin "fila fantasma"). Queda alineada con la primera columna del grid.
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: cellSize,
        height: cellSize,
        child: _HeatCell(
          day: day,
          size: cellSize,
          radius: radius,
          accent: accent,
          intensity: intensity,
        ),
      ),
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _HeatCell extends StatefulWidget {
  const _HeatCell({
    required this.day,
    required this.size,
    required this.radius,
    required this.accent,
    required this.intensity,
  });

  final int day;
  final double size;
  final double radius;
  final Color accent;
  final double intensity;

  @override
  State<_HeatCell> createState() => _HeatCellState();
}

class _HeatCellState extends State<_HeatCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final isDone = widget.intensity > 0;
    final bg = isDone
        ? widget.accent.withValues(alpha: _alphaForIntensity(widget.intensity))
        : const Color(0xFFEDEDED);

    final shadows = isDone
        ? [
            BoxShadow(
              color: widget.accent.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ]
        : const <BoxShadow>[];

    final cell = AnimatedScale(
      scale: _hover ? 1.2 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: shadows,
        ),
      ),
    );

    if (kIsWeb) {
      return Tooltip(
        message: context.l10n.habitStatsDayTooltip(widget.day),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: cell,
        ),
      );
    }

    return Tooltip(
      message: context.l10n.habitStatsDayTooltip(widget.day),
      child: cell,
    );
  }

  double _alphaForIntensity(double x) {
    // 0..1 -> 0.45..1.0 (más agradable visualmente)
    return (0.45 + (0.55 * x)).clamp(0.0, 1.0);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.accent,
    required this.cellSize,
    required this.radius,
  });

  final Color accent;
  final double cellSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    Widget cell(double intensity) {
      final bg =
          accent.withValues(alpha: (0.45 + 0.55 * intensity).clamp(0.0, 1.0));
      return Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Row(
      children: [
        Text(
          context.l10n.habitStatsLegendLess,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B8B8B),
          ),
        ),
        const SizedBox(width: 10),
        cell(0.25),
        const SizedBox(width: 6),
        cell(0.55),
        const SizedBox(width: 6),
        cell(1.0),
        const SizedBox(width: 10),
        Text(
          context.l10n.habitStatsLegendMore,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF8B8B8B),
          ),
        ),
      ],
    );
  }
}
