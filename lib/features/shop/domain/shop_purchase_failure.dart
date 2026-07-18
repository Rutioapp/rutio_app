enum ShopPurchaseFailureCode {
  authRequired,
  requestIdRequired,
  itemIdRequired,
  requestIdConflict,
  itemNotFoundOrInactive,
  walletNotInitialized,
  insufficientFunds,
  maxQuantityReached,
  itemAlreadyOwned,
  itemConfigurationInvalid,
  unauthenticated,
  featureDisabled,
  unsupportedCloudItem,
  cloudWalletMissing,
  networkUnavailable,
  timeout,
  malformedResponse,
  sessionChanged,
  operationPending,
  unknown,
}

class ShopPurchaseFailure {
  const ShopPurchaseFailure({
    required this.code,
    required this.message,
    this.cause,
    this.retryable = false,
    this.definitive = false,
  });

  final ShopPurchaseFailureCode code;
  final String message;
  final Object? cause;
  final bool retryable;
  final bool definitive;

  bool get keepPending => !definitive;
}
