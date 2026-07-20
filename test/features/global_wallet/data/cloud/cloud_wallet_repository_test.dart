import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_remote_data_sources.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/global_cloud_wallet_config.dart';

void main() {
  group('GlobalCloudWalletConfig', () {
    test('is disabled by default', () {
      expect(GlobalCloudWalletConfig.isEnabled, isFalse);
    });
  });

  group('SupabaseCloudWalletRepository', () {
    test('maps a valid wallet row into a snapshot', () async {
      final remote = _FakeCloudWalletRemoteDataSource()
        ..row = <String, dynamic>{
          'user_id': 'user-1',
          'coins': 123,
          'version': 7,
          'created_at': '2026-07-18T08:00:00.000Z',
          'updated_at': '2026-07-18T09:00:00.000Z',
        };
      final repository = SupabaseCloudWalletRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
        nowProvider: () => DateTime.utc(2026, 7, 18, 10, 0),
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.userId, 'user-1');
      expect(result.data!.coins, 123);
      expect(result.data!.version, 7);
      expect(
          result.data!.createdAt, DateTime.parse('2026-07-18T08:00:00.000Z'));
      expect(
          result.data!.updatedAt, DateTime.parse('2026-07-18T09:00:00.000Z'));
      expect(result.data!.fetchedAt, DateTime.utc(2026, 7, 18, 10, 0));
      expect(remote.calls, 1);
    });

    test('returns walletMissing when the row is absent', () async {
      final remote = _FakeCloudWalletRemoteDataSource();
      final repository = SupabaseCloudWalletRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, WalletFailureCode.walletMissing);
      expect(remote.calls, 1);
    });

    test('rejects negative balance rows', () async {
      final remote = _FakeCloudWalletRemoteDataSource()
        ..row = <String, dynamic>{
          'user_id': 'user-1',
          'coins': -1,
          'version': 7,
          'created_at': '2026-07-18T08:00:00.000Z',
          'updated_at': '2026-07-18T09:00:00.000Z',
        };
      final repository = SupabaseCloudWalletRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, WalletFailureCode.invalidResponse);
    });

    test('rejects invalid versions', () async {
      final remote = _FakeCloudWalletRemoteDataSource()
        ..row = <String, dynamic>{
          'user_id': 'user-1',
          'coins': 12,
          'version': 'abc',
          'created_at': '2026-07-18T08:00:00.000Z',
          'updated_at': '2026-07-18T09:00:00.000Z',
        };
      final repository = SupabaseCloudWalletRepository(
        remoteDataSource: remote,
        enabled: true,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, WalletFailureCode.invalidResponse);
    });

    test('returns featureDisabled when the flag is off', () async {
      final remote = _FakeCloudWalletRemoteDataSource();
      final repository = SupabaseCloudWalletRepository(
        remoteDataSource: remote,
        enabled: false,
        currentUserIdProvider: () => 'user-1',
      );

      final result = await repository.fetchWallet();

      expect(result.isSuccess, isFalse);
      expect(result.failure?.code, WalletFailureCode.featureDisabled);
      expect(remote.calls, 0);
    });
  });
}

class _FakeCloudWalletRemoteDataSource implements CloudWalletRemoteDataSource {
  int calls = 0;
  Map<String, dynamic>? row;

  @override
  Future<Map<String, dynamic>?> fetchWalletRow() async {
    calls += 1;
    return row;
  }
}
