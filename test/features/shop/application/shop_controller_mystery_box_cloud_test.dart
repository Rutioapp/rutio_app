import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/shop_controller.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_dtos.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/local_mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/data/shop_local_repository.dart';
import 'package:rutio/features/shop/domain/shop_state.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShopController mystery box cloud', () {
    test('double tap resolves only one cloud open request', () async {
      final completer = Completer<RemoteMysteryBoxOpeningResultDto>();
      final cloudRepo = _FakeCloudMysteryBoxOpeningRepository(
        response: completer.future,
      );
      final fixture = await _createController(cloudRepo: cloudRepo);

      final first = fixture.controller.openMysteryBox(transactionId: 'tx-1');
      final second = fixture.controller.openMysteryBox(transactionId: 'tx-1');

      final duplicate = await second;
      expect(duplicate.status, MysteryBoxOperationStatus.duplicateTransaction);

      completer.complete(
        RemoteMysteryBoxOpeningResultDto(
          requestId: 'tx-1',
          operation: 'open',
          userId: 'user-a',
          mysteryBoxUtilityId: 'utility_mystery_box_basic',
          reward: RemoteMysteryBoxRewardDto(
            rewardId: 'reward_80_coins_40_xp',
            rewardType: RemoteMysteryBoxRewardType.coins,
            quantity: 80,
            weight: 40,
            rarity: 'common',
            isActive: true,
            catalogVersion: 1,
            coins: 80,
            xp: 40,
            utilityRewards: const <String, int>{},
            maxQuantity: null,
          ),
          createdAt: DateTime.utc(2026, 7, 19, 12),
          balanceAfter: 980,
          walletVersion: 1,
          remainingBoxes: 2,
        ),
      );

      final result = await first;

      expect(result.status, MysteryBoxOperationStatus.success);
      expect(cloudRepo.calls, 1);
    });
  });
}

class _FakeCloudMysteryBoxOpeningRepository
    implements CloudMysteryBoxOpeningRepository {
  _FakeCloudMysteryBoxOpeningRepository({required Future<RemoteMysteryBoxOpeningResultDto> response})
      : _response = response;

  final Future<RemoteMysteryBoxOpeningResultDto> _response;
  int calls = 0;

  @override
  Future<RemoteMysteryBoxOpeningResultDto> openMysteryBox({
    required String requestId,
  }) async {
    calls += 1;
    return _response;
  }
}

Future<_ControllerFixture> _createController({
  required _FakeCloudMysteryBoxOpeningRepository cloudRepo,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});

  final repo = UserStateRepository(storage: UserStateStorage())
    ..setActiveUserScope('user-a');
  final store = UserStateStore(
    repo,
    journalEntrySyncService: JournalEntrySyncService(),
  );
  await store.save(_baseState(userId: 'user-a', dateKey: '2026-07-19'));

  final shopRepository = ShopLocalRepository(scopeResolver: () => 'user-a');
  await shopRepository.save(const ShopState.initial());

  final transactionRepository = LocalMysteryBoxOpeningRepository(
    scopeResolver: () => 'user-a',
  );

  return _ControllerFixture(
    controller: ShopController(
      userStateStore: store,
      shopRepository: shopRepository,
      mysteryBoxOpeningRepository: transactionRepository,
      cloudMysteryBoxOpeningRepository: cloudRepo,
      currentSupabaseUserIdProvider: () => 'user-a',
      cloudReadEnabled: false,
      cloudPurchaseEnabled: false,
      mysteryBoxCloudEnabled: true,
    ),
  );
}

class _ControllerFixture {
  const _ControllerFixture({required this.controller});

  final ShopController controller;
}

Map<String, dynamic> _baseState({
  required String userId,
  required String dateKey,
}) {
  return <String, dynamic>{
    'userState': <String, dynamic>{
      'userId': userId,
      'meta': <String, dynamic>{
        'schemaVersion': 1,
        'lastSavedAt': '2026-07-19T12:00:00.000Z',
        'diaryRewardAppliedDateKeys': <dynamic>[],
      },
      'progression': <String, dynamic>{
        'level': 1,
        'xp': 0,
        'prestige': 0,
      },
      'wallet': <String, dynamic>{'coins': 0},
      'inventory': <String, dynamic>{'items': <dynamic>[]},
      'profile': <String, dynamic>{
        'equipped': <String, dynamic>{},
        'badges': <String, dynamic>{'owned': <dynamic>[], 'shown': null},
        'achievements': <String, dynamic>{
          'unlocked': <dynamic>[],
          'featured': <dynamic>[],
          'rewardAppliedAchievementIds': <dynamic>[],
          'progress': <String, dynamic>{},
        },
      },
      'claims': <String, dynamic>{
        'milestonesClaimed': <dynamic>[],
        'achievementRewardsClaimed': <dynamic>[],
        'prestigeClaimed': <dynamic>[],
      },
      'daily': <String, dynamic>{
        'lastResetDate': dateKey,
        'xpEarnedToday': 0,
        'coinsEarnedToday': 0,
        'habitsCompletedToday': <String, dynamic>{},
      },
      'history': <String, dynamic>{
        'habitCompletions': <String, dynamic>{},
        'habitCountValues': <String, dynamic>{},
        'habitSkips': <String, dynamic>{},
        'habitCompletionTimes': <String, dynamic>{},
      },
      'familyXp': <String, dynamic>{
        'mind': 0,
        'spirit': 0,
        'body': 0,
        'emotional': 0,
        'social': 0,
        'discipline': 0,
        'professional': 0,
      },
      'activeHabits': <dynamic>[],
    },
  };
}
