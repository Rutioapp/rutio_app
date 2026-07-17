import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalMysteryBoxOpeningRepository', () {
    test('persists openings after rebuilding the repository', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = LocalMysteryBoxOpeningRepository();
      final transaction = _transaction(
        id: 'tx-1',
        userScope: 'user-a',
        status: MysteryBoxOpeningStatus.granted,
      );

      await repo.saveTransactions('user-a', <MysteryBoxOpeningTransaction>[transaction]);

      final reloaded = LocalMysteryBoxOpeningRepository();
      final loaded = await reloaded.loadTransactions('user-a');

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'tx-1');
      expect(loaded.single.status, MysteryBoxOpeningStatus.granted);
      expect(loaded.single.reward.rewardId, 'reward_80_coins_40_xp');
    });

    test('keeps openings separated by user scope', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = LocalMysteryBoxOpeningRepository();
      await repo.saveTransactions(
        'user-a',
        <MysteryBoxOpeningTransaction>[
          _transaction(id: 'tx-a', userScope: 'user-a'),
        ],
      );
      await repo.saveTransactions(
        'user-b',
        <MysteryBoxOpeningTransaction>[
          _transaction(id: 'tx-b', userScope: 'user-b', status: MysteryBoxOpeningStatus.presented),
        ],
      );

      expect((await repo.loadTransactions('user-a')).single.id, 'tx-a');
      expect((await repo.loadTransactions('user-b')).single.id, 'tx-b');
    });

    test('filters invalid or corrupt records on load', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        '${LocalMysteryBoxOpeningRepository.storageKey}_user-a':
            '[{"id":"","userScope":"user-a","mysteryBoxUtilityId":"utility_mystery_box_basic","reward":{"rewardId":"reward_80_coins_40_xp","coins":80,"xp":40,"utilityRewards":{}},"createdAtMillis":1,"status":"granted"},'
            '{"id":"tx-valid","userScope":"user-a","mysteryBoxUtilityId":"utility_mystery_box_basic","reward":{"rewardId":"reward_80_coins_40_xp","coins":80,"xp":40,"utilityRewards":{}},"createdAtMillis":2,"status":"granted"}]',
      });

      final repo = LocalMysteryBoxOpeningRepository();
      final loaded = await repo.loadTransactions('user-a');

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'tx-valid');
    });
  });
}

MysteryBoxOpeningTransaction _transaction({
  required String id,
  required String userScope,
  MysteryBoxOpeningStatus status = MysteryBoxOpeningStatus.granted,
}) {
  return MysteryBoxOpeningTransaction(
    id: id,
    userScope: userScope,
    mysteryBoxUtilityId: 'utility_mystery_box_basic',
    reward: MysteryBoxRewardResult(
      rewardId: 'reward_80_coins_40_xp',
      coins: 80,
      xp: 40,
      utilityRewards: <String, int>{},
    ),
    createdAtMillis: 1,
    status: status,
  );
}
