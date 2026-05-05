import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/widgets/stats/helpers/stats_number_formatter.dart';

void main() {
  group('StatsNumberFormatter.compact1', () {
    test('shows integers without decimal', () {
      expect(StatsNumberFormatter.compact1(3), '3');
      expect(StatsNumberFormatter.compact1(3.0), '3');
      expect(StatsNumberFormatter.compact1(12.000001), '12.0');
    });

    test('shows at most one decimal for fractions', () {
      expect(StatsNumberFormatter.compact1(3.25), '3.3');
      expect(StatsNumberFormatter.compact1(3.24), '3.2');
      expect(StatsNumberFormatter.compact1(0.04), '0.0');
    });
  });
}
