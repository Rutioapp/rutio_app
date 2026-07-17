import 'dart:math';

import 'package:rutio/features/shop/domain/random_source.dart';

class DartRandomSource implements RandomSource {
  DartRandomSource({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  int nextInt(int max) {
    return _random.nextInt(max);
  }
}
