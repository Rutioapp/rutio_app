import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/widgets/stats/helpers/stats_motivation_engine.dart';

void main() {
  group('StatsMotivationEngine.pick', () {
    test('returns a deterministic tone and bounded variant', () {
      final input = const StatsMotivationInput(
        streakDays: 9,
        thisWeekDoneDays: 5,
        lastWeekDoneDays: 3,
        hasBestTime: true,
        compliancePct: 74,
      );

      final first = StatsMotivationEngine.pick(input);
      final second = StatsMotivationEngine.pick(input);

      expect(first.tone, second.tone);
      expect(first.variant, second.variant);
      expect(first.variant, inInclusiveRange(0, 2));
    });

    test('falls back to neutral when there are no strong signals', () {
      const input = StatsMotivationInput(
        streakDays: 0,
        thisWeekDoneDays: 0,
        lastWeekDoneDays: 0,
        hasBestTime: false,
        compliancePct: 0,
      );

      final pick = StatsMotivationEngine.pick(input);
      expect(pick.tone, StatsMotivationTone.neutral);
    });
  });
}
