class StatsNumberFormatter {
  const StatsNumberFormatter._();

  static String compact1(num value) {
    if (value.isNaN || value.isInfinite) return '0';

    final roundedInt = value.roundToDouble();
    if ((value - roundedInt).abs() < 0.0000001) {
      return roundedInt.toInt().toString();
    }

    return value.toStringAsFixed(1);
  }
}
