import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/remote/remote_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/repositories/repository_result.dart';
import '../../devtools/rutio_runtime_profile.dart';
import '../../stores/user_state_store.dart';
import '../auth/auth_controller.dart';

abstract class BootstrapProfileRepository {
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile();

  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  });
}

class ProfileBootstrapRepository implements BootstrapProfileRepository {
  const ProfileBootstrapRepository(this._repository);

  final ProfileRepository _repository;

  @override
  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() =>
      _repository.fetchCurrentProfile();

  @override
  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) =>
      _repository.markOnboardingCompleted(
        onboardingVersion: onboardingVersion,
      );
}

enum BootstrapPhase {
  idle,
  resolvingSession,
  selectingUserScope,
  loadingLocalState,
  loadingRemoteProfile,
  decidingDestination,
  ready,
  failed,
}

enum BootstrapDestination {
  welcome,
  authentication,
  onboarding,
  home,
}

enum BootstrapErrorType {
  profileNotFound,
  network,
  permissionDenied,
  invalidRemoteResponse,
  staleSession,
  localState,
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
    this.user,
    this.remoteProfile,
    this.destination,
    this.error,
    this.usesOfflinePolicy = false,
  });

  final BootstrapPhase phase;
  final int runId;
  final User? user;
  final RemoteProfile? remoteProfile;
  final BootstrapDestination? destination;
  final BootstrapError? error;
  final bool usesOfflinePolicy;

  bool get isReady => phase == BootstrapPhase.ready && destination != null;
  bool get isFailed => phase == BootstrapPhase.failed;

  BootstrapState copyWith({
    BootstrapPhase? phase,
    int? runId,
    User? user,
    bool clearUser = false,
    RemoteProfile? remoteProfile,
    bool clearRemoteProfile = false,
    BootstrapDestination? destination,
    bool clearDestination = false,
    BootstrapError? error,
    bool clearError = false,
    bool? usesOfflinePolicy,
  }) {
    return BootstrapState(
      phase: phase ?? this.phase,
      runId: runId ?? this.runId,
      user: clearUser ? null : user ?? this.user,
      remoteProfile:
          clearRemoteProfile ? null : remoteProfile ?? this.remoteProfile,
      destination: clearDestination ? null : destination ?? this.destination,
      error: clearError ? null : error ?? this.error,
      usesOfflinePolicy: usesOfflinePolicy ?? this.usesOfflinePolicy,
    );
  }

  static const initial = BootstrapState(
    phase: BootstrapPhase.idle,
    runId: 0,
  );
}

class BootstrapController extends ChangeNotifier {
  BootstrapController({
    required AuthController authController,
    required UserStateStore userStateStore,
    required BootstrapProfileRepository profileRepository,
  })  : _authController = authController,
        _userStateStore = userStateStore,
        _profileRepository = profileRepository {
    _authController.addListener(_handleAuthChanged);
    unawaited(start());
  }

  final AuthController _authController;
  final UserStateStore _userStateStore;
  final BootstrapProfileRepository _profileRepository;

  BootstrapState _state = BootstrapState.initial;
  int _nextRunId = 0;
  String? _lastResolvedUserId;
  bool _isCompletingTemporaryOnboarding = false;

  BootstrapState get state => _state;

  Future<void> start() => _run();

  Future<void> retry() => _run();

  Future<void> completeTemporaryOnboarding() async {
    if (_isCompletingTemporaryOnboarding) return;
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
      _setState(_state.copyWith(phase: BootstrapPhase.decidingDestination));
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
      _setState(
        BootstrapState(
          phase: BootstrapPhase.ready,
          runId: runId,
          user: _state.user,
          remoteProfile: completed,
          destination: BootstrapDestination.home,
        ),
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
    if (currentUserId == _lastResolvedUserId && _state.isReady) return;
    _log(_state.runId, 'auth_changed user=${currentUserId != null}');
    unawaited(_run());
  }

  Future<void> _run() async {
    final runId = ++_nextRunId;
    final startedAt = DateTime.now();
    _lastResolvedUserId = _authController.currentUser?.id;
    _setState(
      BootstrapState(
        phase: BootstrapPhase.resolvingSession,
        runId: runId,
      ),
    );
    _log(runId, 'phase=resolving_session', startedAt: startedAt);

    try {
      final session = _authController.isSessionResolved
          ? _authController.sessionSnapshot
          : await _authController.initialSessionResolved;
      if (!_isCurrentRun(runId)) return;

      final user = session.user;
      _lastResolvedUserId = user?.id;
      _log(
        runId,
        'session_resolved user=${user != null}',
        startedAt: startedAt,
      );

      if (RutioRuntimeProfile.isDemo) {
        await _loadGuestStateAndDecide(runId, startedAt);
        return;
      }

      if (user == null) {
        await _loadGuestStateAndDecide(runId, startedAt);
        return;
      }

      _setState(
        BootstrapState(
          phase: BootstrapPhase.selectingUserScope,
          runId: runId,
          user: user,
        ),
      );
      _log(runId, 'phase=selecting_user_scope', startedAt: startedAt);
      await _userStateStore.switchLocalScope(userId: user.id);
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        return;
      }
      _log(runId, 'scope_selected', startedAt: startedAt);

      _setState(_state.copyWith(phase: BootstrapPhase.loadingLocalState));
      _log(runId, 'phase=loading_local_state', startedAt: startedAt);
      if (_userStateStore.state == null && !_userStateStore.isLoading) {
        await _userStateStore.load();
      }
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        return;
      }
      if (_userStateStore.activeLocalScopeUserId != user.id ||
          _userStateStore.userId != user.id) {
        throw StateError('Local state scope does not match current user.');
      }
      _log(runId, 'local_state_ready', startedAt: startedAt);

      _setState(_state.copyWith(phase: BootstrapPhase.loadingRemoteProfile));
      _log(runId, 'phase=loading_remote_profile', startedAt: startedAt);
      _log(runId, 'profile_load_started', startedAt: startedAt);
      final profileResult = await _profileRepository.fetchCurrentProfile();
      if (!_isCurrentRun(runId) || _authController.currentUser?.id != user.id) {
        _fail(
          runId,
          const BootstrapError(
            type: BootstrapErrorType.staleSession,
            message: 'La sesión cambió mientras preparábamos tu espacio.',
          ),
        );
        return;
      }
      if (!profileResult.isSuccess) {
        _fail(runId, _errorFromRepository(profileResult.error));
        return;
      }
      final profile = profileResult.data;
      if (profile == null) {
        _fail(
          runId,
          const BootstrapError(
            type: BootstrapErrorType.profileNotFound,
            message: 'No hemos encontrado tu perfil. Reintenta en un momento.',
          ),
        );
        return;
      }
      if (profile.id != user.id) {
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
        'profile_ready status=${profile.onboardingStatus.toSupabase()}',
        startedAt: startedAt,
      );

      _setState(_state.copyWith(phase: BootstrapPhase.decidingDestination));
      _log(runId, 'phase=deciding_destination', startedAt: startedAt);
      final destination = _destinationForProfile(profile);
      _setState(
        BootstrapState(
          phase: BootstrapPhase.ready,
          runId: runId,
          user: user,
          remoteProfile: profile,
          destination: destination,
        ),
      );
      _log(runId, 'destination=${destination.name}', startedAt: startedAt);
    } catch (error) {
      if (!_isCurrentRun(runId)) return;
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
      ),
    );
    _log(runId, 'phase=loading_local_state', startedAt: startedAt);
    await _userStateStore.switchLocalScope(userId: null);
    if (!_isCurrentRun(runId) || _authController.currentUser != null) return;
    _log(runId, 'local_state_ready', startedAt: startedAt);

    _setState(_state.copyWith(phase: BootstrapPhase.decidingDestination));
    final destination = _userStateStore.onboardingDone
        ? BootstrapDestination.authentication
        : BootstrapDestination.welcome;
    _setState(
      BootstrapState(
        phase: BootstrapPhase.ready,
        runId: runId,
        destination: destination,
      ),
    );
    _log(runId, 'destination=${destination.name}', startedAt: startedAt);
  }

  BootstrapDestination _destinationForProfile(RemoteProfile profile) {
    switch (profile.onboardingStatus) {
      case OnboardingStatus.pending:
      case OnboardingStatus.inProgress:
        return BootstrapDestination.onboarding;
      case OnboardingStatus.completed:
        return BootstrapDestination.home;
    }
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
  }

  bool _isCurrentRun(int runId) => runId == _state.runId;

  void _setState(BootstrapState state) {
    _state = state;
    notifyListeners();
  }

  void _log(int runId, String message, {DateTime? startedAt}) {
    if (!kDebugMode) return;
    final elapsed = startedAt == null
        ? ''
        : ' t=${DateTime.now().difference(startedAt).inMilliseconds}ms';
    debugPrint('[Bootstrap] run=$runId $message$elapsed');
  }

  @override
  void dispose() {
    _authController.removeListener(_handleAuthChanged);
    super.dispose();
  }
}
