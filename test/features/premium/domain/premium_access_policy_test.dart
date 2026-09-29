import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/domain/premium_access.dart';
import 'package:rutio/features/premium/domain/premium_access_policy.dart';

void main() {
  final features = PremiumFeature.values;

  test('free, unknown and expired users cannot access Premium features', () {
    for (final state in [
      const PremiumAccessState.free(),
      const PremiumAccessState.unknown(),
      const PremiumAccessState(
        status: PremiumAccessStatus.expired,
        isPremium: false,
      ),
    ]) {
      for (final feature in features) {
        expect(PremiumAccessPolicy.canAccess(feature, state), isFalse);
      }
    }
  });

  test('premium and trial users can access every Premium feature', () {
    for (final state in [
      const PremiumAccessState(
        status: PremiumAccessStatus.premium,
        isPremium: true,
      ),
      const PremiumAccessState(
        status: PremiumAccessStatus.trial,
        isPremium: true,
      ),
    ]) {
      for (final feature in features) {
        expect(PremiumAccessPolicy.canAccess(feature, state), isTrue);
      }
    }
  });
}
