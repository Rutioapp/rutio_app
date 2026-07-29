import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../devtools/rutio_runtime_profile.dart';
import '../../data/models/remote/remote_profile.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../features/global_wallet/application/global_wallet_controller.dart';
import '../../stores/user_state_store.dart';

typedef AuthDebugLogger = void Function(String message);

typedef PostHomeBootstrapTaskRunner = Future<void> Function(
  PostHomeBootstrapTaskContext context,
);

enum AuthSessionResolution {
  unresolved,
  resolvedWithoutUser,
  resolvedWithUser,
}

@immutable
class AuthSessionSnapshot {
  const AuthSessionSnapshot({
    required this.resolution,
    required this.user,
  });

  final AuthSessionResolution resolution;
  final User? user;

  bool get isResolved => resolution != AuthSessionResolution.unresolved;

  static const unresolved = AuthSessionSnapshot(
    resolution: AuthSessionResolution.unresolved,
    user: null,
  );
}

@immutable
class PostHomeBootstrapTaskContext {
  const PostHomeBootstrapTaskContext({
    required this.bootstrapRunId,
    required this.userId,
    required this.scopeUserId,
    required this.scopeEpoch,
    this.bootstrapDecision,
  });

  final int bootstrapRunId;
  final String userId;
  final String scopeUserId;
  final int scopeEpoch;
  final BootstrapProfileDecision? bootstrapDecision;

  String get scopeKey => '$userId|$scopeUserId|$scopeEpoch';

  String get operationKey => '$bootstrapRunId|$scopeKey';
}

class AuthController extends ChangeNotifier {
  AuthController(
    this._authRepository, {
    required UserStateStore userStateStore,
    required GlobalWalletController globalWalletController,
    ProfileRepository? profileRepository,
    bool enableBackgroundProfileSync = true,
    PostHomeBootstrapTaskRunner? postHomeBootstrapTaskRunner,
    AuthDebugLogger? debugLogger,
  })  : _userStateStore = userStateStore,
        _globalWalletController = globalWalletController,
        _profileRepository = profileRepository,
        _enableBackgroundProfileSync = enableBackgroundProfileSync,
        _postHomeBootstrapTaskRunner = postHomeBootstrapTaskRunner,
        _debugLogger = debugLogger ?? debugPrint {
    if (RutioRuntimeProfile.isDemo) {
      // Demo profile is intentionally local-only: avoid binding to any live
      // Supabase session so real accounts are never mutated during demos.
      _currentUser = null;
      if (kDebugMode) {
        debugPrint('[auth] demo profile active: skipping Supabase auth sync');
      }
      _resolveSession(null);
      return;
    }

    _currentUser = _authRepository.currentUser;
    if (kDebugMode) {
      debugPrint(
        '[auth] initial auth state: ${_currentUser != null ? 'signedIn' : 'signedOut'}',
      );
      debugPrint(
        '[BootstrapTrace] event=auth_initial_value '
        'user=${_currentUser != null}',
      );
    }

    _authSubscription = _authRepository.authStateChanges.listen(
      _handleAuthState,
      onError: _handleAuthStateError,
    );
    if (_currentUser != null) {
      final initialUserId = _currentUser!.id;
      _fireAndForget(() async {
        await _userStateStore.switchLocalScope(userId: initialUserId);
        _fireAndForget(
          () => _globalWalletController.syncSession(userId: initialUserId),
          context: 'global wallet sync (controller_init)',
        );
        if (_enableBackgroundProfileSync) {
          _markLastLoginTouchPending(initialUserId);
        }
      }, context: 'auth controller init');
    }
  }

  final AuthRepository _authRepository;
  final UserStateStore _userStateStore;
  final GlobalWalletController _globalWalletController;
  final ProfileRepository? _profileRepository;
  final bool _enableBackgroundProfileSync;
  final PostHomeBootstrapTaskRunner? _postHomeBootstrapTaskRunner;
  final AuthDebugLogger _debugLogger;
  StreamSubscription<AuthState>? _authSubscription;

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  AuthSessionResolution _sessionResolution = AuthSessionResolution.unresolved;
  final Completer<AuthSessionSnapshot> _initialSessionCompleter =
      Completer<AuthSessionSnapshot>();
  bool _isEnsuringProfileForBootstrap = false;
  String? _errorMessage;
  String? _noticeMessage;
  final Map<String, Future<void>> _postHomeBootstrapInFlight =
      <String, Future<void>>{};
  final Map<String, int> _latestPostHomeBootstrapRunIdByScopeKey =
      <String, int>{};
  String? _pendingLastLoginTouchUserId;
  Future<void>? _signOutInFlight;
  String? _locallySignedOutUserId;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  AuthSessionResolution get sessionResolution => _sessionResolution;
  bool get isSessionResolved =>
      _sessionResolution != AuthSessionResolution.unresolved;
  AuthSessionSnapshot get sessionSnapshot => AuthSessionSnapshot(
        resolution: _sessionResolution,
        user: _currentUser,
      );
  Future<AuthSessionSnapshot> get initialSessionResolved =>
      _initialSessionCompleter.future;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  bool get isAuthenticated => _currentUser != null;

  void clearError() {
    if (_errorMessage == null && _noticeMessage == null) return;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<AuthResponse?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (!_isValidEmail(normalizedEmail)) {
      _setError('Please enter a valid email address.');
      return null;
    }
    if (password.isEmpty) {
      _setError('Email or password is incorrect.');
      return null;
    }

    _setLoading(true);
    _setError(null);
    _setNotice(null);
    if (kDebugMode) {
      debugPrint('[auth] sign in started');
    }

    try {
      final response = await _authRepository.signInWithEmailPassword(
        email: normalizedEmail,
        password: password,
      );
      _currentUser = _authRepository.currentUser ?? response.user;
      if (_currentUser == null) {
        _setError('Email or password is incorrect.');
        return null;
      }
      _locallySignedOutUserId = null;

      if (kDebugMode) {
        debugPrint('[auth] sign in succeeded: userId=${_currentUser!.id}');
        debugPrint('[auth] currentUser after sign in: yes');
      }
      _resolveSession(_currentUser);
      _userStateStore.restoreGamificationOverlaysAfterLogout();
      await _userStateStore.switchLocalScope(userId: _currentUser!.id);
      unawaited(
        _globalWalletController.syncSession(userId: _currentUser!.id),
      );
      if (_enableBackgroundProfileSync) {
        _markLastLoginTouchPending(_currentUser!.id);
      }
      await _profileRepository?.invalidateBootstrapProfileDecisionMemory(
        reason: BootstrapProfileDecisionMemoryInvalidationReason.sessionChanged,
        bumpSessionGeneration: true,
      );
      notifyListeners();
      return response;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign in failed (AuthException): ${error.message}');
      }
      _setError(_mapAuthError(error.message, isSignIn: true));
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign in failed (unexpected): $error');
      }
      _setError('Connection error. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResponse?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim();
    if (!_isValidEmail(normalizedEmail)) {
      _setError('Please enter a valid email address.');
      return null;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return null;
    }

    _setLoading(true);
    _setError(null);
    _setNotice(null);
    if (kDebugMode) {
      debugPrint('[auth] sign up started');
    }

    try {
      final response = await _authRepository.signUpWithEmailPassword(
        email: normalizedEmail,
        password: password,
        displayName: displayName,
      );
      _currentUser = response.session?.user ?? _authRepository.currentUser;
      if (_currentUser != null) {
        _locallySignedOutUserId = null;
      }
      if (_currentUser == null && response.user != null) {
        _setNotice(
          'Account created. Please check your email to confirm your account.',
        );
        if (kDebugMode) {
          debugPrint(
            '[auth] sign up created user without session; email confirmation is likely enabled.',
          );
          debugPrint('[auth] currentUser after sign up: no');
        }
        return response;
      }

      if (_currentUser == null) {
        _setError('Authentication failed. Please try again.');
        return null;
      }

      _resolveSession(_currentUser);
      _userStateStore.restoreGamificationOverlaysAfterLogout();
      await _userStateStore.switchLocalScope(userId: _currentUser!.id);
      unawaited(
        _globalWalletController.syncSession(userId: _currentUser!.id),
      );
      if (_enableBackgroundProfileSync) {
        _markLastLoginTouchPending(_currentUser!.id);
        await _ensureCurrentUserProfileForBootstrap(
          reason: 'sign_up',
        );
      }
      await _profileRepository?.invalidateBootstrapProfileDecisionMemory(
        reason: BootstrapProfileDecisionMemoryInvalidationReason.sessionChanged,
        bumpSessionGeneration: true,
      );

      if (kDebugMode) {
        debugPrint('[auth] sign up succeeded: userId=${_currentUser!.id}');
        debugPrint('[auth] currentUser after sign up: yes');
      }
      notifyListeners();
      return response;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign up failed (AuthException): ${error.message}');
      }
      _setError(_mapAuthError(error.message, isSignIn: false));
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign up failed (unexpected): $error');
      }
      _setError('Connection error. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    final inFlight = _signOutInFlight;
    if (inFlight != null) return inFlight;

    final future = _signOutFailClosed();
    _signOutInFlight = future;
    try {
      await future;
    } finally {
      if (identical(_signOutInFlight, future)) {
        _signOutInFlight = null;
      }
    }
  }

  Future<void> _signOutFailClosed() async {
    _setLoading(true);
    _setError(null);
    _setNotice(null);
    final previousUserId = _currentUser?.id ?? _authRepository.currentUser?.id;
    _locallySignedOutUserId = previousUserId;
    _currentUser = null;
    _pendingLastLoginTouchUserId = null;
    _latestPostHomeBootstrapRunIdByScopeKey.clear();
    _resolveSession(null);

    await _profileRepository?.invalidateBootstrapProfileDecisionMemory(
      userId: previousUserId,
      reason: BootstrapProfileDecisionMemoryInvalidationReason.logout,
      bumpSessionGeneration: true,
    );
    _userStateStore.suppressGamificationOverlaysDuringLogout();
    await _globalWalletController.clearSession();
    await _userStateStore.switchLocalScope(
      userId: null,
      forceReload: true,
    );

    try {
      await _authRepository.signOut();
      _locallySignedOutUserId = null;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[auth] sign out succeeded');
        debugPrint('[auth] sign out cleared/updated user state');
      }
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign out failed (AuthException): ${error.message}');
      }
      _setError('Could not finish remote sign-out. Please try again.');
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign out failed (unexpected): $error');
      }
      _setError('Could not finish remote sign-out. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _ensureCurrentUserProfileForBootstrap({
    required String reason,
  }) async {
    if (_isEnsuringProfileForBootstrap) return;

    final profileRepository = _profileRepository;
    if (profileRepository == null) return;

    final user = _currentUser ?? _authRepository.currentUser;
    if (user == null) return;

    _isEnsuringProfileForBootstrap = true;
    try {
      final ensured = await profileRepository.upsertCurrentProfile(
        email: user.email,
        displayName: _firstNonEmpty(<String?>[
          _normalizedValue(user.userMetadata?['display_name']),
          _normalizedValue(user.userMetadata?['name']),
        ]),
        avatarUrl: _firstNonEmpty(<String?>[
          _normalizedValue(user.userMetadata?['avatar_url']),
          _normalizedValue(user.userMetadata?['avatarUrl']),
        ]),
      );

      if (!ensured.isSuccess && kDebugMode) {
        _debugLogger(
          '[auth] profile ensure failed ($reason): ${ensured.error?.message}',
        );
      } else if (ensured.data != null &&
          _userStateStore.activeLocalScopeUserId == user.id) {
        await profileRepository
            .storeBootstrapProfileDecisionFromRemoteProfileInMemory(
          profile: ensured.data!,
          scopeUserId: user.id,
          scopeEpoch: _userStateStore.scopeEpoch,
          source: BootstrapProfileDecisionMemorySource.remoteProfileUpsert,
          expectedUserId: user.id,
        );
      }
    } catch (error) {
      if (kDebugMode) {
        _debugLogger(
          '[auth] warning: profile ensure for bootstrap failed: $error',
        );
      }
    } finally {
      _isEnsuringProfileForBootstrap = false;
    }
  }

  void _handleAuthState(AuthState state) {
    try {
      final previousUserId = _currentUser?.id;
      final nextUser = state.session?.user ?? _authRepository.currentUser;
      if (nextUser == null &&
          _currentUser == null &&
          _locallySignedOutUserId != null) {
        if (kDebugMode) {
          debugPrint('[auth] ignored duplicate signed-out event');
        }
        _resolveSession(null);
        return;
      }
      if (nextUser != null &&
          _currentUser == null &&
          _locallySignedOutUserId == nextUser.id) {
        if (kDebugMode) {
          debugPrint('[auth] ignored stale auth event after local sign out');
        }
        _resolveSession(null);
        return;
      }
      if (kDebugMode) {
        final authUserId = nextUser?.id ?? 'guest';
        debugPrint(
          '[auth] auth state changed: ${nextUser != null ? 'signedIn' : 'signedOut'} (event=${state.event.name})',
        );
        debugPrint('[auth] auth state userId: $authUserId');
        debugPrint(
          '[BootstrapTrace] event=auth_stream_event '
          'user=${nextUser != null} authEvent=${state.event.name}',
        );
      }
      if (nextUser != null) {
        if (previousUserId != nextUser.id) {
          final profileRepository = _profileRepository;
          if (profileRepository != null) {
            unawaited(
              profileRepository.invalidateBootstrapProfileDecisionMemory(
                userId: previousUserId,
                reason: BootstrapProfileDecisionMemoryInvalidationReason
                    .userChanged,
                bumpSessionGeneration: true,
              ),
            );
          }
        }
        _userStateStore.restoreGamificationOverlaysAfterLogout();
        final userId = nextUser.id;
        _fireAndForget(() async {
          await _userStateStore.switchLocalScope(userId: userId);
          _fireAndForget(
            () => _globalWalletController.syncSession(userId: userId),
            context: 'global wallet sync (auth_state_${state.event.name})',
          );
          if (_enableBackgroundProfileSync) {
            if (_shouldTouchLastLogin(state.event)) {
              _markLastLoginTouchPending(userId);
            }
          }
        }, context: 'auth state signed in (${state.event.name})');
      } else {
        final profileRepository = _profileRepository;
        if (profileRepository != null) {
          unawaited(
            profileRepository.invalidateBootstrapProfileDecisionMemory(
              userId: previousUserId,
              reason: BootstrapProfileDecisionMemoryInvalidationReason.logout,
              bumpSessionGeneration: true,
            ),
          );
        }
        _userStateStore.suppressGamificationOverlaysDuringLogout();
        _fireAndForget(
          () => _globalWalletController.clearSession(),
          context: 'global wallet clear (auth_state_${state.event.name})',
        );
        _fireAndForget(
          () => _userStateStore.switchLocalScope(
            userId: null,
            forceReload: true,
          ),
          context:
              'switch local scope cleared (auth_state_${state.event.name})',
        );
        if (kDebugMode) {
          debugPrint('[auth] sign out cleared/updated user state');
        }
      }
      _resolveSession(nextUser);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[auth] auth state handler error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      _resolveSession(_currentUser);
    }
  }

  void _handleAuthStateError(Object error, StackTrace stackTrace) {
    final recoverable = _isRecoverableAuthStreamError(error);
    if (kDebugMode) {
      debugPrint(
        recoverable
            ? '[auth] recoverable auth stream error'
            : '[auth] auth stream error',
      );
    }
    _resolveSession(_currentUser);
  }

  bool _shouldTouchLastLogin(AuthChangeEvent event) {
    return event == AuthChangeEvent.signedIn ||
        event == AuthChangeEvent.initialSession;
  }

  bool _isRecoverableAuthStreamError(Object error) {
    if (error is AuthRetryableFetchException) {
      return true;
    }
    if (error is SocketException ||
        error.runtimeType.toString() == 'ClientException') {
      return true;
    }
    return error.toString().contains('Failed host lookup');
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = _normalizedValue(value);
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  String _normalizedValue(dynamic value) => (value ?? '').toString().trim();

  String _emailPrefix(String? email) {
    final normalizedEmail = _normalizedValue(email);
    if (normalizedEmail.isEmpty) return '';
    final atIndex = normalizedEmail.indexOf('@');
    if (atIndex <= 0) return '';
    return normalizedEmail.substring(0, atIndex).trim();
  }

  void _resolveSession(User? user) {
    final nextResolution = user == null
        ? AuthSessionResolution.resolvedWithoutUser
        : AuthSessionResolution.resolvedWithUser;
    final changed = _isCheckingSession ||
        _sessionResolution != nextResolution ||
        _currentUser?.id != user?.id;
    _currentUser = user;
    _isCheckingSession = false;
    _sessionResolution = nextResolution;
    final snapshot = AuthSessionSnapshot(
      resolution: nextResolution,
      user: user,
    );
    if (!_initialSessionCompleter.isCompleted) {
      _initialSessionCompleter.complete(snapshot);
    }
    if (changed) {
      notifyListeners();
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  void _setNotice(String? value) {
    if (_noticeMessage == value) return;
    _noticeMessage = value;
    notifyListeners();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  String _mapAuthError(
    String rawMessage, {
    required bool isSignIn,
  }) {
    final message = rawMessage.toLowerCase();

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Connection error. Please try again.';
    }

    if (message.contains('invalid email') ||
        message.contains('email address') ||
        message.contains('email format')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('password') &&
        (message.contains('weak') ||
            message.contains('short') ||
            message.contains('at least'))) {
      return 'Password must be at least 6 characters.';
    }

    if (!isSignIn &&
        (message.contains('already registered') ||
            message.contains('already exists') ||
            message.contains('user already registered') ||
            message.contains('duplicate key'))) {
      return 'An account with this email may already exist. Try signing in instead.';
    }

    if (isSignIn) {
      return 'Email or password is incorrect.';
    }

    return 'Authentication failed. Please try again.';
  }

  void startPostHomeBootstrapWork({
    required int bootstrapRunId,
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    BootstrapProfileDecision? bootstrapDecision,
  }) {
    if (!_enableBackgroundProfileSync) return;
    final context = PostHomeBootstrapTaskContext(
      bootstrapRunId: bootstrapRunId,
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      bootstrapDecision: bootstrapDecision,
    );
    _latestPostHomeBootstrapRunIdByScopeKey[context.scopeKey] = bootstrapRunId;
    _fireAndForget(
      () => _schedulePostHomeBootstrapWork(context),
      context: 'post-home bootstrap work',
    );
  }

  Future<void> _schedulePostHomeBootstrapWork(
    PostHomeBootstrapTaskContext context,
  ) async {
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'schedule');
      return;
    }

    final operationKey = context.operationKey;
    final existing = _postHomeBootstrapInFlight[operationKey];
    if (existing != null) {
      return existing;
    }

    final runner =
        _postHomeBootstrapTaskRunner ?? _runDefaultPostHomeBootstrapWork;
    late final Future<void> future;
    future = runner(context).whenComplete(() {
      if (identical(_postHomeBootstrapInFlight[operationKey], future)) {
        _postHomeBootstrapInFlight.remove(operationKey);
      }
    });
    _postHomeBootstrapInFlight[operationKey] = future;
    return future;
  }

  Future<void> _runDefaultPostHomeBootstrapWork(
    PostHomeBootstrapTaskContext context,
  ) async {
    final startedAt = DateTime.now();
    try {
      final profileStartedAt = DateTime.now();
      await _runPostHomeProfileMetadata(context);
      _bootstrapMetric(
        context.bootstrapRunId,
        'post_home_profile_metadata',
        DateTime.now().difference(profileStartedAt),
      );
      if (!_isCurrentPostHomeContext(context)) {
        _recordPostHomeStaleDiscard(context, stage: 'profile_metadata');
        return;
      }

      final backfillsStartedAt = DateTime.now();
      await _runPostHomeBackfills(context);
      _bootstrapMetric(
        context.bootstrapRunId,
        'post_home_backfills',
        DateTime.now().difference(backfillsStartedAt),
      );
    } catch (error, stackTrace) {
      _recordPostHomeError(
        context,
        stage: 'unexpected',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    } finally {
      _bootstrapMetric(
        context.bootstrapRunId,
        'post_home_total',
        DateTime.now().difference(startedAt),
      );
    }
  }

  Future<void> _runPostHomeProfileMetadata(
    PostHomeBootstrapTaskContext context,
  ) async {
    final profileRepository = _profileRepository;
    if (profileRepository == null) return;
    if (!_isCurrentPostHomeContext(context)) return;

    await _runPostHomeFullProfileSync(context);
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'profile_sync');
      return;
    }

    final shouldTouchLastLogin = _pendingLastLoginTouchUserId == context.userId;
    if (shouldTouchLastLogin) {
      final loginTouch = await profileRepository.touchLastLogin();
      if (!_isCurrentPostHomeContext(context)) {
        _recordPostHomeStaleDiscard(context, stage: 'touch_last_login');
        return;
      }
      if (!loginTouch.isSuccess) {
        _recordPostHomeError(
          context,
          stage: 'touch_last_login',
          error: loginTouch.error ?? 'unknown',
        );
      } else if (_pendingLastLoginTouchUserId == context.userId) {
        _pendingLastLoginTouchUserId = null;
      }
    }

    if (!_isCurrentPostHomeContext(context)) return;
    final lastSeenTouch = await profileRepository.touchLastSeen();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'touch_last_seen');
      return;
    }
    if (!lastSeenTouch.isSuccess) {
      _recordPostHomeError(
        context,
        stage: 'touch_last_seen',
        error: lastSeenTouch.error ?? 'unknown',
      );
    }
  }

  Future<void> _runPostHomeFullProfileSync(
    PostHomeBootstrapTaskContext context,
  ) async {
    final profileRepository = _profileRepository;
    if (profileRepository == null) return;
    if (!_isCurrentPostHomeContext(context)) return;

    Map<String, dynamic>? profile;
    try {
      final profileResult = await profileRepository.fetchCurrentProfile();
      if (!_isCurrentPostHomeContext(context)) {
        _recordPostHomeStaleDiscard(context, stage: 'profile_fetch');
        return;
      }
      if (!profileResult.isSuccess) {
        _recordPostHomeError(
          context,
          stage: 'profile_fetch',
          error: profileResult.error ?? 'unknown',
        );
        return;
      }

      final remoteProfile = profileResult.data;
      if (remoteProfile != null) {
        profile = remoteProfile.toMap();
      }

      final currentUser = _currentUser ?? _authRepository.currentUser;
      if (currentUser == null) {
        _recordPostHomeStaleDiscard(context, stage: 'profile_fetch');
        return;
      }

      final remoteDisplayName = _normalizedValue(profile?['display_name']);
      final metadataDisplayName =
          _normalizedValue(currentUser.userMetadata?['display_name']);
      final metadataName = _normalizedValue(currentUser.userMetadata?['name']);
      final emailPrefix = _emailPrefix(currentUser.email);
      final existingLocalName = _normalizedValue(_userStateStore.displayName);
      final resolvedDisplayName = _firstNonEmpty(<String?>[
            remoteDisplayName,
            metadataDisplayName,
            metadataName,
            emailPrefix,
            existingLocalName,
          ]) ??
          '';

      final resolvedEmail = _firstNonEmpty(<String?>[
        _normalizedValue(profile?['email']),
        _normalizedValue(currentUser.email),
        _normalizedValue(_userStateStore.authEmail),
      ]);

      await _userStateStore.applySupabaseIdentity(
        userId: currentUser.id,
        email: resolvedEmail,
        displayName: resolvedDisplayName,
        avatarUrl: _normalizedValue(profile?['avatar_url']),
      );
      if (remoteProfile != null) {
        await profileRepository
            .storeBootstrapProfileDecisionFromRemoteProfileInMemory(
          profile: remoteProfile,
          scopeUserId: context.scopeUserId,
          scopeEpoch: context.scopeEpoch,
          source: BootstrapProfileDecisionMemorySource.remoteProfile,
          expectedUserId: currentUser.id,
        );
      }
    } catch (error, stackTrace) {
      _recordPostHomeError(
        context,
        stage: 'profile_sync',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _runPostHomeBackfills(
    PostHomeBootstrapTaskContext context,
  ) async {
    if (!_isCurrentPostHomeContext(context)) return;

    final progressBootstrap =
        await _userStateStore.syncSupabaseUserProgressBootstrapBestEffort();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'user_progress');
      return;
    }
    if (kDebugMode) {
      _debugLogger(
        '[auth] user progress restore status: '
        '${progressBootstrap.restoreResult.status.name}',
      );
      _debugLogger(
        '[auth] user progress backfill synced: '
        '${progressBootstrap.backfillSynced ? 'yes' : 'no'}',
      );
    }

    final habitSummary = await _userStateStore.syncExistingLocalHabitsOnce();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'habit_backfill');
      return;
    }
    if (kDebugMode) {
      _debugLogger(
        '[auth] habit backfill summary: '
        'total=${habitSummary.totalCandidates}, '
        'uploaded=${habitSummary.uploadedCount}, '
        'skipped=${habitSummary.skippedCount}, '
        'failed=${habitSummary.failedCount}',
      );
    }

    final habitLogSummary =
        await _userStateStore.syncExistingLocalHabitLogsOnce();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'habit_log_backfill');
      return;
    }
    if (kDebugMode) {
      _debugLogger(
        '[auth] habit log backfill summary: '
        'total=${habitLogSummary.totalCandidates}, '
        'uploaded=${habitLogSummary.uploadedCount}, '
        'skipped=${habitLogSummary.skippedCount}, '
        'failed=${habitLogSummary.failedCount}',
      );
    }

    final journalSummary =
        await _userStateStore.syncExistingLocalJournalEntriesOnce();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'journal_backfill');
      return;
    }
    if (kDebugMode) {
      _debugLogger(
        '[auth] journal backfill summary: '
        'total=${journalSummary.totalCandidates}, '
        'uploaded=${journalSummary.uploadedCount}, '
        'skipped=${journalSummary.skippedCount}, '
        'failed=${journalSummary.failedCount}',
      );
    }

    final achievementSummary =
        await _userStateStore.syncExistingLocalAchievementsOnce();
    if (!_isCurrentPostHomeContext(context)) {
      _recordPostHomeStaleDiscard(context, stage: 'achievement_backfill');
      return;
    }
    if (kDebugMode) {
      _debugLogger(
        '[auth] achievement backfill summary: '
        'total=${achievementSummary.totalCandidates}, '
        'uploaded=${achievementSummary.uploadedCount}, '
        'skipped=${achievementSummary.skippedCount}, '
        'failed=${achievementSummary.failedCount}',
      );
    }
  }

  bool _isCurrentPostHomeContext(PostHomeBootstrapTaskContext context) {
    final currentUserId =
        (_currentUser ?? _authRepository.currentUser)?.id.trim();
    final scopeUserId = _userStateStore.activeLocalScopeUserId?.trim() ??
        _userStateStore.userId?.trim();
    return currentUserId == context.userId &&
        scopeUserId == context.scopeUserId &&
        _userStateStore.scopeEpoch == context.scopeEpoch &&
        _latestPostHomeBootstrapRunIdByScopeKey[context.scopeKey] ==
            context.bootstrapRunId &&
        isAuthenticated;
  }

  void _markLastLoginTouchPending(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    _pendingLastLoginTouchUserId = normalized;
  }

  void _recordPostHomeStaleDiscard(
    PostHomeBootstrapTaskContext context, {
    required String stage,
  }) {
    _bootstrapMetric(
      context.bootstrapRunId,
      'post_home_stale_discard',
      Duration.zero,
      extras: <String, Object>{'stage': stage},
    );
  }

  void _recordPostHomeError(
    PostHomeBootstrapTaskContext context, {
    required String stage,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      _debugLogger('[auth] post-home bootstrap error ($stage): $error');
      if (stackTrace != null) {
        debugPrintStack(stackTrace: stackTrace);
      }
    }
    _bootstrapMetric(
      context.bootstrapRunId,
      'post_home_error',
      Duration.zero,
      extras: <String, Object>{'stage': stage},
    );
  }

  void _bootstrapMetric(
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

  void _fireAndForget(
    Future<void> Function() task, {
    required String context,
  }) {
    unawaited(_guardAsyncTask(task, context: context));
  }

  Future<void> _guardAsyncTask(
    Future<void> Function() task, {
    required String context,
  }) async {
    try {
      await task();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('[auth] background auth task error ($context): $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
