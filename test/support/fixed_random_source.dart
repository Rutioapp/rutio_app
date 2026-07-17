import 'package:rutio/features/shop/domain/random_source.dart';

class FixedRandomSource implements RandomSource {
  FixedRandomSource(this.values);

  final List<int> values;
  int _index = 0;

  @override
  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max');
    }
    if (values.isEmpty) {
      return 0;
    }
    final value = values[_index % values.length] % max;
    _index += 1;
    return value;
  }
}
