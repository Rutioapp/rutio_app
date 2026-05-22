import 'dart:math' as math;

import 'package:flutter/material.dart';

class CountLast7DaysAxisTick {
  final num value;
  final double y;

  const CountLast7DaysAxisTick({
    required this.value,
    required this.y,
  });
}

class CountLast7DaysCurveSegment {
  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  const CountLast7DaysCurveSegment({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });
}

class CountLast7DaysChartScale {
  final double yMax;
  final List<num> tickValues;
  final double topPadding;
  final double bottomPadding;
  final double leftGutter;
  final double rightPadding;
  final int fractionDigits;

  static const defaultLeftGutter = 36.0;
  static const defaultRightPadding = 6.0;

  const CountLast7DaysChartScale({
    required this.yMax,
    required this.tickValues,
    this.topPadding = 6,
    this.bottomPadding = 10,
    this.leftGutter = defaultLeftGutter,
    this.rightPadding = defaultRightPadding,
    this.fractionDigits = 0,
  });

  factory CountLast7DaysChartScale.fromDays(List<num> values) {
    var rawMax = 0.0;
    var hasFractionalValue = false;
    for (final value in values) {
      final resolved = value.toDouble();
      if (resolved > rawMax) {
        rawMax = resolved;
      }
      if (!_isWholeNumber(resolved)) {
        hasFractionalValue = true;
      }
    }

    final ticks = _buildTickValues(
      rawMax: rawMax,
      hasFractionalValues: hasFractionalValue,
      maxTicks: 5,
    );
    final yMax = ticks.isEmpty ? 1.0 : ticks.last.toDouble();
    final step = ticks.length >= 2
        ? (ticks[1].toDouble() - ticks[0].toDouble()).abs()
        : yMax;
    final fractionDigits = step > 0 && step < 1 ? 1 : 0;

    return CountLast7DaysChartScale(
      yMax: yMax <= 0 ? 1 : yMax,
      tickValues: ticks,
      fractionDigits: fractionDigits,
    );
  }
}

class CountLast7DaysChartPainter extends CustomPainter {
  final List<Offset> points;
  final CountLast7DaysChartScale scale;
  final Color lineColor;

  const CountLast7DaysChartPainter({
    required this.points,
    required this.scale,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plotHeight = _plotBottom(size.height) - _plotTop;
    if (plotHeight <= 0) return;

    _paintGuideLines(canvas, size);
    if (points.isEmpty) return;

    final plotRect = Rect.fromLTRB(
      _plotLeft,
      _plotTop,
      _plotRight(size.width),
      _plotBottom(size.height),
    );
    final linePath = buildCountLast7DaysMonotonePath(
      points: points,
      minY: plotRect.top,
      maxY: plotRect.bottom,
    );
    final areaPath = Path.from(linePath)
      ..lineTo(points.last.dx, _plotBottom(size.height))
      ..lineTo(points.first.dx, _plotBottom(size.height))
      ..close();

    canvas.save();
    canvas.clipRect(plotRect.inflate(0.4));
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            lineColor.withValues(alpha: 0.27),
            lineColor.withValues(alpha: 0.03),
          ],
        ).createShader(plotRect)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  void _paintGuideLines(Canvas canvas, Size size) {
    final axisTicks = buildCountLast7DaysAxisTicks(
      scale: scale,
      maxHeight: size.height,
    );
    for (final tick in axisTicks) {
      final isBaseline = tick.value == 0;
      final color = isBaseline
          ? const Color(0xFFD8CEC1).withValues(alpha: 0.72)
          : const Color(0xFFE7DFD3).withValues(alpha: 0.58);
      canvas.drawLine(
        Offset(_plotLeft, tick.y),
        Offset(_plotRight(size.width), tick.y),
        Paint()
          ..color = color
          ..strokeWidth = isBaseline ? 1.1 : 0.8,
      );
    }
  }

  double get _plotTop => scale.topPadding;

  double _plotBottom(double maxHeight) => maxHeight - scale.bottomPadding;

  double get _plotLeft => scale.leftGutter;

  double _plotRight(double maxWidth) => maxWidth - scale.rightPadding;

  @override
  bool shouldRepaint(covariant CountLast7DaysChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.scale != scale ||
        oldDelegate.lineColor != lineColor;
  }
}

List<Offset> buildCountLast7DaysChartPoints({
  required List<num> values,
  required double maxWidth,
  required double maxHeight,
  required CountLast7DaysChartScale scale,
}) {
  if (values.isEmpty || maxWidth <= 0 || maxHeight <= 0) return const [];

  final top = scale.topPadding;
  final bottom = maxHeight - scale.bottomPadding;
  final plotLeft = scale.leftGutter;
  final plotRight = maxWidth - scale.rightPadding;
  final plotWidth = plotRight - plotLeft;
  if (plotWidth <= 0) return const [];

  final usableHeight = bottom - top;
  if (usableHeight <= 0) return const [];

  final safeMax = scale.yMax <= 0 ? 1.0 : scale.yMax;
  final slotWidth = plotWidth / values.length;
  final points = <Offset>[];
  for (var index = 0; index < values.length; index += 1) {
    final value = values[index].toDouble().clamp(0, safeMax);
    final ratio = safeMax <= 0 ? 0.0 : (value / safeMax);
    final y = bottom - (ratio * usableHeight);
    final x = plotLeft + (slotWidth * index) + (slotWidth / 2);
    points.add(Offset(x, y));
  }
  return points;
}

List<CountLast7DaysAxisTick> buildCountLast7DaysAxisTicks({
  required CountLast7DaysChartScale scale,
  required double maxHeight,
}) {
  if (maxHeight <= 0 || scale.tickValues.isEmpty) return const [];

  final top = scale.topPadding;
  final bottom = maxHeight - scale.bottomPadding;
  final usableHeight = bottom - top;
  if (usableHeight <= 0) return const [];

  final safeMax = scale.yMax <= 0 ? 1.0 : scale.yMax;
  final ticks = <CountLast7DaysAxisTick>[];
  for (final value in scale.tickValues) {
    final resolved = value.toDouble().clamp(0, safeMax);
    final ratio = safeMax <= 0 ? 0.0 : (resolved / safeMax);
    ticks.add(CountLast7DaysAxisTick(
      value: value,
      y: bottom - (ratio * usableHeight),
    ));
  }
  return ticks;
}

String formatCountLast7DaysAxisLabel(
  num value, {
  required int fractionDigits,
}) {
  return formatChartAxisValue(
    value,
    fractionDigits: fractionDigits,
  );
}

String formatChartAxisValue(
  num value, {
  int fractionDigits = 0,
}) {
  final resolved = value.toDouble();
  final abs = resolved.abs();
  if (abs >= 1000) {
    final inThousands = resolved / 1000;
    final text = _isWholeNumber(inThousands)
        ? inThousands.round().toString()
        : inThousands.toStringAsFixed(1);
    return '${_trimTrailingZero(text)}k';
  }
  if (fractionDigits <= 0 || _isWholeNumber(value.toDouble())) {
    return value.round().toString();
  }
  return value.toStringAsFixed(fractionDigits);
}

Path buildCountLast7DaysMonotonePath({
  required List<Offset> points,
  required double minY,
  required double maxY,
}) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) return path;

  final segments = buildCountLast7DaysMonotoneSegments(
    points: points,
    minY: minY,
    maxY: maxY,
  );
  for (final segment in segments) {
    path.cubicTo(
      segment.control1.dx,
      segment.control1.dy,
      segment.control2.dx,
      segment.control2.dy,
      segment.end.dx,
      segment.end.dy,
    );
  }
  return path;
}

List<CountLast7DaysCurveSegment> buildCountLast7DaysMonotoneSegments({
  required List<Offset> points,
  required double minY,
  required double maxY,
}) {
  if (points.length < 2) return const [];

  final n = points.length;
  final dx = List<double>.filled(n - 1, 0);
  final slope = List<double>.filled(n - 1, 0);
  for (var i = 0; i < n - 1; i += 1) {
    final deltaX = points[i + 1].dx - points[i].dx;
    dx[i] = deltaX <= 0 ? 1 : deltaX;
    slope[i] = (points[i + 1].dy - points[i].dy) / dx[i];
  }

  final tangent = List<double>.filled(n, 0);
  tangent[0] = slope.first;
  tangent[n - 1] = slope.last;

  for (var i = 1; i < n - 1; i += 1) {
    final left = slope[i - 1];
    final right = slope[i];
    if (left == 0 || right == 0 || left.sign != right.sign) {
      tangent[i] = 0;
      continue;
    }
    final w1 = 2 * dx[i] + dx[i - 1];
    final w2 = dx[i] + 2 * dx[i - 1];
    tangent[i] = (w1 + w2) / ((w1 / left) + (w2 / right));
  }

  for (var i = 0; i < n - 1; i += 1) {
    final segmentSlope = slope[i];
    if (segmentSlope == 0) {
      tangent[i] = 0;
      tangent[i + 1] = 0;
      continue;
    }
    var a = tangent[i] / segmentSlope;
    var b = tangent[i + 1] / segmentSlope;
    final h = math.sqrt((a * a) + (b * b));
    if (h > 3) {
      final t = 3 / h;
      a *= t;
      b *= t;
      tangent[i] = a * segmentSlope;
      tangent[i + 1] = b * segmentSlope;
    }
  }

  final segments = <CountLast7DaysCurveSegment>[];
  for (var i = 0; i < n - 1; i += 1) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final segmentMinY = math.min(p0.dy, p1.dy);
    final segmentMaxY = math.max(p0.dy, p1.dy);
    final segmentDx = dx[i];

    final cp1 = Offset(
      p0.dx + (segmentDx / 3),
      _clampDouble(
        p0.dy + ((tangent[i] * segmentDx) / 3),
        math.max(minY, segmentMinY),
        math.min(maxY, segmentMaxY),
      ),
    );
    final cp2 = Offset(
      p1.dx - (segmentDx / 3),
      _clampDouble(
        p1.dy - ((tangent[i + 1] * segmentDx) / 3),
        math.max(minY, segmentMinY),
        math.min(maxY, segmentMaxY),
      ),
    );
    segments.add(CountLast7DaysCurveSegment(
      start: p0,
      control1: cp1,
      control2: cp2,
      end: p1,
    ));
  }
  return segments;
}

List<num> _buildTickValues({
  required double rawMax,
  required bool hasFractionalValues,
  required int maxTicks,
}) {
  if (rawMax <= 0) {
    return const <num>[0, 1];
  }

  var step = _niceCeilStep(
    rawMax / (maxTicks - 1),
    hasFractionalValues: hasFractionalValues,
  );
  if (!hasFractionalValues && step < 1) {
    step = 1;
  }

  var ticks = _generateTicks(rawMax: rawMax, step: step);
  while (ticks.length > maxTicks) {
    step = _nextNiceStep(step, hasFractionalValues: hasFractionalValues);
    ticks = _generateTicks(rawMax: rawMax, step: step);
  }

  if (!hasFractionalValues) {
    return ticks.map((value) => value.round()).toList(growable: false);
  }
  return ticks;
}

List<double> _generateTicks({
  required double rawMax,
  required double step,
}) {
  if (step <= 0) return const <double>[0, 1];
  final maxValue = (rawMax / step).ceilToDouble() * step;
  final totalTicks = (maxValue / step).round() + 1;
  return List<double>.generate(
    totalTicks,
    (index) => _normalizeTick(step * index),
    growable: false,
  );
}

double _niceCeilStep(
  double rawStep, {
  required bool hasFractionalValues,
}) {
  if (rawStep <= 0) return 1;
  final exponent = math.log(rawStep) / math.ln10;
  final magnitude = math.pow(10, exponent.floor()).toDouble();
  final normalized = rawStep / magnitude;
  final candidates = magnitude < 1
      ? const <double>[1, 2, 5, 10]
      : const <double>[1, 2, 2.5, 5, 10];

  for (final candidate in candidates) {
    if (normalized <= candidate) {
      final step = candidate * magnitude;
      if (!hasFractionalValues && step < 1) {
        return 1;
      }
      return step;
    }
  }
  final nextStep = 10 * magnitude;
  if (!hasFractionalValues && nextStep < 1) {
    return 1;
  }
  return nextStep;
}

double _nextNiceStep(
  double step, {
  required bool hasFractionalValues,
}) {
  final exponent = math.log(step) / math.ln10;
  final magnitude = math.pow(10, exponent.floor()).toDouble();
  final normalized = step / magnitude;
  final candidates = magnitude < 1
      ? const <double>[1, 2, 5, 10]
      : const <double>[1, 2, 2.5, 5, 10];

  for (final candidate in candidates) {
    if (normalized < candidate - 1e-9) {
      final next = candidate * magnitude;
      if (!hasFractionalValues && next < 1) {
        return 1;
      }
      return next;
    }
  }
  final nextMagnitude = magnitude * 10;
  if (!hasFractionalValues && nextMagnitude < 1) {
    return 1;
  }
  return nextMagnitude;
}

double _normalizeTick(double value) {
  final rounded = (value * 1000).roundToDouble() / 1000;
  return rounded == -0.0 ? 0 : rounded;
}

double _clampDouble(double value, double min, double max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

String _trimTrailingZero(String text) {
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
}

bool _isWholeNumber(double value) {
  return (value - value.roundToDouble()).abs() < 0.0001;
}
