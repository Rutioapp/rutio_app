import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/application/bootstrap/bootstrap_controller.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_state_repository.dart';
import 'package:rutio/data/services/journal_entry_sync_service.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_controller.dart';
import 'package:rutio/features/global_wallet/application/global_wallet_state.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_errors.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_repository.dart';
import 'package:rutio/features/global_wallet/data/cloud/cloud_wallet_snapshot.dart';
import 'package:rutio/features/global_wallet/data/cloud/wallet_cache.dart';
import 'package:rutio/features/shop/application/shop_cosmetics_controller.dart';
import 'package:rutio/features/shop/domain/models/shop_asset.dart';
import 'package:rutio/stores/user_state_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BootstrapController metrics', () {
    test('logs total metric, sources and preserves bootstrap result', () async {
      final fixture = _MetricsFixture();

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('[BootstrapPerf] run=1 metric=essential_habits') &&
              line.contains('source=remote'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains(
                  '[BootstrapPerf] run=1 metric=essential_cosmetics') &&
              line.contains('source=remote'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('[BootstrapPerf] run=1 metric=total') &&
              line.contains('mode=cold_start') &&
              line.contains('habits_source=remote') &&
              line.contains('cosmetics_source=remote') &&
              line.contains('habits_cosmetics_parallel=true'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('[BootstrapTimeline] run=1 event=home_published'),
        ),
        isTrue,
      );
    });

    test('retry produces separate metric runs', () async {
      final fixture = _MetricsFixture(profileResult: _ProfileResult.network);

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      fixture.profile.result = _ProfileResult.completed;
      await fixture.bootstrap.retry();
      await fixture.pump();

      final totals = fixture.logs
          .where((line) =>
              line.contains('[BootstrapPerf]') && line.contains('metric=total'))
          .toList();
      expect(totals.length, 2);
      expect(totals[0], contains('run=1'));
      expect(totals[1], contains('run=2'));
    });

    test('stale run does not emit final total metric', () async {
      final firstProfile = Completer<RepositoryResult<RemoteProfile?>>();
      final fixture = _MetricsFixture(profileCompleter: firstProfile);

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.profile.completer = null;
      fixture.profile.result = _ProfileResult.completed;
      fixture.resolveUser('user-2');
      await fixture.pump();

      firstProfile.complete(
        RepositoryResult<RemoteProfile?>.success(
          data: _profile('user-1', OnboardingStatus.completed),
        ),
      );
      await fixture.pump();

      final totals = fixture.logs
          .where((line) =>
              line.contains('[BootstrapPerf]') && line.contains('metric=total'))
          .toList();
      expect(totals.length, 1);
      expect(totals.single, contains('run=2'));
      expect(
        fixture.logs.any(
          (line) => line.contains(
              '[Bootstrap] run=1 stale_result_discarded domain=profile'),
        ),
        isTrue,
      );
    });

    test('logs stay sanitized from tokens, emails and full user ids', () async {
      final fixture = _MetricsFixture();
      const userId = 'user-1234567890';

      fixture.resolveUser(userId);
      await fixture.pump();

      final joined = fixture.logs.join('\n');
      expect(joined.contains('access-token'), isFalse);
      expect(joined.contains('@'), isFalse);
      expect(joined.contains(userId), isFalse);
    });
  });
}

class _MetricsFixture {
  _MetricsFixture({
    _ProfileResult profileResult = _ProfileResult.completed,
    Completer<RepositoryResult<RemoteProfile?>>? profileCompleter,
  })  : authStream = StreamController<AuthState>.broadcast(sync: true),
        userStore = _FakeUserStateStore(localOnboardingDone: true),
        wallet = _FakeGlobalWalletController(),
        profile = _FakeProfileRepository(
          result: profileResult,
          completer: profileCompleter,
        ) {
    auth = AuthController(
      AuthRepository(
        authStateChangesProvider: () => authStream.stream,
        currentUserProvider: () => currentUser,
      ),
      userStateStore: userStore,
      globalWalletController: wallet,
      profileRepository: null,
      enableBackgroundProfileSync: false,
    );
    bootstrap = BootstrapController(
      authController: auth,
      userStateStore: userStore,
      profileRepository: profile,
      essentialHabitsPreparer: _FakeEssentialHabitsPreparer(),
      essentialCosmeticsPreparer: _FakeEssentialCosmeticsPreparer(),
      essentialAssetPreloader: _FakeEssentialAssetPreloader(),
      debugLogger: logs.add,
    );
    addTearDown(() async {
      bootstrap.dispose();
      auth.dispose();
      await authStream.close();
    });
  }

  final StreamController<AuthState> authStream;
  final _FakeUserStateStore userStore;
  final _FakeGlobalWalletController wallet;
  final _FakeProfileRepository profile;
  final List<String> logs = <String>[];
  late final AuthController auth;
  late final BootstrapController bootstrap;
  User? currentUser;

  void resolveUser(String id) {
    currentUser = _user(id);
    profile.currentFetchUserId = id;
    authStream
        .add(AuthState(AuthChangeEvent.initialSession, _session(_user(id))));
  }

  Future<void> pump() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }
}

enum _ProfileResult {
  completed,
  network,
}

class _FakeProfileRepository implements BootstrapProfileRepository {
  _FakeProfileRepository({
    required this.result,
    this.completer,
  });

  _ProfileResult result;
  Completer<RepositoryResult<RemoteProfile?>>? completer;
  String currentFetchUserId = 'user-1';

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() {
    final pending = completer;
    if (pending != null) return pending.future;
    switch (result) {
      case _ProfileResult.completed:
        return Future<RepositoryResult<RemoteProfile?>>.value(
          RepositoryResult<RemoteProfile?>.success(
            data: _profile(currentFetchUserId, OnboardingStatus.completed),
          ),
        );
      case _ProfileResult.network:
        return Future<RepositoryResult<RemoteProfile?>>.value(
          const RepositoryResult<RemoteProfile?>.failure(
            RepositoryError(
              code: RepositoryErrorCode.network,
              message: 'network',
            ),
          ),
        );
    }
  }

  @override
  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) {
    return Future<RepositoryResult<RemoteProfile>>.value(
      RepositoryResult<RemoteProfile>.success(
        data: _profile(currentFetchUserId, OnboardingStatus.completed),
      ),
    );
  }
}

class _FakeUserStateStore extends UserStateStore {
  _FakeUserStateStore({
    required bool localOnboardingDone,
  })  : _localOnboardingDone = localOnboardingDone,
        super(
          UserStateRepository(storage: UserStateStorage()),
          journalEntrySyncService: JournalEntrySyncService(),
        );

  final bool _localOnboardingDone;
  String? _scopeUserId;
  Map<String, dynamic>? _fakeState;

  @override
  Map<String, dynamic>? get state => _fakeState;

  @override
  bool get isLoading => false;

  @override
  String? get activeLocalScopeUserId => _scopeUserId;

  @override
  bool get onboardingDone => _localOnboardingDone;

  @override
  String? get userId => _scopeUserId;

  @override
  Future<void> switchLocalScope({
    String? userId,
    bool forceReload = false,
  }) async {
    _scopeUserId = userId;
    _fakeState = <String, dynamic>{
      'userState': <String, dynamic>{
        if (userId != null) 'userId': userId,
        'meta': <String, dynamic>{'onboardingDone': _localOnboardingDone},
      },
    };
  }

  @override
  Future<void> load() async {
    _fakeState ??= <String, dynamic>{
      'userState': <String, dynamic>{
        if (_scopeUserId != null) 'userId': _scopeUserId,
        'meta': <String, dynamic>{'onboardingDone': _localOnboardingDone},
      },
    };
  }

  @override
  void restoreGamificationOverlaysAfterLogout() {}

  @override
  void suppressGamificationOverlaysDuringLogout() {}
}

class _FakeGlobalWalletController extends GlobalWalletController {
  _FakeGlobalWalletController()
      : super(
          repository: _NoopCloudWalletRepository(),
          cache: _NoopWalletCache(),
          enabled: true,
        );

  @override
  Future<GlobalWalletState> syncSession({
    String? userId,
    bool force = false,
  }) async {
    return GlobalWalletState.unauthenticated();
  }

  @override
  Future<GlobalWalletState> clearSession() async {
    return GlobalWalletState.unauthenticated();
  }
}

class _FakeEssentialHabitsPreparer implements BootstrapEssentialHabitsPreparer {
  @override
  Future<EssentialHabitsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) {
    return Future<EssentialHabitsBootstrapResult>.value(
      EssentialHabitsBootstrapResult(
        status: EssentialHabitsBootstrapStatus.readyFromRemote,
        userId: userId,
        source: 'remote',
        scopeEpoch: 1,
        requestId: 1,
        duration: const Duration(milliseconds: 4),
        remoteQueryCount: 3,
      ),
    );
  }
}

class _FakeEssentialCosmeticsPreparer
    implements BootstrapEssentialCosmeticsPreparer {
  @override
  Future<CosmeticsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) {
    return Future<CosmeticsBootstrapResult>.value(
      CosmeticsBootstrapResult(
        status: CosmeticsBootstrapStatus.readyFromRemote,
        userId: userId,
        source: 'remote',
        requestId: 1,
        duration: const Duration(milliseconds: 5),
        remoteQueryCount: 1,
        appliedRevision: 1,
        readyToken: createReadyToken(userId: userId),
      ),
    );
  }

  @override
  CosmeticsReadyToken? createReadyToken({required String userId}) {
    return CosmeticsReadyToken(
      controllerIdentity: 1,
      userId: userId,
      scope: userId,
      appliedRevision: 1,
      equippedWallpaperId: 'wallpaper_mist_blue',
      equippedHabitCardId: 'habit_card_soft_sage',
      equippedUserCardId: 'user_card_full_moon',
      wallpaperResolved: true,
      habitCardResolved: true,
      userCardResolved: true,
    );
  }

  @override
  bool validateReadyToken(CosmeticsReadyToken token) => true;
}

class _FakeEssentialAssetPreloader implements BootstrapEssentialAssetPreloader {
  @override
  Future<void> preload(Iterable<ShopAsset> assets) async {}
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

RemoteProfile _profile(String id, OnboardingStatus status) {
  return RemoteProfile(
    id: id,
    email: 'hidden@example.com',
    displayName: 'Rutio User',
    onboardingStatus: status,
    onboardingVersion: 1,
    onboardingCompletedAt:
        status == OnboardingStatus.completed ? DateTime.utc(2026, 7, 27) : null,
  );
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
    userMetadata: const <String, dynamic>{},
    aud: 'authenticated',
    createdAt: '2026-07-27T00:00:00Z',
  );
}
