import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';

enum MysteryBoxOpeningUiStatus {
  ready,
  openingInProgress,
  revealAnimation,
  rewardVisible,
  error,
}

class MysteryBoxOpeningState {
  const MysteryBoxOpeningState({
    required this.status,
    this.transaction,
    this.errorMessage,
  });

  const MysteryBoxOpeningState.ready({
    this.transaction,
  })  : status = MysteryBoxOpeningUiStatus.ready,
        errorMessage = null;

  final MysteryBoxOpeningUiStatus status;
  final MysteryBoxOpeningTransaction? transaction;
  final String? errorMessage;

  bool get canStartOpening =>
      status == MysteryBoxOpeningUiStatus.ready ||
      status == MysteryBoxOpeningUiStatus.error;
  bool get isRewardVisible => status == MysteryBoxOpeningUiStatus.rewardVisible;
  bool get isBusy =>
      status == MysteryBoxOpeningUiStatus.openingInProgress ||
      status == MysteryBoxOpeningUiStatus.revealAnimation;
  bool get hasResolvedTransaction => transaction != null;

  MysteryBoxOpeningState copyWith({
    MysteryBoxOpeningUiStatus? status,
    MysteryBoxOpeningTransaction? transaction,
    String? errorMessage,
    bool clearError = false,
    bool clearTransaction = false,
  }) {
    return MysteryBoxOpeningState(
      status: status ?? this.status,
      transaction: clearTransaction ? null : transaction ?? this.transaction,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
