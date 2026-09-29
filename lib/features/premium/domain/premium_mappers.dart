import '../data/revenuecat/revenuecat_client.dart';
import 'premium_access.dart';

const premiumEntitlementIdentifier = 'premium';
const currentOfferingIdentifier = 'default';
const monthlyPackageIdentifier = r'$rc_monthly';
const annualPackageIdentifier = r'$rc_annual';

PremiumAccessState premiumAccessStateFromCustomerInfo(
  RevenueCatCustomerInfoSnapshot customerInfo, {
  DateTime? now,
}) {
  final active = customerInfo.activeEntitlements[premiumEntitlementIdentifier];
  if (active != null && active.isActive) {
    return PremiumAccessState(
      status: active.isTrial
          ? PremiumAccessStatus.trial
          : PremiumAccessStatus.premium,
      isPremium: true,
      expirationDate: active.expirationDate,
      productIdentifier: active.productIdentifier,
      willRenew: active.willRenew,
    );
  }

  final inactive = customerInfo.allEntitlements[premiumEntitlementIdentifier];
  final expirationDate = inactive?.expirationDate;
  final referenceTime = now ?? DateTime.now();
  if (inactive != null &&
      !inactive.isActive &&
      expirationDate != null &&
      expirationDate.isBefore(referenceTime)) {
    return PremiumAccessState(
      status: PremiumAccessStatus.expired,
      isPremium: false,
      expirationDate: expirationDate,
      productIdentifier: inactive.productIdentifier,
      willRenew: inactive.willRenew,
    );
  }

  return const PremiumAccessState.free();
}

PremiumOffering? premiumOfferingFromSnapshot(
  RevenueCatOfferingSnapshot? offering,
) {
  if (offering == null || offering.identifier != currentOfferingIdentifier) {
    return null;
  }

  PremiumSubscriptionPlan? planFor(
    String packageIdentifier,
    PremiumPlanKind kind,
  ) {
    RevenueCatPackageSnapshot? package;
    for (final candidate in offering.packages) {
      if (candidate.identifier == packageIdentifier) {
        package = candidate;
        break;
      }
    }
    if (package == null) return null;
    return PremiumSubscriptionPlan(
      kind: kind,
      packageIdentifier: package.identifier,
      productIdentifier: package.productIdentifier,
      localizedPrice: package.localizedPrice,
    );
  }

  return PremiumOffering(
    identifier: offering.identifier,
    monthly: planFor(monthlyPackageIdentifier, PremiumPlanKind.monthly),
    annual: planFor(annualPackageIdentifier, PremiumPlanKind.annual),
  );
}
