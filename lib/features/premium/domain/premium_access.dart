enum PremiumAccessStatus {
  unknown,
  free,
  trial,
  premium,
  expired,
}

class PremiumAccessState {
  const PremiumAccessState({
    required this.status,
    required this.isPremium,
    this.expirationDate,
    this.productIdentifier,
    this.willRenew,
  });

  const PremiumAccessState.unknown()
      : this(status: PremiumAccessStatus.unknown, isPremium: false);

  const PremiumAccessState.free()
      : this(status: PremiumAccessStatus.free, isPremium: false);

  final PremiumAccessStatus status;
  final bool isPremium;
  final DateTime? expirationDate;
  final String? productIdentifier;
  final bool? willRenew;

  bool get isTrial => status == PremiumAccessStatus.trial;

  bool get isResolved => status != PremiumAccessStatus.unknown;
}

enum PremiumPlanKind {
  monthly,
  annual,
}

class PremiumSubscriptionPlan {
  const PremiumSubscriptionPlan({
    required this.kind,
    required this.packageIdentifier,
    required this.productIdentifier,
    required this.localizedPrice,
  });

  final PremiumPlanKind kind;
  final String packageIdentifier;
  final String productIdentifier;
  final String localizedPrice;
}

class PremiumOffering {
  const PremiumOffering({
    required this.identifier,
    this.monthly,
    this.annual,
  });

  final String identifier;
  final PremiumSubscriptionPlan? monthly;
  final PremiumSubscriptionPlan? annual;

  bool get hasAnyPlan => monthly != null || annual != null;
}
