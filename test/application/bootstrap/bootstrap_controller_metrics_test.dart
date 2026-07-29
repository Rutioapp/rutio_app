import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/auth/auth_controller.dart';
import 'package:rutio/application/bootstrap/bootstrap_controller.dart';
import 'package:rutio/data/local/authoritative_bootstrap_cache_v2.dart';
import 'package:rutio/data/local/user_state_storage.dart';
import 'package:rutio/data/models/remote/authoritative_bootstrap_decision.dart';
import 'package:rutio/data/models/remote/remote_profile.dart';
import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/data/repositories/profile_repository.dart';
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
      final firstProfile = Completer<BootstrapProfileDecisionLoadResult>();
      final fixture = _MetricsFixture(profileCompleter: firstProfile);

      fixture.resolveUser('user-1');
      await fixture.pump();

      fixture.profile.completer = null;
      fixture.profile.result = _ProfileResult.completed;
      fixture.resolveUser('user-2');
      await fixture.pump();

      firstProfile.complete(
        BootstrapProfileDecisionLoadResult(
          result: RepositoryResult<BootstrapProfileDecision?>.success(
            data: BootstrapProfileDecision(
              userId: 'user-1',
              onboardingStatus: OnboardingStatus.completed,
              onboardingVersion: 1,
              onboardingCompletedAt: DateTime.utc(2026, 7, 28),
            ),
          ),
          totalDuration: const Duration(milliseconds: 3),
          inflightWaitDuration: Duration.zero,
          remoteQueryDuration: const Duration(milliseconds: 2),
          mapDuration: const Duration(milliseconds: 1),
          remoteCallCount: 1,
          payloadColumnCount: 4,
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
              '[Bootstrap] run=1 stale_result_discarded domain=authoritative_bootstrap'),
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

    test('normal bootstrap performs a single authoritative fetch call',
        () async {
      final fixture = _MetricsFixture();

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(fixture.profile.authoritativeLoadCalls, 1);
    });

    test('authoritative decision metrics reflect one remote query', () async {
      final fixture = _MetricsFixture();

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(
        fixture.logs.singleWhere(
          (line) => line.contains('metric=authoritative_bootstrap_calls'),
        ),
        contains('count=1'),
      );
      expect(
        fixture.logs.singleWhere(
          (line) =>
              line.contains('metric=authoritative_bootstrap_payload_columns'),
        ),
        contains('count=11'),
      );
    });

    test('authoritative cache shadow reads compares and rewrites home', () async {
      final fixture = _MetricsFixture();
      final userId = 'user-1234567890';
      await fixture.authoritativeBootstrapCache.write(
        AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
          decision: AuthoritativeBootstrapDecision(
            userId: userId,
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
          environmentId: 'test-supabase-url',
          scopeKey: '$userId|$userId|0',
          cachedAt: DateTime.utc(2026, 7, 28, 10),
        ),
      );

      fixture.resolveUser(userId);
      await fixture.pump();

      expect(
        fixture.logs.any(
          (line) =>
              line.contains('authoritative_cache_v2_read_started') &&
              line.contains('run=1'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('authoritative_cache_v2_result status=hit'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) => line.contains(
            'authoritative_cache_v2_comparison kind=matchHome',
          ),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('authoritative_cache_v2_write_result status=success'),
        ),
        isTrue,
      );
      expect(fixture.authoritativeBootstrapCache.peek(userId), isNotNull);
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
    });

    test('stale cache read is discarded after a newer run starts', () async {
      final cache = _BlockingAuthoritativeBootstrapCache();
      final fixture = _MetricsFixture(authoritativeBootstrapCache: cache);
      final userOne = 'user-1234567890';
      final userTwo = 'user-0987654321';
      final pendingRead = Completer<AuthoritativeBootstrapCacheReadResultV2>();
      cache.readCompleter = pendingRead;

      await cache.write(
        AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
          decision: AuthoritativeBootstrapDecision(
            userId: userOne,
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
          environmentId: 'test-supabase-url',
          scopeKey: '$userOne|$userOne|0',
          cachedAt: DateTime.utc(2026, 7, 28, 10),
        ),
      );

      fixture.resolveUser(userOne);
      await fixture.pump();

      fixture.resolveUser(userTwo);
      await fixture.pump();
      pendingRead.complete(
        const AuthoritativeBootstrapCacheReadResultV2.notFound(),
      );
      await fixture.pump();

      expect(
        fixture.logs.any(
          (line) => line.contains('authoritative_cache_v2_stale_read_discard'),
        ),
        isTrue,
      );
      expect(fixture.bootstrap.state.destination, BootstrapDestination.home);
      expect(cache.peek(userOne), isNotNull);
      expect(cache.peek(userTwo), isNotNull);
    });

    test('home metrics include essential_total and time_to_home_ready',
        () async {
      final fixture = _MetricsFixture();

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(
        fixture.logs.any(
          (line) =>
              line.contains('[BootstrapPerf] run=1 metric=time_to_home_ready'),
        ),
        isTrue,
      );
      expect(
        fixture.logs.any(
          (line) =>
              line.contains('[BootstrapPerf] run=1 metric=essential_total'),
        ),
        isTrue,
      );
    });

    test('subspans are emitted once with query counters', () async {
      final fixture = _MetricsFixture();

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(
        fixture.logs
            .where((line) => line.contains('metric=essential_habits_fetch'))
            .length,
        1,
      );
      expect(
        fixture.logs.singleWhere(
          (line) => line.contains('metric=essential_logs_batch'),
        ),
        contains('queries=1'),
      );
      expect(
        fixture.logs
            .where((line) => line.contains('metric=cosmetics_remote_fetch'))
            .length,
        1,
      );
    });

    test('confirmed-empty habits emit zero log batch queries', () async {
      final fixture = _MetricsFixture(
        habitsPreparer: _FakeEssentialHabitsPreparer(
          status: EssentialHabitsBootstrapStatus.confirmedEmpty,
        ),
      );

      fixture.resolveUser('user-1234567890');
      await fixture.pump();

      expect(
        fixture.logs.singleWhere(
          (line) => line.contains('metric=essential_logs_batch'),
        ),
        contains('queries=0'),
      );
    });
  });
}

class _MetricsFixture {
  _MetricsFixture({
    InMemoryAuthoritativeBootstrapCacheV2? authoritativeBootstrapCache,
    _ProfileResult profileResult = _ProfileResult.completed,
    Completer<BootstrapProfileDecisionLoadResult>? profileCompleter,
    BootstrapProfileDecisionLoadResult? profileLoadResultOverride,
    bool enableBackgroundProfileSync = false,
    PostHomeBootstrapTaskRunner? postHomeBootstrapTaskRunner,
    Completer<RepositoryResult<RemoteProfile?>>? postHomeFetchProfileCompleter,
    Completer<RepositoryResult<RemoteProfile>>? postHomeTouchLastLoginCompleter,
    _FakeEssentialHabitsPreparer? habitsPreparer,
    _FakeEssentialCosmeticsPreparer? cosmeticsPreparer,
  })  : authStream = StreamController<AuthState>.broadcast(sync: true),
        userStore = _FakeUserStateStore(localOnboardingDone: true),
        wallet = _FakeGlobalWalletController(),
        authoritativeBootstrapCache =
            authoritativeBootstrapCache ?? InMemoryAuthoritativeBootstrapCacheV2(),
        profile = _FakeProfileRepository(
          result: profileResult,
          completer: profileCompleter,
          loadResultOverride: profileLoadResultOverride,
        ),
        authProfile = _FakeAuthProfileRepository(
          fetchCurrentProfileCompleter: postHomeFetchProfileCompleter,
          touchLastLoginCompleter: postHomeTouchLastLoginCompleter,
        ) {
    auth = AuthController(
      AuthRepository(
        authStateChangesProvider: () => authStream.stream,
        currentUserProvider: () => currentUser,
      ),
      userStateStore: userStore,
      globalWalletController: wallet,
      profileRepository: authProfile,
      enableBackgroundProfileSync: enableBackgroundProfileSync,
      postHomeBootstrapTaskRunner: postHomeBootstrapTaskRunner,
      debugLogger: logs.add,
    );
    bootstrap = BootstrapController(
      authController: auth,
      userStateStore: userStore,
      profileRepository: profile,
      authoritativeBootstrapCache: this.authoritativeBootstrapCache,
      authoritativeBootstrapEnvironmentId: 'test-supabase-url',
      essentialHabitsPreparer: habitsPreparer ?? _FakeEssentialHabitsPreparer(),
      essentialCosmeticsPreparer:
          cosmeticsPreparer ?? _FakeEssentialCosmeticsPreparer(),
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
  final InMemoryAuthoritativeBootstrapCacheV2 authoritativeBootstrapCache;
  final _FakeProfileRepository profile;
  final _FakeAuthProfileRepository authProfile;
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

class _FakeAuthProfileRepository extends ProfileRepository {
  _FakeAuthProfileRepository({
    this.fetchCurrentProfileCompleter,
    this.touchLastLoginCompleter,
  }) : super(
          client: SupabaseClient(
            'https://example.com',
            'anon-key',
          ),
        );

  final Completer<RepositoryResult<RemoteProfile?>>?
      fetchCurrentProfileCompleter;
  final Completer<RepositoryResult<RemoteProfile>>? touchLastLoginCompleter;

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    final pending = fetchCurrentProfileCompleter;
    if (pending != null) {
      return pending.future;
    }
    return RepositoryResult<RemoteProfile?>.success(
      data: _profile('user-1234567890', OnboardingStatus.completed),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> ensureCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    return RepositoryResult<RemoteProfile>.success(
      data: _profile('user-1234567890', OnboardingStatus.completed),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> touchLastLogin({
    DateTime? at,
  }) {
    final pending = touchLastLoginCompleter;
    if (pending != null) {
      return pending.future;
    }
    return Future<RepositoryResult<RemoteProfile>>.value(
      RepositoryResult<RemoteProfile>.success(
        data: _profile('user-1234567890', OnboardingStatus.completed),
      ),
    );
  }

  @override
  Future<RepositoryResult<RemoteProfile>> touchLastSeen({
    DateTime? at,
  }) {
    return Future<RepositoryResult<RemoteProfile>>.value(
      RepositoryResult<RemoteProfile>.success(
        data: _profile('user-1234567890', OnboardingStatus.completed),
      ),
    );
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
    this.loadResultOverride,
  });

  _ProfileResult result;
  Completer<BootstrapProfileDecisionLoadResult>? completer;
  BootstrapProfileDecisionLoadResult? loadResultOverride;
  String currentFetchUserId = 'user-1';
  int fetchCalls = 0;
  int authoritativeLoadCalls = 0;

  @override
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) {
    authoritativeLoadCalls += 1;
    final pending = completer;
    if (pending != null) {
      return pending.future.then(_authoritativeFromBootstrapResult);
    }
    final override = loadResultOverride;
    if (override != null) {
      return Future.value(_authoritativeFromBootstrapResult(override));
    }
    switch (result) {
      case _ProfileResult.completed:
        return Future.value(
          _authoritativeResult(
            decision: AuthoritativeBootstrapDestination.home,
          ),
        );
      case _ProfileResult.network:
        return Future.value(
          const AuthoritativeBootstrapDecisionLoadResult(
            decision: null,
            error: AuthoritativeBootstrapDecisionReadException(
              code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
              message: 'network',
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 11,
          ),
        );
    }
  }

  @override
  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) {
    fetchCalls += 1;
    final pending = completer;
    if (pending != null) return pending.future;
    final override = loadResultOverride;
    if (override != null) {
      return Future<BootstrapProfileDecisionLoadResult>.value(override);
    }
    switch (result) {
      case _ProfileResult.completed:
        return Future<BootstrapProfileDecisionLoadResult>.value(
          BootstrapProfileDecisionLoadResult(
            result: RepositoryResult<BootstrapProfileDecision?>.success(
              data: BootstrapProfileDecision(
                userId: currentFetchUserId,
                onboardingStatus: OnboardingStatus.completed,
                onboardingVersion: 1,
                onboardingCompletedAt: DateTime.utc(2026, 7, 28),
              ),
            ),
            totalDuration: const Duration(milliseconds: 3),
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: const Duration(milliseconds: 2),
            mapDuration: const Duration(milliseconds: 1),
            remoteCallCount: 1,
            payloadColumnCount: 4,
          ),
        );
      case _ProfileResult.network:
        return Future<BootstrapProfileDecisionLoadResult>.value(
          const BootstrapProfileDecisionLoadResult(
            result: RepositoryResult<BootstrapProfileDecision?>.failure(
              RepositoryError(
                code: RepositoryErrorCode.network,
                message: 'network',
              ),
            ),
            totalDuration: Duration.zero,
            inflightWaitDuration: Duration.zero,
            remoteQueryDuration: Duration.zero,
            mapDuration: Duration.zero,
            remoteCallCount: 1,
            payloadColumnCount: 4,
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

  @override
  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  }) async {}

  AuthoritativeBootstrapDecisionLoadResult _authoritativeFromBootstrapResult(
    BootstrapProfileDecisionLoadResult result,
  ) {
    final profileResult = result.result;
    if (!profileResult.isSuccess || profileResult.data == null) {
      return const AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: AuthoritativeBootstrapDecisionReadException(
          code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
          message: 'empty',
        ),
        totalDuration: Duration.zero,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 1,
        payloadColumnCount: 11,
      );
    }
    final profile = profileResult.data!;
    return _authoritativeResult(
      decision: profile.onboardingStatus == OnboardingStatus.completed
          ? AuthoritativeBootstrapDestination.home
          : AuthoritativeBootstrapDestination.onboarding,
      userId: profile.userId,
    );
  }

  AuthoritativeBootstrapDecisionLoadResult _authoritativeResult({
    required AuthoritativeBootstrapDestination decision,
    String? userId,
  }) {
    final resolvedUserId = userId ?? currentFetchUserId;
    return AuthoritativeBootstrapDecisionLoadResult(
      decision: AuthoritativeBootstrapDecision(
        userId: resolvedUserId,
        decision: decision,
        accountStatus: BootstrapAccountStatus.active,
        profileState: BootstrapProfileState.ready,
        onboardingStatus: decision == AuthoritativeBootstrapDestination.home
            ? OnboardingStatus.completed
            : OnboardingStatus.pending,
        completedOnboardingVersion:
            decision == AuthoritativeBootstrapDestination.home ? 1 : null,
        requiredOnboardingVersion: 1,
        onboardingEnforcement: BootstrapOnboardingEnforcement.required,
        onboardingCompletedAt:
            decision == AuthoritativeBootstrapDestination.home
                ? DateTime.utc(2026, 7, 28)
                : null,
        profileRevision: 3,
        policyRevision: 2,
      ),
      totalDuration: const Duration(milliseconds: 3),
      inflightWaitDuration: Duration.zero,
      remoteQueryDuration: const Duration(milliseconds: 2),
      mapDuration: const Duration(milliseconds: 1),
      remoteCallCount: 1,
      payloadColumnCount: 11,
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
  _FakeEssentialHabitsPreparer({
    this.status = EssentialHabitsBootstrapStatus.readyFromRemote,
  });

  final EssentialHabitsBootstrapStatus status;

  @override
  Future<EssentialHabitsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) {
    return Future<EssentialHabitsBootstrapResult>.value(
      EssentialHabitsBootstrapResult(
        status: status,
        userId: userId,
        source: status == EssentialHabitsBootstrapStatus.confirmedEmpty
            ? 'confirmed_empty'
            : 'remote',
        scopeEpoch: 1,
        requestId: 1,
        duration: const Duration(milliseconds: 4),
        remoteQueryCount:
            status == EssentialHabitsBootstrapStatus.confirmedEmpty ? 1 : 3,
        operationDurations: <String, Duration>{
          'essential_habits_fetch': const Duration(milliseconds: 2),
          'essential_logs_batch': Duration.zero,
          'habits_logs_merge': const Duration(milliseconds: 1),
          'missed_occurrences_close': Duration.zero,
          'habit_timezone': Duration.zero,
          'streak_shields_fetch': Duration.zero,
          'streak_breaks_fetch': Duration.zero,
          'streak_reconciliation': Duration.zero,
          'habits_persist': const Duration(milliseconds: 1),
        },
        operationQueryCounts: <String, int>{
          'essential_habits_fetch': 1,
          'essential_logs_batch':
              status == EssentialHabitsBootstrapStatus.confirmedEmpty ? 0 : 1,
          'missed_occurrences_close': 0,
          'habit_timezone': 0,
          'streak_shields_fetch': 0,
          'streak_breaks_fetch': 0,
        },
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
        operationDurations: <String, Duration>{
          'cosmetics_cache_read': const Duration(milliseconds: 1),
          'cosmetics_remote_fetch': const Duration(milliseconds: 3),
          'cosmetics_resolve_visible': const Duration(milliseconds: 1),
        },
        operationQueryCounts: const <String, int>{
          'cosmetics_remote_fetch': 1,
        },
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

class _BlockingAuthoritativeBootstrapCache
    extends InMemoryAuthoritativeBootstrapCacheV2 {
  Completer<AuthoritativeBootstrapCacheReadResultV2>? readCompleter;

  @override
  Future<AuthoritativeBootstrapCacheReadResultV2> read(
    String userId, {
    required String expectedScopeKey,
  }) {
    final pending = readCompleter;
    if (pending != null) {
      return pending.future;
    }
    return super.read(
      userId,
      expectedScopeKey: expectedScopeKey,
    );
  }
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
