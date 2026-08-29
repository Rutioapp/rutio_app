import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_config.dart';
import '../../data/local/authoritative_bootstrap_cache_v2.dart';
import '../../data/models/remote/authoritative_bootstrap_decision.dart';
import '../../data/models/remote/remote_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/repository_result.dart';
import '../../devtools/rutio_runtime_profile.dart';
import 'authoritative_bootstrap_cache_shadow.dart';
import '../../features/shop/application/shop_cosmetics_controller.dart';
import '../../features/shop/domain/models/shop_asset.dart';
import '../../stores/user_state_store.dart';
import '../auth/auth_controller.dart';

enum BootstrapRunMode {
  coldStart,
  inAppBootstrap,
}

typedef BootstrapDebugLogger = void Function(String message);
typedef BootstrapHomeReadyCallback = Future<void> Function(
  BootstrapHomeEssentialReady ready,
);

class _BootstrapRunTelemetry {
  _BootstrapRunTelemetry({
    required this.runId,
    required this.mode,
    required this.startedAt,
  });

  final int runId;
  final BootstrapRunMode mode;
  final DateTime startedAt;
  int remoteQueriesExecuted = 0;
  int deduplicatedLoads = 0;
  int staleResultsDiscarded = 0;
  String habitsSource = 'unknown';
  String cosmeticsSource = 'unknown';
  bool habitsAndCosmeticsParallel = false;
}

@immutable
class BootstrapHomeEssentialReady {
  const BootstrapHomeEssentialReady({
    required this.userId,
    required this.scopeUserId,
    required this.scopeEpoch,
    required this.remoteProfile,
    required this.localStateLoaded,
    required this.habitsAndLogsReconciled,
    required this.streakProtectionReconciled,
    required this.effectiveTimeZoneResolved,
    required this.visibleCosmeticsResolved,
    required this.visibleAssetsPreloaded,
    required this.cosmeticsReadyToken,
  });

  final String userId;
  final String scopeUserId;
  final int scopeEpoch;
  final RemoteProfile remoteProfile;
  final bool localStateLoaded;
  final bool habitsAndLogsReconciled;
  final bool streakProtectionReconciled;
  final bool effectiveTimeZoneResolved;
  final bool visibleCosmeticsResolved;
  final bool visibleAssetsPreloaded;
  final CosmeticsReadyToken cosmeticsReadyToken;
}

abstract class BootstrapProfileRepository {
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  });

  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  });

  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  });

  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  });
}

class ProfileBootstrapRepository implements BootstrapProfileRepository {
  const ProfileBootstrapRepository(this._repository);

  final ProfileRepository _repository;

  @override
  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) =>
          _repository.loadAuthoritativeBootstrapDecision(
            scopeUserId: scopeUserId,
            scopeEpoch: scopeEpoch,
            onboardingPolicyVersion: onboardingPolicyVersion,
          );

  @override
  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
  }) =>
      _repository.fetchBootstrapProfileDecision(
        scopeUserId: scopeUserId,
        scopeEpoch: scopeEpoch,
        onboardingPolicyVersion: onboardingPolicyVersion,
      );

  @override
  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) =>
      _repository.markOnboardingCompleted(
        onboardingVersion: onboardingVersion,
      );

  @override
  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion =
        ProfileRepository.bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  }) {
    return _repository.storeBootstrapProfileDecisionFromRemoteProfileInMemory(
      profile: profile,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      source: source,
      expectedUserId: expectedUserId,
    );
  }
}

abstract class BootstrapEssentialHabitsPreparer {
  Future<EssentialHabitsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  });
}

class UserStateBootstrapEssentialHabitsPreparer
    implements BootstrapEssentialHabitsPreparer {
  const UserStateBootstrapEssentialHabitsPreparer(this._store);

  final UserStateStore _store;

  @override
  Future<EssentialHabitsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) =>
      _store.prepareEssentialHabitsForBootstrap(
        userId: userId,
        forceRemote: forceRemote,
      );
}

abstract class BootstrapEssentialCosmeticsPreparer {
  Future<CosmeticsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  });

  CosmeticsReadyToken? createReadyToken({required String userId});

  bool validateReadyToken(CosmeticsReadyToken token);
}

class ShopBootstrapEssentialCosmeticsPreparer
    implements BootstrapEssentialCosmeticsPreparer {
  const ShopBootstrapEssentialCosmeticsPreparer(this._controller);

  final ShopCosmeticsController _controller;

  @override
  Future<CosmeticsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) =>
      _controller.prepareEssentialCosmeticsForBootstrap(
        userId: userId,
        forceRemote: forceRemote,
      );

  @override
  CosmeticsReadyToken? createReadyToken({required String userId}) =>
      _controller.createReadyTokenForBootstrap(userId: userId);

  @override
  bool validateReadyToken(CosmeticsReadyToken token) =>
      _controller.validateReadyToken(token);
}

class NoopBootstrapCosmeticsPreparer
    implements BootstrapEssentialCosmeticsPreparer {
  const NoopBootstrapCosmeticsPreparer();

  @override
  Future<CosmeticsBootstrapResult> prepare({
    required String userId,
    bool forceRemote = false,
  }) async {
    return CosmeticsBootstrapResult(
      status: CosmeticsBootstrapStatus.confirmedEmpty,
      userId: userId,
      source: 'confirmed_empty',
      requestId: 0,
      duration: Duration.zero,
    );
  }

  @override
  CosmeticsReadyToken? createReadyToken({required String userId}) =>
      CosmeticsReadyToken(
        controllerIdentity: 0,
        userId: userId,
        scope: userId,
        appliedRevision: 0,
        equippedWallpaperId: null,
        equippedHabitCardId: null,
        equippedUserCardId: null,
        wallpaperResolved: true,
        habitCardResolved: true,
        userCardResolved: true,
      );

  @override
  bool validateReadyToken(CosmeticsReadyToken token) => true;
}

abstract class BootstrapEssentialAssetPreloader {
  Future<void> preload(Iterable<ShopAsset> assets);
}

class RootBundleEssentialAssetPreloader
    implements BootstrapEssentialAssetPreloader {
  RootBundleEssentialAssetPreloader({AssetBundle? bundle})
      : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Set<String> _preloadedPaths = <String>{};

  @override
  Future<void> preload(Iterable<ShopAsset> assets) async {
    final paths = <String>{
      for (final asset in assets)
        if (asset.assetPath.trim().isNotEmpty) asset.assetPath.trim(),
    }..removeAll(_preloadedPaths);
    if (paths.isEmpty) return;
    await Future.wait(paths.map((path) async {
      await _bundle.load(path);
      await _precacheImageProvider(buildShopAssetImageProvider(path));
    }));
    _preloadedPaths.addAll(paths);
  }

  Future<void> _precacheImageProvider(ImageProvider<Object> provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (_, __) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete();
      },
      onError: (Object error, StackTrace? stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}

enum BootstrapPhase {
  idle,
  resolvingSession,
  selectingUserScope,
  loadingLocalState,
  loadingRemoteProfile,
  loadingEssentialHabits,
  loadingEssentialCosmetics,
  preloadingEssentialAssets,
  decidingDestination,
  ready,
  failed,
}

enum BootstrapDestination {
  welcome,
  authentication,
  onboarding,
  home,
  profileUninitialized,
  profileDeleted,
  accountSuspended,
  accountPendingDeletion,
  invalidProfile,
}

enum BootstrapErrorType {
  profileNotFound,
  network,
  permissionDenied,
  invalidRemoteResponse,
  staleSession,
  localState,
  essentialHabits,
  essentialCosmetics,
  essentialAssets,
  unknown,
}

@immutable
class BootstrapError {
  const BootstrapError({
    required this.type,
    required this.message,
    this.cause,
  });

  final BootstrapErrorType type;
  final String message;
  final Object? cause;

  bool get canRetry => true;
}

@immutable
class BootstrapState {
  const BootstrapState({
    required this.phase,
    required this.runId,
    this.mode = BootstrapRunMode.coldStart,
    this.user,
    this.remoteProfile,
    this.destination,
    this.error,
    this.cosmeticsReadyToken,
    this.usesOfflinePolicy = false,
  });

  final BootstrapPhase phase;
  final int runId;
  final BootstrapRunMode mode;
  final User? user;
  final RemoteProfile? remoteProfile;
  final BootstrapDestination? destination;
  final BootstrapError? error;
  final CosmeticsReadyToken? cosmeticsReadyToken;
  final bool usesOfflinePolicy;

  bool get isReady => phase == BootstrapPhase.ready && destination != null;
  bool get isFailed => phase == BootstrapPhase.failed;

  BootstrapState copyWith({
    BootstrapPhase? phase,
    int? runId,
    BootstrapRunMode? mode,
    User? user,
    bool clearUser = false,
    RemoteProfile? remoteProfile,
    bool clearRemoteProfile = false,
    BootstrapDestination? destination,
    bool clearDestination = false,
    BootstrapError? error,
    CosmeticsReadyToken? cosmeticsReadyToken,
    bool clearCosmeticsReadyToken = false,
    bool clearError = false,
    bool? usesOfflinePolicy,
  }) {
    return BootstrapState(
      phase: phase ?? this.phase,
      runId: runId ?? this.runId,
      mode: mode ?? this.mode,
      user: clearUser ? null : user ?? this.user,
      remoteProfile:
          clearRemoteProfile ? null : remoteProfile ?? this.remoteProfile,
      destination: clearDestination ? null : destination ?? this.destination,
      error: clearError ? null : error ?? this.error,
      cosmeticsReadyToken: clearCosmeticsReadyToken
          ? null
          : cosmeticsReadyToken ?? this.cosmeticsReadyToken,
      usesOfflinePolicy: usesOfflinePolicy ?? this.usesOfflinePolicy,
    );
  }

  static const initial = BootstrapState(
    phase: BootstrapPhase.idle,
    runId: 0,
    mode: BootstrapRunMode.coldStart,
  );
}

class BootstrapController extends ChangeNotifier {
  static const int _onboardingPolicyVersion =
      ProfileRepository.bootstrapOnboardingPolicyVersion;

  BootstrapController({
    required AuthController authController,
    required UserStateStore userStateStore,
    required BootstrapProfileRepository profileRepository,
    AuthoritativeBootstrapCacheStorageV2? authoritativeBootstrapCache,
    String? authoritativeBootstrapEnvironmentId,
    BootstrapEssentialHabitsPreparer? essentialHabitsPreparer,
    BootstrapEssentialCosmeticsPreparer? essentialCosmeticsPreparer,
    BootstrapEssentialAssetPreloader? essentialAssetPreloader,
    BootstrapHomeReadyCallback? onHomeReady,
    BootstrapDebugLogger? debugLogger,
  })  : _authController = authController,
        _userStateStore = userStateStore,
        _profileRepository = profileRepository,
        _authoritativeBootstrapEnvironmentId =
            _normalizeAuthoritativeBootstrapEnvironmentId(
          authoritativeBootstrapEnvironmentId,
        ),
        _authoritativeBootstrapCache = authoritativeBootstrapCache ??
            SharedPreferencesAuthoritativeBootstrapCacheV2(
              environmentId: RutioSupabaseConfig.supabaseUrl,
            ),
        _essentialHabitsPreparer = essentialHabitsPreparer ??
            UserStateBootstrapEssentialHabitsPreparer(userStateStore),
        _essentialCosmeticsPreparer = essentialCosmeticsPreparer,
        _essentialAssetPreloader =
            essentialAssetPreloader ?? RootBundleEssentialAssetPreloader(),
        _onHomeReady = onHomeReady,
        _debugLogger = debugLogger ?? debugPrint {
    _trace(0, 'controller_created');
    _authController.addListener(_handleAuthChanged);
    unawaited(start());
  }

  final AuthController _authController;
  final UserStateStore _userStateStore;
  final BootstrapProfileRepository _profileRepository;
  final String _authoritativeBootstrapEnvironmentId;
  final AuthoritativeBootstrapCacheStorageV2 _authoritativeBootstrapCache;
  final BootstrapEssentialHabitsPreparer _essentialHabitsPreparer;
  final BootstrapEssentialCosmeticsPreparer? _essentialCosmeticsPreparer;
  final BootstrapEssentialAssetPreloader _essentialAssetPreloader;
  final BootstrapHomeReadyCallback? _onHomeReady;
  final BootstrapDebugLogger _debugLogger;

  BootstrapState _state = BootstrapState.initial;
  int _nextRunId = 0;
  String? _lastResolvedUserId;
  bool _isCompletingTemporaryOnboarding = false;
  bool _hasStartedInitialBootstrap = false;
  final Map<int, _BootstrapRunTelemetry> _telemetryByRunId =
      <int, _BootstrapRunTelemetry>{};

  BootstrapState get state => _state;

  Future<void> start() => _run(mode: _consumeNextRunMode());

  Future<void> retry() => _run(mode: BootstrapRunMode.inAppBootstrap);

  void logColdStartSplashShown() {
    _log(_state.runId, 'cold_start_showing_splash');
  }

  void logPreparingScreenShown() {
    _log(_state.runId, 'showing_preparing_screen');
  }

  Future<void> completeTemporaryOnboarding() async {
    if (_isCompletingTemporaryOnboarding) return;
    final startedAt = DateTime.now();
    final runId = _state.runId;
    final userId = _state.user?.id;
    final profile = _state.remoteProfile;
    if (userId == null || profile == null) {
      _setState(
        _state.copyWith(
          phase: BootstrapPhase.failed,
          error: const BootstrapError(
            type: BootstrapErrorType.staleSession,
            message:
                'No hemos podido confirmar tu sesión. Vuelve a intentarlo.',
          ),
        ),
      );
      return;
    }

    _isCompletingTemporaryOnboarding = true;
    try {
      _setState(
        _state.copyWith(
          phase: BootstrapPhase.decidingDestination,
          mode: BootstrapRunMode.inAppBootstrap,
        ),
      );
      final result = await _profileRepository.markOnboardingCompleted(
        onboardingVersion: profile.onboardingVersion,
      );
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != userId) {
        return;
      }

      if (!result.isSuccess || result.data == null) {
        _fail(runId, _errorFromRepository(result.error));
        return;
      }

      final completed = result.data!;
      await _profileRepository
          .storeBootstrapProfileDecisionFromRemoteProfileInMemory(
        profile: completed,
        scopeUserId: userId,
        scopeEpoch: _userStateStore.scopeEpoch,
        onboardingPolicyVersion: _onboardingPolicyVersion,
        source: BootstrapProfileDecisionMemorySource.onboardingCompletion,
        expectedUserId: userId,
      );
      if (completed.id != userId ||
          completed.onboardingStatus != OnboardingStatus.completed) {
        _fail(
          runId,
          const BootstrapError(
            type: BootstrapErrorType.invalidRemoteResponse,
            message: 'No hemos podido confirmar el onboarding.',
          ),
        );
        return;
      }

      _log(runId, 'profile_ready status=completed');
      final essentials = await _prepareHomeEssentials(
        runId: runId,
        userId: userId,
        profile: completed,
        startedAt: DateTime.now(),
      );
      if (essentials == null) return;
      final essentialDuration = DateTime.now().difference(startedAt);
      _metric(runId, 'time_to_home_ready', essentialDuration);
      _metric(runId, 'essential_total', essentialDuration);
      final publishStartedAt = DateTime.now();
      _setState(
        BootstrapState(
          phase: BootstrapPhase.ready,
          runId: runId,
          mode: BootstrapRunMode.inAppBootstrap,
          user: _state.user,
          remoteProfile: completed,
          destination: BootstrapDestination.home,
          cosmeticsReadyToken: essentials.cosmeticsReadyToken,
        ),
      );
      _metric(
        runId,
        'home_publish',
        DateTime.now().difference(publishStartedAt),
      );
      _timeline(runId, 'home_published');
      _fireAndForgetHomeReady(essentials);
      _finishRun(runId);
      _authController.startPostHomeBootstrapWork(
        bootstrapRunId: runId,
        userId: essentials.userId,
        scopeUserId: essentials.scopeUserId,
        scopeEpoch: essentials.scopeEpoch,
        bootstrapDecision: completed.toBootstrapProfileDecision(),
      );
      _log(runId, 'destination=home');
    } finally {
      _isCompletingTemporaryOnboarding = false;
    }
  }

  void _handleAuthChanged() {
    final currentUserId = _authController.currentUser?.id;
    final sessionResolved = _authController.isSessionResolved;
    if (!sessionResolved) return;
    _trace(
      _state.runId,
      'auth_stream_event',
      note: 'user=${currentUserId != null}',
    );
    if (_state.mode == BootstrapRunMode.coldStart &&
        _state.phase == BootstrapPhase.resolvingSession &&
        !_state.isReady &&
        !_state.isFailed) {
      return;
    }
    if (currentUserId == _lastResolvedUserId && !_state.isFailed) {
      _trace(
        _state.runId,
        'auth_stream_event',
        note: 'same_user_ignored user=${currentUserId != null}',
      );
      return;
    }
    _log(_state.runId, 'auth_changed user=${currentUserId != null}');
    unawaited(_run(mode: BootstrapRunMode.inAppBootstrap));
  }

  Future<void> _run({required BootstrapRunMode mode}) async {
    final runId = ++_nextRunId;
    final startedAt = DateTime.now();
    _telemetryByRunId[runId] = _BootstrapRunTelemetry(
      runId: runId,
      mode: mode,
      startedAt: startedAt,
    );
    _lastResolvedUserId = _authController.currentUser?.id;
    _setState(
      BootstrapState(
        phase: BootstrapPhase.resolvingSession,
        runId: runId,
        mode: mode,
      ),
    );
    _log(runId,
        'mode=${mode == BootstrapRunMode.coldStart ? 'cold_start' : 'in_app'}');
    _trace(
      runId,
      'auth_initial_value',
      note:
          'mode=${mode == BootstrapRunMode.coldStart ? 'cold_start' : 'in_app'} user=${_lastResolvedUserId != null}',
    );
    _log(runId, 'phase=resolving_session', startedAt: startedAt);
    _timeline(runId, 'bootstrap_started');

    try {
      final sessionStartedAt = DateTime.now();
      final session = _authController.isSessionResolved
          ? _authController.sessionSnapshot
          : await _authController.initialSessionResolved;
      _metric(
        runId,
        'session_resolution',
        DateTime.now().difference(sessionStartedAt),
      );
      if (!_isCurrentRun(runId)) {
        _recordStaleDiscard(runId, domain: 'session');
        return;
      }

      final user = session.user;
      _lastResolvedUserId = user?.id;
      _log(
        runId,
        'session_resolved user=${user != null}',
        startedAt: startedAt,
      );
      _timeline(runId, 'session_ready');

      if (RutioRuntimeProfile.isDemo || user == null) {
        await _loadGuestStateAndDecide(runId, startedAt);
        return;
      }

      _setState(
        BootstrapState(
          phase: BootstrapPhase.selectingUserScope,
          runId: runId,
          mode: mode,
          user: user,
        ),
      );
      _log(runId, 'phase=selecting_user_scope', startedAt: startedAt);
      _trace(runId, 'scope_change_requested');
      final scopeStartedAt = DateTime.now();
      await _userStateStore.switchLocalScope(userId: user.id);
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        _recordStaleDiscard(runId, domain: 'scope');
        return;
      }
      _metric(
          runId, 'scope_selection', DateTime.now().difference(scopeStartedAt));
      _log(runId, 'scope_selected', startedAt: startedAt);
      _trace(runId, 'scope_change_applied');
      _timeline(runId, 'scope_ready');

      _setState(_state.copyWith(phase: BootstrapPhase.loadingLocalState));
      _log(runId, 'phase=loading_local_state', startedAt: startedAt);
      final localStateStartedAt = DateTime.now();
      if (_userStateStore.state == null && !_userStateStore.isLoading) {
        await _userStateStore.load();
      }
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        _recordStaleDiscard(runId, domain: 'local_state');
        return;
      }
      if (_userStateStore.activeLocalScopeUserId != user.id ||
          _userStateStore.userId != user.id) {
        throw StateError('Local state scope does not match current user.');
      }
      _metric(
        runId,
        'local_state',
        DateTime.now().difference(localStateStartedAt),
      );
      _log(runId, 'local_state_ready', startedAt: startedAt);
      _timeline(runId, 'local_state_ready');

      _setState(_state.copyWith(phase: BootstrapPhase.loadingRemoteProfile));
      _log(runId, 'phase=loading_remote_profile', startedAt: startedAt);
      final scopeUserId = user.id;
      final scopeEpoch = _userStateStore.scopeEpoch;
      final scopeKey = '${user.id}|$scopeUserId|$scopeEpoch';
      _log(runId, 'authoritative_cache_v2_read_started', startedAt: startedAt);
      final cacheReadStartedAt = DateTime.now();
      final cacheReadFuture = _authoritativeBootstrapCache.read(
        user.id,
        expectedScopeKey: scopeKey,
      );
      _log(runId, 'authoritative_bootstrap_started', startedAt: startedAt);
      final authoritativeDecisionResult =
          await _profileRepository.loadAuthoritativeBootstrapDecision(
        scopeUserId: scopeUserId,
        scopeEpoch: scopeEpoch,
        onboardingPolicyVersion: _onboardingPolicyVersion,
      );
      _metric(
        runId,
        'authoritative_bootstrap_total',
        authoritativeDecisionResult.totalDuration,
      );
      _metric(
        runId,
        'authoritative_bootstrap_query',
        authoritativeDecisionResult.remoteQueryDuration,
      );
      _metric(
        runId,
        'authoritative_bootstrap_map',
        authoritativeDecisionResult.mapDuration,
      );
      _metric(
        runId,
        'authoritative_bootstrap_calls',
        Duration.zero,
        extras: <String, Object>{
          'count': authoritativeDecisionResult.remoteCallCount,
        },
      );
      _metric(
        runId,
        'authoritative_bootstrap_payload_columns',
        Duration.zero,
        extras: <String, Object>{
          'count': authoritativeDecisionResult.payloadColumnCount,
        },
      );
      if (authoritativeDecisionResult.staleResultDiscarded) {
        _metric(
          runId,
          'authoritative_bootstrap_stale_discard',
          Duration.zero,
        );
      }
      _telemetryByRunId[runId]?.remoteQueriesExecuted +=
          authoritativeDecisionResult.remoteCallCount;
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        _recordStaleDiscard(runId, domain: 'authoritative_bootstrap');
        _fail(
          runId,
          const BootstrapError(
            type: BootstrapErrorType.staleSession,
            message: 'La sesión cambió mientras preparábamos tu espacio.',
          ),
        );
        return;
      }
      final authoritative = authoritativeDecisionResult.decision;
      final authoritativeError = authoritativeDecisionResult.error;
      if (authoritative == null) {
        if (authoritativeError?.code ==
            AuthoritativeBootstrapDecisionFailureCode.staleResult) {
          _recordStaleDiscard(runId, domain: 'authoritative_bootstrap');
          return;
        }
        _fail(
          runId,
          _errorFromAuthoritativeRepository(
            authoritativeError ??
                const AuthoritativeBootstrapDecisionReadException(
                  code:
                      AuthoritativeBootstrapDecisionFailureCode.invalidPayload,
                  message: 'Authoritative bootstrap decision was null.',
                ),
          ),
        );
        return;
      }
      unawaited(
        _runAuthoritativeBootstrapCacheShadow(
          runId: runId,
          userId: user.id,
          scopeUserId: scopeUserId,
          scopeEpoch: scopeEpoch,
          scopeKey: scopeKey,
          startedAt: startedAt,
          cacheReadStartedAt: cacheReadStartedAt,
          cacheReadFuture: cacheReadFuture,
          authoritativeDecision: authoritative,
        ),
      );
      final destination = _destinationForAuthoritativeDecision(authoritative);
      final bootstrapProfile = authoritative.toBootstrapProfileDecision();
      final profile = bootstrapProfile?.toRemoteProfile();
      if (profile != null && profile.id != user.id) {
        _fail(
          runId,
          const BootstrapError(
            type: BootstrapErrorType.invalidRemoteResponse,
            message: 'La respuesta del perfil no coincide con tu sesión.',
          ),
        );
        return;
      }
      _log(
        runId,
        'authoritative_bootstrap_destination=${destination.name}',
        startedAt: startedAt,
      );
      _timeline(runId, 'profile_ready');

      _setState(_state.copyWith(phase: BootstrapPhase.decidingDestination));
      _log(runId, 'phase=deciding_destination', startedAt: startedAt);
      if (destination == BootstrapDestination.home) {
        if (profile == null) {
          _fail(
            runId,
            const BootstrapError(
              type: BootstrapErrorType.invalidRemoteResponse,
              message:
                  'No hemos podido validar tu estado. Reintenta en un momento.',
            ),
          );
          return;
        }
        final essentials = await _prepareHomeEssentials(
          runId: runId,
          userId: user.id,
          profile: profile,
          startedAt: startedAt,
        );
        if (essentials == null) return;
        final publishStartedAt = DateTime.now();
        final essentialDuration = DateTime.now().difference(startedAt);
        _metric(runId, 'time_to_home_ready', essentialDuration);
        _metric(runId, 'essential_total', essentialDuration);
        _setState(
          BootstrapState(
            phase: BootstrapPhase.ready,
            runId: runId,
            mode: mode,
            user: user,
            remoteProfile: profile,
            destination: destination,
            cosmeticsReadyToken: essentials.cosmeticsReadyToken,
          ),
        );
        _metric(
          runId,
          'home_publish',
          DateTime.now().difference(publishStartedAt),
        );
        _timeline(runId, 'home_published');
        _fireAndForgetHomeReady(essentials);
        _finishRun(runId);
        _authController.startPostHomeBootstrapWork(
          bootstrapRunId: runId,
          userId: essentials.userId,
          scopeUserId: essentials.scopeUserId,
          scopeEpoch: essentials.scopeEpoch,
          bootstrapDecision: bootstrapProfile,
        );
        _log(runId, 'destination=${destination.name}', startedAt: startedAt);
        return;
      }
      _setState(
        BootstrapState(
          phase: BootstrapPhase.ready,
          runId: runId,
          mode: mode,
          user: user,
          remoteProfile: profile,
          destination: destination,
        ),
      );
      _finishRun(runId);
      _log(runId, 'destination=${destination.name}', startedAt: startedAt);
    } catch (error) {
      if (!_isCurrentRun(runId)) {
        _recordStaleDiscard(runId, domain: 'exception');
        return;
      }
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.localState,
          message:
              'No hemos podido preparar tu espacio. Reintenta en un momento.',
          cause: error,
        ),
      );
    }
  }

  Future<void> _loadGuestStateAndDecide(int runId, DateTime startedAt) async {
    _setState(
      BootstrapState(
        phase: BootstrapPhase.loadingLocalState,
        runId: runId,
        mode: _state.mode,
      ),
    );
    _log(runId, 'phase=loading_local_state', startedAt: startedAt);
    final localStateStartedAt = DateTime.now();
    await _userStateStore.switchLocalScope(userId: null);
    if (!_isCurrentRun(runId) || _authController.currentUser != null) {
      _recordStaleDiscard(runId, domain: 'guest_local_state');
      return;
    }
    _metric(
        runId, 'local_state', DateTime.now().difference(localStateStartedAt));
    _log(runId, 'local_state_ready', startedAt: startedAt);
    _timeline(runId, 'local_state_ready');

    _setState(_state.copyWith(phase: BootstrapPhase.decidingDestination));
    final destination = _userStateStore.onboardingDone
        ? BootstrapDestination.authentication
        : BootstrapDestination.welcome;
    _setState(
      BootstrapState(
        phase: BootstrapPhase.ready,
        runId: runId,
        mode: _state.mode,
        destination: destination,
      ),
    );
    _finishRun(runId);
    _log(runId, 'destination=${destination.name}', startedAt: startedAt);
  }

  BootstrapDestination _destinationForAuthoritativeDecision(
    AuthoritativeBootstrapDecision decision,
  ) {
    switch (decision.decision) {
      case AuthoritativeBootstrapDestination.home:
        return BootstrapDestination.home;
      case AuthoritativeBootstrapDestination.onboarding:
        return BootstrapDestination.onboarding;
      case AuthoritativeBootstrapDestination.profileUninitialized:
        return BootstrapDestination.profileUninitialized;
      case AuthoritativeBootstrapDestination.profileDeleted:
        return BootstrapDestination.profileDeleted;
      case AuthoritativeBootstrapDestination.accountSuspended:
        return BootstrapDestination.accountSuspended;
      case AuthoritativeBootstrapDestination.accountPendingDeletion:
        return BootstrapDestination.accountPendingDeletion;
      case AuthoritativeBootstrapDestination.invalidProfile:
        return BootstrapDestination.invalidProfile;
    }
  }

  BootstrapError _errorFromAuthoritativeRepository(
    AuthoritativeBootstrapDecisionReadException? error,
  ) {
    switch (error?.code) {
      case AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable:
        return BootstrapError(
          type: BootstrapErrorType.network,
          message:
              'No hemos podido confirmar tu estado. Reintenta en un momento.',
          cause: error,
        );
      case AuthoritativeBootstrapDecisionFailureCode.notAuthenticated:
      case AuthoritativeBootstrapDecisionFailureCode.staleResult:
        return BootstrapError(
          type: BootstrapErrorType.staleSession,
          message: 'No hemos podido confirmar tu sesiÃ³n. Vuelve a intentarlo.',
          cause: error,
        );
      case AuthoritativeBootstrapDecisionFailureCode.emptyResponse:
      case AuthoritativeBootstrapDecisionFailureCode.invalidPayload:
      case AuthoritativeBootstrapDecisionFailureCode.identityMismatch:
      case AuthoritativeBootstrapDecisionFailureCode.unknownDecision:
      case AuthoritativeBootstrapDecisionFailureCode.inconsistentContract:
        return BootstrapError(
          type: BootstrapErrorType.invalidRemoteResponse,
          message:
              'No hemos podido validar tu estado. Reintenta en un momento.',
          cause: error,
        );
      case null:
        return BootstrapError(
          type: BootstrapErrorType.unknown,
          message:
              'No hemos podido preparar tu espacio. Reintenta en un momento.',
          cause: error,
        );
    }
  }

  Future<BootstrapHomeEssentialReady?> _prepareHomeEssentials({
    required int runId,
    required String userId,
    required RemoteProfile profile,
    required DateTime startedAt,
  }) async {
    final telemetry = _telemetryByRunId[runId];
    _setState(_state.copyWith(phase: BootstrapPhase.loadingEssentialHabits));
    _log(runId, 'essential_habits_started', startedAt: startedAt);
    _timeline(runId, 'habits_started');
    final habitsStartedAt = DateTime.now();
    final habitsFuture = _essentialHabitsPreparer.prepare(userId: userId);

    _setState(_state.copyWith(phase: BootstrapPhase.loadingEssentialCosmetics));
    _log(runId, 'essential_cosmetics_started', startedAt: startedAt);
    _trace(runId, 'cosmetics_prepare_started');
    _timeline(runId, 'cosmetics_started');
    final cosmeticsStartedAt = DateTime.now();
    final cosmeticsFuture =
        (_essentialCosmeticsPreparer ?? const NoopBootstrapCosmeticsPreparer())
            .prepare(userId: userId);
    telemetry?.habitsAndCosmeticsParallel = true;

    final results = await Future.wait<Object>(<Future<Object>>[
      habitsFuture,
      cosmeticsFuture,
    ]);
    if (!_isCurrentUserRun(runId, userId)) {
      _log(runId, 'stale_result_discarded domain=essentials');
      _recordStaleDiscard(runId, domain: 'essentials');
      return null;
    }

    final habits = results[0] as EssentialHabitsBootstrapResult;
    final cosmetics = results[1] as CosmeticsBootstrapResult;
    telemetry?.habitsSource = _bootstrapSourceLabel(habits.source);
    telemetry?.cosmeticsSource = _bootstrapSourceLabel(cosmetics.source);
    telemetry?.remoteQueriesExecuted +=
        habits.remoteQueryCount + cosmetics.remoteQueryCount;
    telemetry?.deduplicatedLoads +=
        habits.deduplicatedLoadCount + cosmetics.deduplicatedLoadCount;
    telemetry?.staleResultsDiscarded +=
        habits.staleResultDiscardCount + cosmetics.staleResultDiscardCount;
    _metric(
      runId,
      'essential_habits',
      DateTime.now().difference(habitsStartedAt),
      extras: <String, Object>{
        'source': telemetry?.habitsSource ?? 'unknown',
      },
    );
    _emitOperationMetrics(
      runId,
      durations: habits.operationDurations,
      queryCounts: habits.operationQueryCounts,
    );
    _metric(
      runId,
      'essential_cosmetics',
      DateTime.now().difference(cosmeticsStartedAt),
      extras: <String, Object>{
        'source': telemetry?.cosmeticsSource ?? 'unknown',
      },
    );
    _emitOperationMetrics(
      runId,
      durations: cosmetics.operationDurations,
      queryCounts: cosmetics.operationQueryCounts,
    );
    _timeline(runId, 'habits_ready');
    _timeline(runId, 'cosmetics_ready');
    _log(
      runId,
      'essential_habits_ready source=${_bootstrapSourceLabel(habits.source)} '
      'duration_ms=${DateTime.now().difference(habitsStartedAt).inMilliseconds}',
    );
    _log(
      runId,
      'essential_cosmetics_ready '
      'source=${_bootstrapSourceLabel(cosmetics.source)} '
      'duration_ms=${DateTime.now().difference(cosmeticsStartedAt).inMilliseconds}',
    );
    _log(
      runId,
      'cosmetics_snapshot_applied revision=${cosmetics.appliedRevision}',
    );
    if (cosmetics.readyToken != null) {
      _trace(
        runId,
        'cosmetics_snapshot_applied',
        token: cosmetics.readyToken,
      );
    }

    if (habits.userId != userId || !habits.canBuildHome) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialHabits,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃ³n e intÃ©ntalo de nuevo.',
          cause: habits.error,
        ),
      );
      return null;
    }
    if (cosmetics.userId != userId || !cosmetics.canBuildHome) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialCosmetics,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃ³n e intÃ©ntalo de nuevo.',
          cause: cosmetics.error,
        ),
      );
      return null;
    }
    if (!cosmetics.resolversVerified) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialCosmetics,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃƒÂ³n e intÃƒÂ©ntalo de nuevo.',
          cause: StateError('Cosmetics resolvers were not verified.'),
        ),
      );
      return null;
    }
    final cosmeticsPreparer =
        _essentialCosmeticsPreparer ?? const NoopBootstrapCosmeticsPreparer();
    final readyToken = cosmetics.readyToken ??
        cosmeticsPreparer.createReadyToken(userId: userId);
    if (readyToken == null ||
        !cosmeticsPreparer.validateReadyToken(readyToken)) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialCosmetics,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃƒÆ’Ã‚Â³n e intÃƒÆ’Ã‚Â©ntalo de nuevo.',
          cause: StateError('Cosmetics readiness token is not valid.'),
        ),
      );
      return null;
    }
    _trace(runId, 'cosmetics_resolvers_verified', token: readyToken);

    _setState(_state.copyWith(phase: BootstrapPhase.preloadingEssentialAssets));
    final assetStartedAt = DateTime.now();
    try {
      await _essentialAssetPreloader.preload(cosmetics.visibleAssets);
    } catch (error) {
      if (!_isCurrentUserRun(runId, userId)) {
        _log(runId, 'stale_result_discarded domain=assets');
        _recordStaleDiscard(runId, domain: 'assets');
        return null;
      }
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialAssets,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃ³n e intÃ©ntalo de nuevo.',
          cause: error,
        ),
      );
      return null;
    }

    if (!_isCurrentUserRun(runId, userId)) {
      _log(runId, 'stale_result_discarded domain=assets');
      _recordStaleDiscard(runId, domain: 'assets');
      return null;
    }
    _metric(
      runId,
      'essential_assets',
      DateTime.now().difference(assetStartedAt),
    );
    _log(
      runId,
      'essential_assets_preloaded '
      'duration_ms=${DateTime.now().difference(assetStartedAt).inMilliseconds}',
    );
    _log(runId, 'assets_preloaded');
    _trace(runId, 'assets_preloaded', token: readyToken);
    _timeline(runId, 'assets_ready');
    if (!cosmeticsPreparer.validateReadyToken(readyToken)) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.essentialCosmetics,
          message:
              'No hemos podido preparar tu espacio.\n\nComprueba tu conexiÃƒÆ’Ã‚Â³n e intÃƒÆ’Ã‚Â©ntalo de nuevo.',
          cause: StateError('Cosmetics readiness token changed after assets.'),
        ),
      );
      return null;
    }
    _log(
      runId,
      'home_ready total_ms=${DateTime.now().difference(startedAt).inMilliseconds}',
    );
    _trace(runId, 'publishing_home', token: readyToken);
    final scopeUserId =
        _userStateStore.activeLocalScopeUserId ?? _userStateStore.userId;
    if (scopeUserId == null || scopeUserId != userId) {
      _fail(
        runId,
        BootstrapError(
          type: BootstrapErrorType.staleSession,
          message: 'La sesiÃ³n cambiÃ³ mientras preparÃ¡bamos tu espacio.',
          cause: StateError('Scope changed before home publish.'),
        ),
      );
      return null;
    }
    return BootstrapHomeEssentialReady(
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: _userStateStore.scopeEpoch,
      remoteProfile: profile,
      localStateLoaded: true,
      habitsAndLogsReconciled: true,
      streakProtectionReconciled: true,
      effectiveTimeZoneResolved: true,
      visibleCosmeticsResolved: true,
      visibleAssetsPreloaded: true,
      cosmeticsReadyToken: readyToken,
    );
  }

  Future<void> _runAuthoritativeBootstrapCacheShadow({
    required int runId,
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required String scopeKey,
    required DateTime startedAt,
    required DateTime cacheReadStartedAt,
    required Future<AuthoritativeBootstrapCacheReadResultV2> cacheReadFuture,
    required AuthoritativeBootstrapDecision authoritativeDecision,
  }) async {
    AuthoritativeBootstrapCacheReadResultV2 readResult;
    try {
      readResult = await cacheReadFuture;
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[bootstrap] cache v2 read failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      readResult = const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.storageError,
      );
    }

    if (!_isCurrentRun(runId) || _authController.currentUser?.id != userId) {
      _metric(
        runId,
        'authoritative_cache_v2_stale_read_discard',
        Duration.zero,
        extras: <String, Object>{
          'scope_epoch': scopeEpoch,
        },
      );
      _log(runId, 'authoritative_cache_v2_stale_read_discard');
      return;
    }

    final readCompletedAt = DateTime.now();
    _metric(
      runId,
      'authoritative_cache_v2_read_total',
      readCompletedAt.difference(cacheReadStartedAt),
      extras: <String, Object>{
        'scope_epoch': scopeEpoch,
      },
    );
    _log(
      runId,
      'authoritative_cache_v2_result status=${readResult.status.name}',
      startedAt: startedAt,
    );

    final cachedEntry = readResult.entry;
    if (cachedEntry != null) {
      final age =
          readResult.status == AuthoritativeBootstrapCacheReadStatusV2.expired
              ? readResult.entry == null
                  ? Duration.zero
                  : DateTime.now().toUtc().difference(cachedEntry.cachedAt)
              : DateTime.now().toUtc().difference(cachedEntry.cachedAt);
      _metric(
        runId,
        'authoritative_cache_v2_age_ms',
        age,
        extras: <String, Object>{
          'status': readResult.status.name,
        },
      );
      _log(
        runId,
        'authoritative_cache_v2_schema version=${cachedEntry.schemaVersion}',
      );
      _log(
        runId,
        'authoritative_cache_v2_destination=${cachedEntry.destination.name}',
      );
    }

    if (readResult.status == AuthoritativeBootstrapCacheReadStatusV2.hit &&
        cachedEntry != null) {
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != userId) {
        _metric(
          runId,
          'authoritative_cache_v2_stale_comparison_discard',
          Duration.zero,
          extras: <String, Object>{
            'scope_epoch': scopeEpoch,
          },
        );
        _log(runId, 'authoritative_cache_v2_stale_comparison_discard');
        return;
      }
      final comparisonStartedAt = DateTime.now();
      final comparison = compareAuthoritativeBootstrapCacheV2(
        cacheEntry: cachedEntry,
        authoritativeDecision: authoritativeDecision,
        expectedUserId: userId,
        expectedEnvironmentId: _authoritativeBootstrapEnvironmentId,
        expectedScopeKey: scopeKey,
      );
      _metric(
        runId,
        'authoritative_cache_v2_comparison_total',
        DateTime.now().difference(comparisonStartedAt),
        extras: <String, Object>{
          'kind': comparison.kind.name,
          'mismatch_fields': comparison.mismatchedFields.join(','),
        },
      );
      _log(
        runId,
        'authoritative_cache_v2_comparison '
        'kind=${comparison.kind.name} '
        'mismatch_fields=${comparison.mismatchedFields.join(',')}',
      );
    }

    if (!_isCurrentRun(runId) || _authController.currentUser?.id != userId) {
      _metric(
        runId,
        'authoritative_cache_v2_stale_write_discard',
        Duration.zero,
        extras: <String, Object>{
          'scope_epoch': scopeEpoch,
        },
      );
      _log(runId, 'authoritative_cache_v2_stale_write_discard');
      return;
    }

    final writeStartedAt = DateTime.now();
    _log(
      runId,
      'authoritative_cache_v2_write_started',
      startedAt: startedAt,
    );
    try {
      final entry =
          AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision(
        decision: authoritativeDecision,
        environmentId: _authoritativeBootstrapEnvironmentId,
        scopeKey: scopeKey,
        cachedAt: writeStartedAt,
      );
      await _authoritativeBootstrapCache.write(entry);
      _metric(
        runId,
        'authoritative_cache_v2_write_total',
        DateTime.now().difference(writeStartedAt),
        extras: <String, Object>{
          'scope_epoch': scopeEpoch,
          'destination': authoritativeDecision.decision.name,
        },
      );
      _log(
        runId,
        'authoritative_cache_v2_write_result status=success '
        'destination=${authoritativeDecision.decision.name}',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[bootstrap] cache v2 write failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      _metric(
        runId,
        'authoritative_cache_v2_write_total',
        DateTime.now().difference(writeStartedAt),
        extras: <String, Object>{
          'scope_epoch': scopeEpoch,
          'destination': authoritativeDecision.decision.name,
        },
      );
      _log(
        runId,
        'authoritative_cache_v2_write_result status=error '
        'destination=${authoritativeDecision.decision.name}',
      );
    }
  }

  BootstrapRunMode _consumeNextRunMode() {
    if (_hasStartedInitialBootstrap) {
      return BootstrapRunMode.inAppBootstrap;
    }
    _hasStartedInitialBootstrap = true;
    return BootstrapRunMode.coldStart;
  }

  String _bootstrapSourceLabel(String source) {
    if (source.contains('confirmed_empty')) return 'confirmed_empty';
    if (source.contains('degraded')) return 'degraded';
    if (source.contains('cache')) return 'cache';
    if (source.contains('remote')) return 'remote';
    return source;
  }

  BootstrapError _errorFromRepository(RepositoryError? error) {
    switch (error?.code) {
      case RepositoryErrorCode.notFound:
        return BootstrapError(
          type: BootstrapErrorType.profileNotFound,
          message: 'No hemos encontrado tu perfil. Reintenta en un momento.',
          cause: error,
        );
      case RepositoryErrorCode.network:
        return BootstrapError(
          type: BootstrapErrorType.network,
          message: 'No hemos podido conectar. Revisa tu conexión y reintenta.',
          cause: error,
        );
      case RepositoryErrorCode.permissionDenied:
        return BootstrapError(
          type: BootstrapErrorType.permissionDenied,
          message: 'No hemos podido acceder a tu perfil.',
          cause: error,
        );
      case RepositoryErrorCode.invalidResponse:
        return BootstrapError(
          type: BootstrapErrorType.invalidRemoteResponse,
          message: 'No hemos podido validar tu perfil.',
          cause: error,
        );
      case RepositoryErrorCode.notAuthenticated:
        return BootstrapError(
          type: BootstrapErrorType.staleSession,
          message: 'No hemos podido confirmar tu sesión. Vuelve a intentarlo.',
          cause: error,
        );
      case RepositoryErrorCode.unknown:
      case null:
        return BootstrapError(
          type: BootstrapErrorType.unknown,
          message:
              'No hemos podido preparar tu espacio. Reintenta en un momento.',
          cause: error,
        );
    }
  }

  void _fail(int runId, BootstrapError error) {
    if (!_isCurrentRun(runId)) return;
    _setState(
      _state.copyWith(
        phase: BootstrapPhase.failed,
        error: error,
        clearDestination: true,
      ),
    );
    _log(runId, 'failed type=${error.type.name}');
    _finishRun(runId);
  }

  bool _isCurrentRun(int runId) => runId == _state.runId;

  bool _isCurrentUserRun(int runId, String userId) {
    return _isCurrentRun(runId) && _authController.currentUser?.id == userId;
  }

  void _setState(BootstrapState state) {
    _state = state;
    notifyListeners();
  }

  void _recordStaleDiscard(int runId, {required String domain}) {
    final telemetry = _telemetryByRunId[runId];
    if (telemetry == null) return;
    telemetry.staleResultsDiscarded += 1;
    _log(runId, 'stale_result_discarded domain=$domain');
  }

  void _metric(
    int runId,
    String metric,
    Duration duration, {
    Map<String, Object>? extras,
  }) {
    if (!kDebugMode) return;
    final buffer = StringBuffer(
      '[BootstrapPerf] run=$runId metric=$metric '
      'duration_ms=${duration.inMilliseconds}',
    );
    extras?.forEach((key, value) {
      buffer.write(' $key=$value');
    });
    _debugLogger(buffer.toString());
  }

  void _emitOperationMetrics(
    int runId, {
    required Map<String, Duration> durations,
    required Map<String, int> queryCounts,
  }) {
    final emitted = <String>{};
    for (final entry in durations.entries) {
      final extras = <String, Object>{};
      final queryCount = queryCounts[entry.key];
      if (queryCount != null) {
        extras['queries'] = queryCount;
      }
      _metric(
        runId,
        entry.key,
        entry.value,
        extras: extras.isEmpty ? null : extras,
      );
      emitted.add(entry.key);
    }
    for (final entry in queryCounts.entries) {
      if (emitted.contains(entry.key)) continue;
      _metric(
        runId,
        entry.key,
        Duration.zero,
        extras: <String, Object>{'queries': entry.value},
      );
    }
  }

  void _timeline(int runId, String event) {
    if (!kDebugMode) return;
    final telemetry = _telemetryByRunId[runId];
    final elapsed = telemetry == null
        ? 0
        : DateTime.now().difference(telemetry.startedAt).inMilliseconds;
    _debugLogger('[BootstrapTimeline] run=$runId event=$event t_ms=$elapsed');
  }

  void _finishRun(int runId) {
    final telemetry = _telemetryByRunId.remove(runId);
    if (telemetry == null) return;
    _metric(
      runId,
      'total',
      DateTime.now().difference(telemetry.startedAt),
      extras: <String, Object>{
        'mode': telemetry.mode == BootstrapRunMode.coldStart
            ? 'cold_start'
            : 'in_app',
        'habits_source': telemetry.habitsSource,
        'cosmetics_source': telemetry.cosmeticsSource,
        'habits_cosmetics_parallel': telemetry.habitsAndCosmeticsParallel,
        'remote_queries': telemetry.remoteQueriesExecuted,
        'deduplicated_loads': telemetry.deduplicatedLoads,
        'stale_results_discarded': telemetry.staleResultsDiscarded,
      },
    );
  }

  void _log(int runId, String message, {DateTime? startedAt}) {
    if (!kDebugMode) return;
    final elapsed = startedAt == null
        ? ''
        : ' t=${DateTime.now().difference(startedAt).inMilliseconds}ms';
    _debugLogger('[Bootstrap] run=$runId $message$elapsed');
  }

  void _trace(
    int runId,
    String event, {
    CosmeticsReadyToken? token,
    String? note,
  }) {
    if (!kDebugMode) return;
    _debugLogger(
      '[BootstrapTrace] event=$event '
      'runId=$runId '
      'mode=${_state.mode == BootstrapRunMode.coldStart ? 'cold_start' : 'in_app'} '
      'controllerIdentity=${token?.controllerIdentity ?? 'none'} '
      'scope=${_debugScope(token?.scope ?? _userStateStore.activeLocalScopeUserId ?? _userStateStore.userId)} '
      'user=${_authController.currentUser != null} '
      'appliedRevision=${token?.appliedRevision ?? 'none'} '
      'equippedWallpaperId=${token?.equippedWallpaperId ?? 'none'} '
      'equippedHabitCardId=${token?.equippedHabitCardId ?? 'none'} '
      'equippedUserCardId=${token?.equippedUserCardId ?? 'none'} '
      'wallpaperResolved=${token?.wallpaperResolved ?? false} '
      'habitCardResolved=${token?.habitCardResolved ?? false} '
      'userCardResolved=${token?.userCardResolved ?? false} '
      '${note == null ? '' : 'note=$note'}',
    );
  }

  String _debugScope(String? scope) {
    final value = scope?.trim();
    if (value == null || value.isEmpty) return 'guest';
    if (value.length <= 8) return value;
    return '${value.substring(0, 4)}...${value.substring(value.length - 4)}';
  }

  static String _normalizeAuthoritativeBootstrapEnvironmentId(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return RutioSupabaseConfig.supabaseUrl;
    }
    return normalized;
  }

  void _fireAndForgetHomeReady(BootstrapHomeEssentialReady ready) {
    final callback = _onHomeReady;
    if (callback == null) {
      return;
    }
    unawaited(_guardHomeReadyCallback(callback, ready));
  }

  Future<void> _guardHomeReadyCallback(
    BootstrapHomeReadyCallback callback,
    BootstrapHomeEssentialReady ready,
  ) async {
    try {
      await callback(ready);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[bootstrap] home ready callback failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
