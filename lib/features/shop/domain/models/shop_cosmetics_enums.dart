enum ShopAssetOwnershipState {
  locked,
  owned,
  equipped,
  includedInOwnedBundle,
}

enum ShopCosmeticsOperationStatus {
  success,
  assetNotFound,
  bundleNotFound,
  bundleContainsOwnedAssets,
  insufficientCoins,
  alreadyOwned,
  assetNotOwned,
  awaitingResolution,
  remoteStateApplied,
}
