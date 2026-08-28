import 'dart:math';

abstract class NotificationRandomSource {
  double nextDouble();
}

class SeededNotificationRandomSource implements NotificationRandomSource {
  SeededNotificationRandomSource(int seed) : _random = Random(seed);

  final Random _random;

  @override
  double nextDouble() => _random.nextDouble();
}

class FixedNotificationRandomSource implements NotificationRandomSource {
  FixedNotificationRandomSource(Iterable<double> values)
      : _values = List<double>.unmodifiable(values) {
    if (_values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'values cannot be empty.');
    }
  }

  final List<double> _values;
  int _index = 0;

  @override
  double nextDouble() {
    final value = _values[_index % _values.length];
    _index += 1;
    return value.clamp(0.0, 0.999999999999).toDouble();
  }
}
