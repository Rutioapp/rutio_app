import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';

void main() {
  group('GlobalWalletController', () {
    test('hydrates ready state and keeps a per-user cache', () async {
      String? currentUserId = 'user-a';
      final repository = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _snapshot(
            userId: 'user-a',
            coins: 100,
            version: 1,
            updatedAt: DateTime.utc(2026, 7, 18, 9),
          ),
        );
      final cache = _MemoryWalletCache();
      final controller = GlobalWalletController(
        repository: repository,
        cache: cache,
        currentUserIdProvider: () => currentUserId,
        enabled: true,
      );

      await controller.syncSession();

      expect(controller.state.status, GlobalWalletStatus.ready);
      expect(controller.state.userId, 'user-a');
      expect(controller.state.coins, 100);
      expect(cache.keys, contains('user-a'));

      currentUserId = 'user-b';
      repository.enqueueSuccess(
        _snapshot(
          userId: 'user-b',
          coins: 240,
          version: 3,
          updatedAt: DateTime.utc(2026, 7, 18, 10),
        ),
      );

      await controller.syncSession();

      expect(controller.state.status, GlobalWalletStatus.ready);
      expect(controller.state.userId, 'user-b');
      expect(controller.state.coins, 240);
      expect(cache.keys, containsAll(<String>['user-a', 'user-b']));
      expect(cache.readSync('user-a')?.coins, 100);
      expect(cache.readSync('user-b')?.coins, 240);
    });

    test('falls back to stale state when refresh fails and cache exists',
        () async {
      String? currentUserId = 'user-a';
      final repository = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _snapshot(
            userId: 'user-a',
            coins: 100,
            version: 1,
            updatedAt: DateTime.utc(2026, 7, 18, 9),
          ),
        )
        ..enqueueFailure(
          const WalletFailure(
            code: WalletFailureCode.networkUnavailable,
            message: 'Offline.',
          ),
        );
      final cache = _MemoryWalletCache();
      final controller = GlobalWalletController(
        repository: repository,
        cache: cache,
        currentUserIdProvider: () => currentUserId,
        enabled: true,
      );

      await controller.syncSession();
      await controller.refresh();

      expect(controller.state.status, GlobalWalletStatus.stale);
      expect(controller.state.userId, 'user-a');
      expect(controller.state.coins, 100);
      expect(
          controller.state.failure?.code, WalletFailureCode.networkUnavailable);
    });

    test('clears in-memory state on logout but keeps cached data', () async {
      String? currentUserId = 'user-a';
      final repository = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _snapshot(
            userId: 'user-a',
            coins: 80,
            version: 2,
            updatedAt: DateTime.utc(2026, 7, 18, 11),
          ),
        );
      final cache = _MemoryWalletCache();
      final controller = GlobalWalletController(
        repository: repository,
        cache: cache,
        currentUserIdProvider: () => currentUserId,
        enabled: true,
      );

      await controller.syncSession();
      expect(controller.state.status, GlobalWalletStatus.ready);

      currentUserId = null;
      await controller.clearSession();

      expect(controller.state.status, GlobalWalletStatus.unauthenticated);
      expect(controller.state.snapshot, isNull);
      expect(cache.readSync('user-a'), isNotNull);
    });

    test('ignores tardy responses from a prior session', () async {
      String? currentUserId = 'user-a';
      final repository = _FakeCloudWalletRepository();
      final cache = _MemoryWalletCache();
      final controller = GlobalWalletController(
        repository: repository,
        cache: cache,
        currentUserIdProvider: () => currentUserId,
        enabled: true,
      );

      final first = repository.enqueuePending();
      final firstSync = controller.syncSession();
      await Future<void>.delayed(Duration.zero);

      currentUserId = 'user-b';
      final secondSnapshot = _snapshot(
        userId: 'user-b',
        coins: 215,
        version: 4,
        updatedAt: DateTime.utc(2026, 7, 18, 12),
      );
      repository.enqueueSuccess(secondSnapshot);

      final secondSync = controller.syncSession();
      await Future<void>.delayed(Duration.zero);
      await secondSync;

      expect(controller.state.userId, 'user-b');
      expect(controller.state.status, GlobalWalletStatus.ready);
      expect(controller.state.coins, 215);

      first.complete(
        WalletReadResult<CloudWalletSnapshot>.success(
          data: _snapshot(
            userId: 'user-a',
            coins: 999,
            version: 1,
            updatedAt: DateTime.utc(2026, 7, 18, 8),
          ),
        ),
      );
      await firstSync;

      expect(controller.state.userId, 'user-b');
      expect(controller.state.status, GlobalWalletStatus.ready);
      expect(controller.state.coins, 215);
      expect(cache.readSync('user-a'), isNull);
      expect(cache.readSync('user-b')?.coins, 215);
    });

    test('reports featureDisabled when the flag is off', () async {
      final repository = _FakeCloudWalletRepository();
      final cache = _MemoryWalletCache();
      final controller = GlobalWalletController(
        repository: repository,
        cache: cache,
        currentUserIdProvider: () => 'user-a',
        enabled: false,
      );

      await controller.syncSession();

      expect(controller.state.status, GlobalWalletStatus.failed);
      expect(controller.state.failure?.code, WalletFailureCode.featureDisabled);
      expect(repository.calls, 0);
    });

    test('keeps wallet sync isolated from unrelated progression state',
        () async {
      final repository = _FakeCloudWalletRepository()
        ..enqueueSuccess(
          _snapshot(
            userId: 'user-a',
            coins: 30,
            version: 1,
            updatedAt: DateTime.utc(2026, 7, 18, 13),
          ),
        );
      final controller = GlobalWalletController(
        repository: repository,
        cache: _MemoryWalletCache(),
        currentUserIdProvider: () => 'user-a',
        enabled: true,
      );

      await controller.syncSession();

      expect(controller.state.snapshot, isNotNull);
      expect(controller.state.snapshot!.coins, 30);
      expect(controller.state.snapshot!.version, 1);
      expect(controller.state.snapshot, isA<CloudWalletSnapshot>());
    });
  });
}

CloudWalletSnapshot _snapshot({
  required String userId,
  required int coins,
  required int version,
  required DateTime updatedAt,
}) {
  return CloudWalletSnapshot(
    userId: userId,
    coins: coins,
    version: version,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    fetchedAt: updatedAt,
  );
}

class _FakeCloudWalletRepository implements CloudWalletRepository {
  final List<Future<WalletReadResult<CloudWalletSnapshot>>> _responses =
      <Future<WalletReadResult<CloudWalletSnapshot>>>[];

  int calls = 0;

  void enqueueSuccess(CloudWalletSnapshot snapshot) {
    _responses.add(
      Future<WalletReadResult<CloudWalletSnapshot>>.value(
        WalletReadResult<CloudWalletSnapshot>.success(data: snapshot),
      ),
    );
  }

  void enqueueFailure(WalletFailure failure) {
    _responses.add(
      Future<WalletReadResult<CloudWalletSnapshot>>.value(
        WalletReadResult<CloudWalletSnapshot>.failure(failure: failure),
      ),
    );
  }

  Completer<WalletReadResult<CloudWalletSnapshot>> enqueuePending() {
    final completer = Completer<WalletReadResult<CloudWalletSnapshot>>();
    _responses.add(completer.future);
    return completer;
  }

  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() {
    calls += 1;
    if (_responses.isEmpty) {
      throw StateError('No queued wallet response.');
    }
    return _responses.removeAt(0);
  }
}

class _MemoryWalletCache implements WalletCache {
  final Map<String, WalletCacheEntry> _entries = <String, WalletCacheEntry>{};

  Iterable<String> get keys => _entries.keys;

  WalletCacheEntry? readSync(String userId) => _entries[userId];

  @override
  Future<WalletCacheEntry?> read(String userId) async {
    return _entries[userId];
  }

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async {
    final next = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: DateTime.now().toUtc(),
    );
    final current = _entries[snapshot.userId];
    if (current != null && !next.isNewerThan(current)) {
      return current;
    }
    _entries[snapshot.userId] = next;
    return next;
  }

  @override
  Future<void> clearForUser(String userId) async {
    _entries.remove(userId);
  }
}
