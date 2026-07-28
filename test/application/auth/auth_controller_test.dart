import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/stores/user_state_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthController auth stream recovery', () {
    test('AuthRetryableFetchException does not propagate and keeps the user',
        () async {
      final fixture = await _createFixture(
        currentUser: _user('user-1'),
      );

      fixture.authStream.addError(
        AuthRetryableFetchException(message: 'temporary auth fetch issue'),
      );
      await _flushMicrotasks();

      expect(fixture.controller.currentUser?.id, 'user-1');
      expect(fixture.controller.isAuthenticated, isTrue);
      expect(fixture.controller.isCheckingSession, isFalse);
    });

    test('Failed host lookup does not close the session', () async {
      final fixture = await _createFixture(
        currentUser: _user('user-2'),
      );

      fixture.authStream.addError(
        const SocketException('Failed host lookup: supabase.co'),
      );
      await _flushMicrotasks();

      expect(fixture.controller.currentUser?.id, 'user-2');
      expect(fixture.controller.isAuthenticated, isTrue);
      expect(fixture.controller.isCheckingSession, isFalse);
      expect(fixture.userStateStore.switchLocalScopeCalls, greaterThan(0));
    });

    test('isCheckingSession finishes after a recoverable auth stream error',
        () async {
      final fixture = await _createFixture(
        currentUser: _user('user-3'),
      );

      expect(fixture.controller.isCheckingSession, isFalse);

      fixture.authStream.addError(
        AuthRetryableFetchException(message: 'retry later'),
      );
      await _flushMicrotasks();

      expect(fixture.controller.isCheckingSession, isFalse);
    });

    test('tokenRefreshed still processes after a stream error', () async {
      final fixture = await _createFixture(
        currentUser: _user('user-4'),
      );
      final beforeCount = fixture.userStateStore.switchLocalScopeCalls;

      fixture.authStream.addError(
        const SocketException('Failed host lookup: supabase.co'),
      );
      fixture.authStream.add(_authState(
        AuthChangeEvent.tokenRefreshed,
        _session(_user('user-4')),
      ));
      await _flushMicrotasks();

      expect(fixture.controller.currentUser?.id, 'user-4');
      expect(fixture.controller.isAuthenticated, isTrue);
      expect(
        fixture.userStateStore.switchLocalScopeCalls,
        greaterThan(beforeCount),
      );
    });

    test('an unawaited background task error is captured', () async {
      final fixture = await _createFixture(
        currentUser: null,
        throwOnNextWalletSync: true,
      );

      fixture.authStream.add(
        _authState(
          AuthChangeEvent.signedIn,
          _session(_user('user-5')),
        ),
      );
      await _flushMicrotasks();

      expect(fixture.controller.currentUser?.id, 'user-5');
      expect(fixture.controller.isAuthenticated, isTrue);
      expect(
          fixture.walletController.syncSessionCalls, greaterThanOrEqualTo(1));
      expect(
        fixture.userStateStore.switchLocalScopeCalls,
        greaterThanOrEqualTo(1),
      );
    });

    test('dispose cancels the auth subscription', () async {
      final fixture = await _createFixture();

      expect(fixture.authStream.hasListener, isTrue);

      fixture.controller.dispose();

      expect(fixture.authStream.hasListener, isFalse);
    });
  });
}

Future<_AuthFixture> _createFixture({
  User? currentUser,
  bool throwOnNextWalletSync = false,
}) async {
  final authStream = StreamController<AuthState>.broadcast(sync: true);
  final userStateStore = _FakeUserStateStore();
  final walletController = _FakeGlobalWalletController(
    throwOnNextSync: throwOnNextWalletSync,
  );
  final authRepository = AuthRepository(
    authStateChangesProvider: () => authStream.stream,
    currentUserProvider: () => currentUser,
  );

  final controller = AuthController(
    authRepository,
    userStateStore: userStateStore,
    globalWalletController: walletController,
    profileRepository: null,
  );
  authStream.add(
    _authState(
      AuthChangeEvent.initialSession,
      currentUser == null ? null : _session(currentUser),
    ),
  );

  await _flushMicrotasks();

  return _AuthFixture(
    authStream: authStream,
    controller: controller,
    userStateStore: userStateStore,
    walletController: walletController,
  );
}

Future<void> _flushMicrotasks() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

AuthState _authState(AuthChangeEvent event, Session? session) {
  return AuthState(event, session);
}

Session _session(User user) {
  return Session(
    accessToken: 'access-token',
    tokenType: 'bearer',
    user: user,
  );
}

User _user(String id) {
  return User(
    id: id,
    appMetadata: const <String, dynamic>{},
    userMetadata: <String, dynamic>{'display_name': 'Rutio'},
    aud: 'authenticated',
    createdAt: '2026-07-22T00:00:00Z',
  );
}

class _AuthFixture {
  const _AuthFixture({
    required this.authStream,
    required this.controller,
    required this.userStateStore,
    required this.walletController,
  });

  final StreamController<AuthState> authStream;
  final AuthController controller;
  final _FakeUserStateStore userStateStore;
  final _FakeGlobalWalletController walletController;
}

class _FakeUserStateStore extends UserStateStore {
  _FakeUserStateStore()
      : super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  int switchLocalScopeCalls = 0;
  int restoreCalls = 0;
  int suppressCalls = 0;

  @override
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) async {
    switchLocalScopeCalls += 1;
  }

  @override
  void restoreGamificationOverlaysAfterLogout() {
    restoreCalls += 1;
  }

  @override
  void suppressGamificationOverlaysDuringLogout() {
    suppressCalls += 1;
  }
}

class _FakeGlobalWalletController extends GlobalWalletController {
  _FakeGlobalWalletController({
    required bool throwOnNextSync,
  })  : _throwOnNextSync = throwOnNextSync,
        super(
          repository: _NoopCloudWalletRepository(),
          cache: _NoopWalletCache(),
          enabled: true,
        );

  bool _throwOnNextSync;
  int syncSessionCalls = 0;
  int clearSessionCalls = 0;

  @override
  Future<GlobalWalletState> syncSession({
    String? userId,
    bool force = false,
  }) async {
    syncSessionCalls += 1;
    if (_throwOnNextSync) {
      _throwOnNextSync = false;
      throw StateError('wallet sync failed');
    }
    return GlobalWalletState.unauthenticated();
  }

  @override
  Future<GlobalWalletState> clearSession() async {
    clearSessionCalls += 1;
    return GlobalWalletState.unauthenticated();
  }
}

class _NoopCloudWalletRepository implements CloudWalletRepository {
  @override
  Future<WalletReadResult<CloudWalletSnapshot>> fetchWallet() async {
    return const WalletReadResult<CloudWalletSnapshot>.failure(
      failure: WalletFailure(
        code: WalletFailureCode.unknown,
        message: 'noop',
      ),
    );
  }
}

class _NoopWalletCache implements WalletCache {
  @override
  Future<void> clearForUser(String userId) async {}

  @override
  Future<WalletCacheEntry?> read(String userId) async => null;

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async => null;
}
