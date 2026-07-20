import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_errors.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_remote_data_sources.dart';
import 'package:rutio/features/shop/data/cloud/mystery_box_opening_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SupabaseCloudMysteryBoxOpeningRepository', () {
    test('rejects malformed reward probabilities as malformed response',
        () async {
      final repo = SupabaseCloudMysteryBoxOpeningRepository(
        remoteDataSource: _FakeRemoteDataSource(
          response: <String, dynamic>{
            'requestId': 'tx-1',
            'operation': 'open',
            'userId': 'user-a',
            'mysteryBoxUtilityId': 'utility_mystery_box_basic',
            'reward': <String, dynamic>{
              'rewardId': 'reward_80_coins_40_xp',
              'rewardType': 'coins',
              'quantity': 80,
              'weight': 0,
              'rarity': 'common',
              'isActive': true,
              'catalogVersion': 1,
              'coins': 80,
              'xp': 40,
              'utilityRewards': <String, dynamic>{},
            },
            'createdAt': '2026-07-19T12:00:00.000Z',
            'balanceAfter': 980,
            'walletVersion': 1,
            'remainingBoxes': 2,
          },
        ),
        enabled: true,
        currentUserIdProvider: () => 'user-a',
      );

      await expectLater(
        () => repo.openMysteryBox(requestId: 'tx-1'),
        throwsA(
          isA<MysteryBoxOpeningCloudException>().having(
            (error) => error.code,
            'code',
            MysteryBoxOpeningCloudErrorCode.malformedResponse,
          ),
        ),
      );
    });
  });
}

class _FakeRemoteDataSource implements MysteryBoxOpeningRemoteDataSource {
  _FakeRemoteDataSource({
    required this.response,
  });

  final Object? response;

  @override
  Future<Object?> openMysteryBox({
    required String requestId,
  }) async {
    return response;
  }
}
