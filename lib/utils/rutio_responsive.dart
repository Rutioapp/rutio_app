import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// RutioResponsive
/// - Diseñado "iOS first" (baseline: iPhone 13/14: 390×844)
/// - Usa escalado independiente para ancho/alto + un "scale" uniforme para radios/texto.
///
/// Uso rápido:
///   final w = R.w(context, 120);
///   final h = R.h(context, 24);
///   final r = R.r(context, 20);
///   final sp = R.sp(context, 16);
///
/// Tips:
/// - Para posiciones verticales (top/bottom), usa R.h.
/// - Para posiciones horizontales (left/right), usa R.w.
/// - Para tamaños “cuadrados” (iconos, radios, blur), usa R.r.
/// - Para texto, usa R.sp.
class R {
  R._();

  /// Baseline iOS (Figma) recomendado.
  static const Size designSize = Size(390, 844);

  static Size screen(BuildContext context) => MediaQuery.sizeOf(context);

  static double _scaleW(BuildContext context) =>
      screen(context).width / designSize.width;

  static double _scaleH(BuildContext context) =>
      screen(context).height / designSize.height;

  /// Escala uniforme (para radios / blur / iconos).
  static double scale(BuildContext context) {
    final sw = _scaleW(context);
    final sh = _scaleH(context);
    return math.min(sw, sh);
  }

  /// Escala en ancho (x).
  static double w(BuildContext context, double value) =>
      value * _scaleW(context);

  /// Escala en alto (y).
  static double h(BuildContext context, double value) =>
      value * _scaleH(context);

  /// Escala uniforme (radios, sombras, iconos, etc.)
  static double r(BuildContext context, double value) =>
      value * scale(context);

  /// Escala para tipografía.
  /// Por defecto usa la escala uniforme. Si quieres respetar accesibilidad,
  /// usa Theme.of(context).textTheme + MediaQuery.textScalerOf(context).
  static double sp(BuildContext context, double fontSize) =>
      fontSize * scale(context);

  /// Helpers para EdgeInsets
  static EdgeInsets all(BuildContext context, double v) =>
      EdgeInsets.all(r(context, v));

  static EdgeInsets only(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: w(context, left),
        top: h(context, top),
        right: w(context, right),
        bottom: h(context, bottom),
      );

  static EdgeInsets sym(
    BuildContext context, {
    double h = 0,
    double v = 0,
  }) =>
      EdgeInsets.symmetric(
        horizontal: w(context, h),
        vertical: R.h(context, v),
      );

  /// Clamp (por si quieres evitar que algo crezca demasiado en iPad)
  static double clamp(double value, {double? min, double? max}) {
    var out = value;
    if (min != null && out < min) out = min;
    if (max != null && out > max) out = max;
    return out;
  }
}

/// Backwards-compatible wrapper so screens can use:
///
/// ```dart
/// final r = RutioResponsive.of(context);
/// r.w(10); r.h(10); r.r(10); r.sp(16);
/// ```
///
/// Internally delegates to [R].
class RutioResponsive {
  final BuildContext context;
  const RutioResponsive._(this.context);

  static RutioResponsive of(BuildContext context) => RutioResponsive._(context);

  double w(double value) => R.w(context, value);
  double h(double value) => R.h(context, value);
  double r(double value) => R.r(context, value);
  double sp(double value) => R.sp(context, value);
}
