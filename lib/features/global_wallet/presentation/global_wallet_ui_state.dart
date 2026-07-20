import 'package:flutter/foundation.dart';

import '../application/global_wallet_controller.dart';
import '../application/global_wallet_state.dart';

@immutable
class GlobalWalletUiState {
  const GlobalWalletUiState({
    required this.isEnabled,
    required this.status,
    required this.userId,
    required this.coins,
    required this.isLoading,
    required this.isSyncing,
    required this.isReady,
    required this.isStale,
    required this.isUnauthenticated,
    required this.isWalletMissing,
    required this.isFailed,
  });

  final bool isEnabled;
  final GlobalWalletStatus status;
  final String? userId;
  final int? coins;
  final bool isLoading;
  final bool isSyncing;
  final bool isReady;
  final bool isStale;
  final bool isUnauthenticated;
  final bool isWalletMissing;
  final bool isFailed;

  bool get hasDisplayCoins => coins != null;
  bool get showsCachedBalance => isReady || isSyncing || isStale;
  bool get isBusy => isLoading || isSyncing;
  bool get shouldUseLegacyBalance => !isEnabled;

  @override
  bool operator ==(Object other) {
    return other is GlobalWalletUiState &&
        other.isEnabled == isEnabled &&
        other.status == status &&
        other.userId == userId &&
        other.coins == coins &&
        other.isLoading == isLoading &&
        other.isSyncing == isSyncing &&
        other.isReady == isReady &&
        other.isStale == isStale &&
        other.isUnauthenticated == isUnauthenticated &&
        other.isWalletMissing == isWalletMissing &&
        other.isFailed == isFailed;
  }

  @override
  int get hashCode => Object.hash(
        isEnabled,
        status,
        userId,
        coins,
        isLoading,
        isSyncing,
        isReady,
        isStale,
        isUnauthenticated,
        isWalletMissing,
        isFailed,
      );
}

extension GlobalWalletControllerUiX on GlobalWalletController {
  GlobalWalletUiState get uiState {
    final walletState = state;
    return GlobalWalletUiState(
      isEnabled: isEnabled,
      status: walletState.status,
      userId: walletState.userId,
      coins: walletState.coins,
      isLoading: walletState.status == GlobalWalletStatus.loading,
      isSyncing: walletState.status == GlobalWalletStatus.syncing,
      isReady: walletState.status == GlobalWalletStatus.ready,
      isStale: walletState.status == GlobalWalletStatus.stale,
      isUnauthenticated:
          walletState.status == GlobalWalletStatus.unauthenticated,
      isWalletMissing: walletState.status == GlobalWalletStatus.walletMissing,
      isFailed: walletState.status == GlobalWalletStatus.failed,
    );
  }

  int resolveCoinsForUi({required int Function() legacyCoinsBuilder}) {
    if (isEnabled) {
      return state.coins ?? 0;
    }
    return legacyCoinsBuilder();
  }
}
