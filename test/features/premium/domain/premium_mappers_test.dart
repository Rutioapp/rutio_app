import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/premium/data/revenuecat/revenuecat_client.dart';
import 'package:rutio/features/premium/domain/premium_access.dart';
import 'package:rutio/features/premium/domain/premium_mappers.dart';

void main() {
  group('premiumAccessStateFromCustomerInfo', () {
    test('maps an active premium entitlement to premium', () {
      final state = premiumAccessStateFromCustomerInfo(
        _customerInfo(
          active: _entitlement(
            productIdentifier: 'rutio_test_premium_monthly',
            isActive: true,
          ),
        ),
      );

      expect(state.status, PremiumAccessStatus.premium);
      expect(state.isPremium, isTrue);
      expect(state.productIdentifier, 'rutio_test_premium_monthly');
      expect(state.willRenew, isTrue);
    });

    test('maps a trial entitlement without inferring it from the product', () {
      final state = premiumAccessStateFromCustomerInfo(
        _customerInfo(
          active: _entitlement(
            productIdentifier: 'rutio_test_premium_monthly',
            isActive: true,
            isTrial: true,
          ),
        ),
      );

      expect(state.status, PremiumAccessStatus.trial);
      expect(state.isPremium, isTrue);
    });

    test('maps an absent entitlement to free', () {
      final state = premiumAccessStateFromCustomerInfo(
        const RevenueCatCustomerInfoSnapshot(
          activeEntitlements: {},
          allEntitlements: {},
        ),
      );

      expect(state.status, PremiumAccessStatus.free);
      expect(state.isPremium, isFalse);
    });

    test('maps an expired inactive entitlement to expired', () {
      final expiration = DateTime(2026, 1, 1);
      final state = premiumAccessStateFromCustomerInfo(
        _customerInfo(
          all: _entitlement(
            productIdentifier: 'rutio_test_premium_annual',
            isActive: false,
            expirationDate: expiration,
          ),
        ),
        now: DateTime(2026, 2, 1),
      );

      expect(state.status, PremiumAccessStatus.expired);
      expect(state.isPremium, isFalse);
      expect(state.expirationDate, expiration);
    });
  });

  group('premiumOfferingFromSnapshot', () {
    test('maps monthly and annual packages without hardcoded prices', () {
      final offering = premiumOfferingFromSnapshot(
        const RevenueCatOfferingSnapshot(
          identifier: 'default',
          packages: [
            RevenueCatPackageSnapshot(
              identifier: r'$rc_monthly',
              productIdentifier: 'rutio_test_premium_monthly',
              localizedPrice: '€2.49',
            ),
            RevenueCatPackageSnapshot(
              identifier: r'$rc_annual',
              productIdentifier: 'rutio_test_premium_annual',
              localizedPrice: '€24.99',
            ),
          ],
        ),
      );

      expect(offering?.monthly?.localizedPrice, '€2.49');
      expect(offering?.annual?.localizedPrice, '€24.99');
    });

    test('tolerates a missing monthly package', () {
      final offering = premiumOfferingFromSnapshot(
        const RevenueCatOfferingSnapshot(
          identifier: 'default',
          packages: [
            RevenueCatPackageSnapshot(
              identifier: r'$rc_annual',
              productIdentifier: 'rutio_test_premium_annual',
              localizedPrice: '€24.99',
            ),
          ],
        ),
      );

      expect(offering?.monthly, isNull);
      expect(offering?.annual, isNotNull);
    });

    test('tolerates a missing annual package', () {
      final offering = premiumOfferingFromSnapshot(
        const RevenueCatOfferingSnapshot(
          identifier: 'default',
          packages: [
            RevenueCatPackageSnapshot(
              identifier: r'$rc_monthly',
              productIdentifier: 'rutio_test_premium_monthly',
              localizedPrice: '€2.49',
            ),
          ],
        ),
      );

      expect(offering?.monthly, isNotNull);
      expect(offering?.annual, isNull);
    });

    test('returns null when the current offering is unavailable', () {
      expect(premiumOfferingFromSnapshot(null), isNull);
      expect(
        premiumOfferingFromSnapshot(
          const RevenueCatOfferingSnapshot(identifier: 'other', packages: []),
        ),
        isNull,
      );
    });
  });
}

RevenueCatCustomerInfoSnapshot _customerInfo({
  RevenueCatEntitlementSnapshot? active,
  RevenueCatEntitlementSnapshot? all,
}) {
  return RevenueCatCustomerInfoSnapshot(
    activeEntitlements: active == null ? const {} : {'premium': active},
    allEntitlements: all == null
        ? (active == null ? const {} : {'premium': active})
        : {'premium': all},
  );
}

RevenueCatEntitlementSnapshot _entitlement({
  required String productIdentifier,
  required bool isActive,
  bool isTrial = false,
  DateTime? expirationDate,
}) {
  return RevenueCatEntitlementSnapshot(
    isActive: isActive,
    isTrial: isTrial,
    productIdentifier: productIdentifier,
    willRenew: isActive,
    expirationDate: expirationDate,
  );
}
