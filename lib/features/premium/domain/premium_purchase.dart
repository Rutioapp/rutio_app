enum PremiumPurchaseResultKind { success, cancelled, pending, failed }

enum PremiumPurchaseErrorKind {
  network,
  productUnavailable,
  notAllowed,
  storeProblem,
  alreadyPurchased,
  authenticationRequired,
  premiumNotActive,
  unknown,
}

class PremiumPurchaseError {
  const PremiumPurchaseError(this.kind);

  final PremiumPurchaseErrorKind kind;
}

class PremiumPurchaseResult {
  const PremiumPurchaseResult._({
    required this.kind,
    this.error,
  });

  const PremiumPurchaseResult.success()
      : this._(kind: PremiumPurchaseResultKind.success);

  const PremiumPurchaseResult.cancelled()
      : this._(kind: PremiumPurchaseResultKind.cancelled);

  const PremiumPurchaseResult.pending()
      : this._(kind: PremiumPurchaseResultKind.pending);

  const PremiumPurchaseResult.failed(PremiumPurchaseError error)
      : this._(kind: PremiumPurchaseResultKind.failed, error: error);

  final PremiumPurchaseResultKind kind;
  final PremiumPurchaseError? error;

  bool get isSuccess => kind == PremiumPurchaseResultKind.success;
  bool get isCancelled => kind == PremiumPurchaseResultKind.cancelled;
}
