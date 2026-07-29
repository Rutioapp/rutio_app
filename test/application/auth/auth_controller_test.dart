import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/data/repositories/profile_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/achievement_sync_service.dart';
import 'package:rutio/data/services/habit_log_sync_service.dart';
import 'package:rutio/data/services/habit_sync_service.dart';
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

  group('AuthController fail-closed sign out', () {
    test('successful logout clears local scope and calls sign-out once',
        () async {
      final fixture = await _createSignOutFixture(currentUserId: 'user-a');

      await fixture.controller.signOut();

      expect(fixture.signOutCalls, 1);
      expect(fixture.controller.isAuthenticated, isFalse);
      expect(fixture.userStateStore.suppressed, isTrue);
      expect(fixture.userStateStore.scopeHistory.last, isNull);
      expect(fixture.walletController.clearSessionCalls, 1);
      expect(fixture.controller.errorMessage, isNull);
    });

    test('double tap reuses the in-flight sign-out', () async {
      final completer = Completer<void>();
      final fixture = await _createSignOutFixture(
        currentUserId: 'user-a',
        signOutCompleter: completer,
      );

      final first = fixture.controller.signOut();
      final second = fixture.controller.signOut();
      await _flushMicrotasks();

      expect(fixture.signOutCalls, 1);
      completer.complete();
      await Future.wait(<Future<void>>[first, second]);

      expect(fixture.signOutCalls, 1);
      expect(fixture.controller.isAuthenticated, isFalse);
      expect(fixture.userStateStore.scopeHistory.last, isNull);
    });

    test('sign-out exception leaves private data hidden and reports error',
        () async {
      final fixture = await _createSignOutFixture(
        currentUserId: 'user-a',
        signOutError: AuthException('network failure'),
      );

      await fixture.controller.signOut();

      expect(fixture.signOutCalls, 1);
      expect(fixture.controller.isAuthenticated, isFalse);
      expect(fixture.userStateStore.scopeHistory.last, isNull);
      expect(fixture.walletController.clearSessionCalls, 1);
      expect(
        fixture.controller.errorMessage,
        'Could not finish remote sign-out. Please try again.',
      );
    });

    test('stale auth event for locally signed-out user does not reopen home',
        () async {
      final fixture = await _createSignOutFixture(
        currentUserId: 'user-a',
        signOutError: AuthException('network failure'),
      );

      await fixture.controller.signOut();
      fixture.authStream.add(
        _authState(AuthChangeEvent.tokenRefreshed, _session(_user('user-a'))),
      );
      await _flushMicrotasks();

      expect(fixture.controller.isAuthenticated, isFalse);
      expect(fixture.userStateStore.scopeHistory.last, isNull);
    });

    test('new login after failed logout creates a new scope', () async {
      final fixture = await _createSignOutFixture(
        currentUserId: 'user-a',
        signOutError: AuthException('network failure'),
        signInUserId: 'user-b',
      );

      await fixture.controller.signOut();
      final response = await fixture.controller.signInWithEmailPassword(
        email: 'b@example.com',
        password: 'secret-password',
      );

      expect(response, isNotNull);
      expect(fixture.controller.currentUser?.id, 'user-b');
      expect(
          fixture.userStateStore.scopeHistory,
          containsAll(<String?>[
            null,
            'user-b',
          ]));
    });
  });

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

  group('AuthController post-home bootstrap', () {
    test('simultaneous starts for the same run reuse one in-flight task',
        () async {
      final completer = Completer<void>();
      var calls = 0;
      final fixture = await _createPostHomeFixture(
        postHomeBootstrapTaskRunner: (_) async {
          calls += 1;
          await completer.future;
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      expect(calls, 1);

      completer.complete();
      await fixture.pump();
    });

    test('after success, a new post-home run can start again', () async {
      final firstCompleter = Completer<void>();
      var calls = 0;
      final fixture = await _createPostHomeFixture(
        postHomeBootstrapTaskRunner: (_) async {
          calls += 1;
          await firstCompleter.future;
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      firstCompleter.complete();
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 2,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      expect(calls, 2);
    });

    test('after error, the in-flight task is released', () async {
      var calls = 0;
      final fixture = await _createPostHomeFixture(
        postHomeBootstrapTaskRunner: (_) async {
          calls += 1;
          throw StateError('post-home failure');
        },
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      expect(calls, 2);
    });

    test('logout during post-home work discards the stale result', () async {
      final loginTouchCompleter = Completer<RepositoryResult<RemoteProfile>>();
      final fixture = await _createPostHomeFixture(
        profileRepository: _PostHomeProfileRepository(
          touchLastLoginCompleters: <Completer<
              RepositoryResult<RemoteProfile>>>[
            loginTouchCompleter,
          ],
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      expect(fixture.profileRepository.touchLastLoginCalls, 1);

      fixture.resolveGuest();
      await fixture.pump();

      loginTouchCompleter.complete(
        RepositoryResult<RemoteProfile>.success(
          data: _remoteProfile('user-1'),
        ),
      );
      await fixture.pump();

      expect(fixture.profileRepository.touchLastSeenCalls, 0);
      expect(fixture.userStateStore.progressSyncCalls, 0);
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('metric=post_home_stale_discard') &&
              line.contains('stage=touch_last_login'),
        ),
        isTrue,
      );
    });

    test('post-home work no longer runs an authoritative shadow fetch',
        () async {
      final fixture = await _createPostHomeFixture();

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: fixture.userStateStore.activeLocalScopeUserId!,
        scopeEpoch: fixture.userStateStore.scopeEpoch,
      );
      await fixture.pump();

      expect(fixture.profileRepository.authoritativeLoadCalls, 0);
      expect(
        fixture.logs.any(
          (line) => line.contains('metric=post_home_total'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) => line.contains('authoritative_profile_'),
        ),
        isFalse,
      );
    });

    test('a newer bootstrap run invalidates results from the previous run',
        () async {
      final firstLoginTouch = Completer<RepositoryResult<RemoteProfile>>();
      final secondLoginTouch = Completer<RepositoryResult<RemoteProfile>>();
      final fixture = await _createPostHomeFixture(
        profileRepository: _PostHomeProfileRepository(
          touchLastLoginCompleters: <Completer<
              RepositoryResult<RemoteProfile>>>[
            firstLoginTouch,
            secondLoginTouch,
          ],
        ),
      );

      fixture.resolveUser('user-1');
      await fixture.pump();

      final scopeUserId = fixture.userStateStore.activeLocalScopeUserId!;
      final scopeEpoch = fixture.userStateStore.scopeEpoch;
      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 1,
        userId: 'user-1',
        scopeUserId: scopeUserId,
        scopeEpoch: scopeEpoch,
      );
      await fixture.pump();

      fixture.controller.startPostHomeBootstrapWork(
        bootstrapRunId: 2,
        userId: 'user-1',
        scopeUserId: scopeUserId,
        scopeEpoch: scopeEpoch,
      );
      await fixture.pump();

      expect(fixture.profileRepository.touchLastLoginCalls, 2);

      firstLoginTouch.complete(
        RepositoryResult<RemoteProfile>.success(
          data: _remoteProfile('user-1'),
        ),
      );
      await fixture.pump();

      expect(fixture.profileRepository.touchLastSeenCalls, 0);
      expect(fixture.userStateStore.progressSyncCalls, 0);

      secondLoginTouch.complete(
        RepositoryResult<RemoteProfile>.success(
          data: _remoteProfile('user-1'),
        ),
      );
      await fixture.pump();

      expect(fixture.profileRepository.touchLastSeenCalls, 1);
      expect(fixture.userStateStore.progressSyncCalls, 1);
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('run=1 metric=post_home_stale_discard') &&
              line.contains('stage=touch_last_login'),
        ),
        isTrue,
      );
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

Future<_PostHomeAuthFixture> _createPostHomeFixture({
  PostHomeBootstrapTaskRunner? postHomeBootstrapTaskRunner,
  _PostHomeProfileRepository? profileRepository,
}) async {
  final authStream = StreamController<AuthState>.broadcast(sync: true);
  final userStateStore = _PostHomeUserStateStore();
  final walletController = _FakeGlobalWalletController(
    throwOnNextSync: false,
  );
  final fixture = _PostHomeAuthFixture._(
    authStream: authStream,
    userStateStore: userStateStore,
    walletController: walletController,
    profileRepository: profileRepository ?? _PostHomeProfileRepository(),
  );

  fixture.controller = AuthController(
    AuthRepository(
      authStateChangesProvider: () => authStream.stream,
      currentUserProvider: () => fixture.currentUser,
    ),
    userStateStore: userStateStore,
    globalWalletController: walletController,
    profileRepository: fixture.profileRepository,
    enableBackgroundProfileSync: true,
    postHomeBootstrapTaskRunner: postHomeBootstrapTaskRunner,
    debugLogger: fixture.logs.add,
  );

  addTearDown(() async {
    fixture.controller.dispose();
    await authStream.close();
  });

  await fixture.pump();
  return fixture;
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

Future<_SignOutFixture> _createSignOutFixture({
  required String currentUserId,
  Completer<void>? signOutCompleter,
  Object? signOutError,
  String signInUserId = 'user-b',
}) async {
  final authStream = StreamController<AuthState>.broadcast(sync: true);
  final userStateStore = _SignOutUserStateStore();
  final walletController = _FakeGlobalWalletController(
    throwOnNextSync: false,
  );
  final fixture = _SignOutFixture._(
    authStream: authStream,
    userStateStore: userStateStore,
    walletController: walletController,
    currentUser: _user(currentUserId),
    signInUser: _user(signInUserId),
    signOutCompleter: signOutCompleter,
    signOutError: signOutError,
  );

  fixture.controller = AuthController(
    AuthRepository(
      authStateChangesProvider: () => authStream.stream,
      currentUserProvider: () => fixture.currentUser,
      signOutProvider: fixture.signOut,
      signInWithEmailPasswordProvider: fixture.signIn,
    ),
    userStateStore: userStateStore,
    globalWalletController: walletController,
    profileRepository: null,
    enableBackgroundProfileSync: false,
  );
  authStream.add(
    _authState(
      AuthChangeEvent.initialSession,
      _session(fixture.currentUser!),
    ),
  );
  await _flushMicrotasks();
  return fixture;
}

class _SignOutFixture {
  _SignOutFixture._({
    required this.authStream,
    required this.userStateStore,
    required this.walletController,
    required this.currentUser,
    required this.signInUser,
    this.signOutCompleter,
    this.signOutError,
  });

  final StreamController<AuthState> authStream;
  final _SignOutUserStateStore userStateStore;
  final _FakeGlobalWalletController walletController;
  final User signInUser;
  final Completer<void>? signOutCompleter;
  final Object? signOutError;
  late AuthController controller;
  User? currentUser;
  int signOutCalls = 0;

  Future<void> signOut() async {
    signOutCalls += 1;
    final pending = signOutCompleter;
    if (pending != null) {
      await pending.future;
    }
    if (signOutError != null) {
      throw signOutError!;
    }
    currentUser = null;
    authStream.add(_authState(AuthChangeEvent.signedOut, null));
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    currentUser = signInUser;
    authStream.add(
      _authState(AuthChangeEvent.signedIn, _session(signInUser)),
    );
    return AuthResponse(
      session: _session(signInUser),
      user: signInUser,
    );
  }
}

class _PostHomeAuthFixture {
  _PostHomeAuthFixture._({
    required this.authStream,
    required this.userStateStore,
    required this.walletController,
    required this.profileRepository,
  });

  final StreamController<AuthState> authStream;
  final _PostHomeUserStateStore userStateStore;
  final _FakeGlobalWalletController walletController;
  final _PostHomeProfileRepository profileRepository;
  final List<String> logs = <String>[];
  late AuthController controller;
  User? currentUser;

  void resolveUser(String id) {
    currentUser = _user(id);
    authStream.add(
      _authState(AuthChangeEvent.initialSession, _session(_user(id))),
    );
  }

  void resolveGuest() {
    currentUser = null;
    authStream.add(_authState(AuthChangeEvent.signedOut, null));
  }

  Future<void> pump() => _flushMicrotasks();
}

class _SignOutUserStateStore extends UserStateStore {
  _SignOutUserStateStore()
      : super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  final List<String?> scopeHistory = <String?>[];
  bool suppressed = false;
  String? _scopeUserId = 'user-a';
  int _scopeEpoch = 1;

  @override
  String? get activeLocalScopeUserId => _scopeUserId;

  @override
  String? get userId => _scopeUserId;

  @override
  int get scopeEpoch => _scopeEpoch;

  @override
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) async {
    _scopeUserId = userId;
    _scopeEpoch += 1;
    scopeHistory.add(userId);
  }

  @override
  void suppressGamificationOverlaysDuringLogout() {
    suppressed = true;
  }
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

class _PostHomeUserStateStore extends UserStateStore {
  _PostHomeUserStateStore()
      : super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  String? _scopeUserId;
  int _scopeEpoch = 0;
  Map<String, dynamic>? _fakeState;
  int progressSyncCalls = 0;
  int habitBackfillCalls = 0;
  int habitLogBackfillCalls = 0;
  int journalBackfillCalls = 0;
  int achievementBackfillCalls = 0;

  @override
  Map<String, dynamic>? get state => _fakeState;

  @override
  bool get isLoading => false;

  @override
  String? get activeLocalScopeUserId => _scopeUserId;

  @override
  String? get userId => _scopeUserId;

  @override
  int get scopeEpoch => _scopeEpoch;

  @override
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) async {
    if (_scopeUserId != userId || forceReload) {
      _scopeEpoch += 1;
    }
    _scopeUserId = userId;
    _fakeState = <String, dynamic>{
      'userState': <String, dynamic>{
        if (userId != null) 'userId': userId,
        'meta': const <String, dynamic>{'onboardingDone': true},
        'profile': <String, dynamic>{
          if (userId != null) 'displayName': 'Rutio User',
        },
      },
    };
  }

  @override
  Future<void> load() async {
    _fakeState ??= <String, dynamic>{
      'userState': <String, dynamic>{
        if (_scopeUserId != null) 'userId': _scopeUserId,
        'meta': const <String, dynamic>{'onboardingDone': true},
        'profile': const <String, dynamic>{'displayName': 'Rutio User'},
      },
    };
  }

  @override
  Future<void> applySupabaseIdentity({
    required String userId,
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    await load();
  }

  @override
  Future<SupabaseUserProgressBootstrapResult>
      syncSupabaseUserProgressBootstrapBestEffort({
    bool force = false,
  }) async {
    progressSyncCalls += 1;
    return const SupabaseUserProgressBootstrapResult(
      restoreResult: SupabaseUserProgressRestoreResult(
        status: SupabaseUserProgressRestoreStatus.skippedNoRemoteRow,
      ),
      backfillSynced: false,
    );
  }

  @override
  Future<HabitBackfillSummary> syncExistingLocalHabitsOnce({
    bool force = false,
  }) async {
    habitBackfillCalls += 1;
    return const HabitBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  @override
  Future<HabitLogBackfillSummary> syncExistingLocalHabitLogsOnce({
    bool force = false,
  }) async {
    habitLogBackfillCalls += 1;
    return const HabitLogBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  @override
  Future<JournalEntryBackfillSummary> syncExistingLocalJournalEntriesOnce({
    bool force = false,
  }) async {
    journalBackfillCalls += 1;
    return const JournalEntryBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  @override
  Future<AchievementBackfillSummary> syncExistingLocalAchievementsOnce({
    bool force = false,
  }) async {
    achievementBackfillCalls += 1;
    return const AchievementBackfillSummary(
      totalCandidates: 0,
      uploadedCount: 0,
      skippedCount: 0,
      failedCount: 0,
    );
  }

  @override
  void restoreGamificationOverlaysAfterLogout() {}

  @override
  void suppressGamificationOverlaysDuringLogout() {}
}

class _PostHomeProfileRepository extends ProfileRepository {
  _PostHomeProfileRepository({
    List<Completer<RepositoryResult<RemoteProfile>>>? touchLastLoginCompleters,
  })  : _touchLastLoginCompleters = touchLastLoginCompleters ??
            <Completer<RepositoryResult<RemoteProfile>>>[],
        super(
          client: SupabaseClient(
            'https://example.com',
            'anon-key',
          ),
        );

  final List<Completer<RepositoryResult<RemoteProfile>>>
      _touchLastLoginCompleters;
  int fetchCalls = 0;
  int ensureCalls = 0;
  int upsertCalls = 0;
  int touchLastLoginCalls = 0;
  int touchLastSeenCalls = 0;
  int authoritativeLoadCalls = 0;

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    fetchCalls += 1;
    return RepositoryResult<RemoteProfile?>.success(
      data: _remoteProfile('user-1'),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> ensureCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    ensureCalls += 1;
    return RepositoryResult<RemoteProfile>.success(
      data: _remoteProfile('user-1'),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> upsertCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    upsertCalls += 1;
    return RepositoryResult<RemoteProfile>.success(
      data: _remoteProfile('user-1'),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> touchLastLogin({
    DateTime? at,
  }) {
    touchLastLoginCalls += 1;
    if (_touchLastLoginCompleters.isNotEmpty) {
      return _touchLastLoginCompleters.removeAt(0).future;
    }
    return Future<RepositoryResult<RemoteProfile>>.value(
      RepositoryResult<RemoteProfile>.success(
        data: _remoteProfile('user-1'),
      ),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> touchLastSeen({
    DateTime? at,
  }) {
    touchLastSeenCalls += 1;
    return Future<RepositoryResult<RemoteProfile>>.value(
      RepositoryResult<RemoteProfile>.success(
        data: _remoteProfile('user-1'),
      ),
    );
  }

  @override
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) {
    authoritativeLoadCalls += 1;
    return Future<AuthoritativeBootstrapDecisionLoadResult>.value(
      AuthoritativeBootstrapDecisionLoadResult(
        decision: AuthoritativeBootstrapDecision(
          userId: 'user-1',
          decision: AuthoritativeBootstrapDestination.home,
          accountStatus: BootstrapAccountStatus.active,
          profileState: BootstrapProfileState.ready,
          onboardingStatus: OnboardingStatus.completed,
          completedOnboardingVersion: 1,
          requiredOnboardingVersion: 1,
          onboardingEnforcement: BootstrapOnboardingEnforcement.required,
          onboardingCompletedAt: DateTime.utc(2026, 7, 28),
          profileRevision: 3,
          policyRevision: 2,
        ),
        totalDuration: const Duration(milliseconds: 5),
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: const Duration(milliseconds: 3),
        mapDuration: const Duration(milliseconds: 2),
        remoteCallCount: 1,
        payloadColumnCount: 11,
      ),
    );
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

RemoteProfile _remoteProfile(String id) {
  return RemoteProfile(
    id: id,
    email: 'hidden@example.com',
    displayName: 'Rutio User',
    onboardingStatus: OnboardingStatus.completed,
    onboardingVersion: 1,
    onboardingCompletedAt: DateTime.utc(2026, 7, 28),
  );
}
