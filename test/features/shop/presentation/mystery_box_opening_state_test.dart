import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/presentation/models/mystery_box_opening_state.dart';

void main() {
  group('MysteryBoxOpeningState', () {
    test('ready state can start opening', () {
      final state = MysteryBoxOpeningState.ready(transaction: _transaction());

      expect(state.status, MysteryBoxOpeningUiStatus.ready);
      expect(state.canStartOpening, isTrue);
      expect(state.isBusy, isFalse);
      expect(state.isRewardVisible, isFalse);
    });

    test('opening states are busy', () {
      final opening = MysteryBoxOpeningState.ready(
        transaction: _transaction(),
      ).copyWith(status: MysteryBoxOpeningUiStatus.openingInProgress);
      final reveal = opening.copyWith(
        status: MysteryBoxOpeningUiStatus.revealAnimation,
      );

      expect(opening.isBusy, isTrue);
      expect(reveal.isBusy, isTrue);
      expect(reveal.canStartOpening, isFalse);
    });

    test('reward visible keeps transaction and allows error updates', () {
      final state = MysteryBoxOpeningState.ready(
        transaction: _transaction(),
      ).copyWith(status: MysteryBoxOpeningUiStatus.rewardVisible);
      final errored = state.copyWith(
        status: MysteryBoxOpeningUiStatus.error,
        errorMessage: 'retry',
      );

      expect(state.isRewardVisible, isTrue);
      expect(errored.status, MysteryBoxOpeningUiStatus.error);
      expect(errored.errorMessage, 'retry');
      expect(errored.transaction, state.transaction);
    });

    test('clearError removes any existing message', () {
      final state = MysteryBoxOpeningState(
        status: MysteryBoxOpeningUiStatus.error,
        transaction: _transaction(),
        errorMessage: 'failure',
      );

      expect(state.copyWith(clearError: true).errorMessage, isNull);
    });
  });
}

MysteryBoxOpeningTransaction _transaction() {
  return MysteryBoxOpeningTransaction(
    id: 'tx-1',
    userScope: 'shop-user',
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: MysteryBoxRewardResult(
      rewardId: 'reward_80_coins_40_xp',
      coins: 80,
      xp: 40,
      utilityRewards: <String, int>{},
    ),
    createdAtMillis: 1,
    status: MysteryBoxOpeningStatus.granted,
  );
}
