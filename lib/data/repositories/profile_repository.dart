import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_config.dart';
import '../../core/supabase/rutio_supabase_client.dart';
import '../local/bootstrap_profile_decision_cache.dart';
import '../models/remote/authoritative_bootstrap_decision.dart';
import '../models/remote/remote_profile.dart';
import 'repository_result.dart';

typedef CurrentProfileUserIdProvider = String? Function();

enum BootstrapProfileDecisionMemorySource {
  remoteDecision,
  remoteProfile,
  remoteProfileUpsert,
  onboardingCompletion,
}

enum BootstrapProfilePersistentCacheComparison {
  match,
  remoteNewerOrChanged,
  cacheMissing,
  cacheInvalid,
  remoteMissing,
  remoteInvalid,
}

enum BootstrapProfilePersistentCacheDeleteReason {
  corrupt,
  userMismatch,
  schemaMismatch,
  onboardingVersionMismatch,
  incompleteDecision,
  remoteMissing,
  remoteInvalid,
  logout,
  userChanged,
  profileMutation,
  staleOperation,
}

enum BootstrapProfileDecisionMemoryInvalidationReason {
  userMismatch,
  sessionChanged,
  scopeChanged,
  epochChanged,
  onboardingVersionChanged,
  explicitInvalidation,
  incompleteEntry,
  logout,
  userChanged,
  profileMutation,
  invalidRemoteResponse,
}

@immutable
class BootstrapProfileDecisionMemoryEntry {
  const BootstrapProfileDecisionMemoryEntry({
    required this.userId,
    required this.decision,
    required this.sessionGeneration,
    required this.scopeUserId,
    required this.scopeEpoch,
    required this.onboardingPolicyVersion,
    required this.source,
    required this.storeVersion,
  });

  final String userId;
  final BootstrapProfileDecision decision;
  final int sessionGeneration;
  final String scopeUserId;
  final int scopeEpoch;
  final int onboardingPolicyVersion;
  final BootstrapProfileDecisionMemorySource source;
  final int storeVersion;
}

@immutable
class BootstrapProfileDecisionLoadResult {
  const BootstrapProfileDecisionLoadResult({
    required this.result,
    required this.totalDuration,
    required this.inflightWaitDuration,
    required this.remoteQueryDuration,
    required this.mapDuration,
    required this.remoteCallCount,
    required this.payloadColumnCount,
    this.deduplicatedLoadCount = 0,
    this.memoryHit = false,
    this.memoryMiss = false,
    this.memoryStored = false,
    this.memorySource,
    this.memoryInvalidationReason,
    this.persistentCacheRead = false,
    this.persistentCacheHitShadow = false,
    this.persistentCacheMiss = false,
    this.persistentCacheValidation = BootstrapProfileCacheValidation.missing,
    this.persistentCacheAge,
    this.persistentCacheWrite = false,
    this.persistentCacheDelete = false,
    this.persistentCacheDeleteReason,
    this.persistentCacheComparison,
    this.persistentCacheStaleDiscard = false,
  });

  final RepositoryResult<BootstrapProfileDecision?> result;
  final Duration totalDuration;
  final Duration inflightWaitDuration;
  final Duration remoteQueryDuration;
  final Duration mapDuration;
  final int remoteCallCount;
  final int payloadColumnCount;
  final int deduplicatedLoadCount;
  final bool memoryHit;
  final bool memoryMiss;
  final bool memoryStored;
  final BootstrapProfileDecisionMemorySource? memorySource;
  final BootstrapProfileDecisionMemoryInvalidationReason?
      memoryInvalidationReason;
  final bool persistentCacheRead;
  final bool persistentCacheHitShadow;
  final bool persistentCacheMiss;
  final BootstrapProfileCacheValidation persistentCacheValidation;
  final Duration? persistentCacheAge;
  final bool persistentCacheWrite;
  final bool persistentCacheDelete;
  final BootstrapProfilePersistentCacheDeleteReason?
      persistentCacheDeleteReason;
  final BootstrapProfilePersistentCacheComparison? persistentCacheComparison;
  final bool persistentCacheStaleDiscard;

  BootstrapProfileDecisionLoadResult copyWith({
    RepositoryResult<BootstrapProfileDecision?>? result,
    Duration? totalDuration,
    Duration? inflightWaitDuration,
    Duration? remoteQueryDuration,
    Duration? mapDuration,
    int? remoteCallCount,
    int? payloadColumnCount,
    int? deduplicatedLoadCount,
    bool? memoryHit,
    bool? memoryMiss,
    bool? memoryStored,
    BootstrapProfileDecisionMemorySource? memorySource,
    bool clearMemorySource = false,
    BootstrapProfileDecisionMemoryInvalidationReason? memoryInvalidationReason,
    bool clearMemoryInvalidationReason = false,
    bool? persistentCacheRead,
    bool? persistentCacheHitShadow,
    bool? persistentCacheMiss,
    BootstrapProfileCacheValidation? persistentCacheValidation,
    Duration? persistentCacheAge,
    bool clearPersistentCacheAge = false,
    bool? persistentCacheWrite,
    bool? persistentCacheDelete,
    BootstrapProfilePersistentCacheDeleteReason? persistentCacheDeleteReason,
    bool clearPersistentCacheDeleteReason = false,
    BootstrapProfilePersistentCacheComparison? persistentCacheComparison,
    bool clearPersistentCacheComparison = false,
    bool? persistentCacheStaleDiscard,
  }) {
    return BootstrapProfileDecisionLoadResult(
      result: result ?? this.result,
      totalDuration: totalDuration ?? this.totalDuration,
      inflightWaitDuration: inflightWaitDuration ?? this.inflightWaitDuration,
      remoteQueryDuration: remoteQueryDuration ?? this.remoteQueryDuration,
      mapDuration: mapDuration ?? this.mapDuration,
      remoteCallCount: remoteCallCount ?? this.remoteCallCount,
      payloadColumnCount: payloadColumnCount ?? this.payloadColumnCount,
      deduplicatedLoadCount:
          deduplicatedLoadCount ?? this.deduplicatedLoadCount,
      memoryHit: memoryHit ?? this.memoryHit,
      memoryMiss: memoryMiss ?? this.memoryMiss,
      memoryStored: memoryStored ?? this.memoryStored,
      memorySource:
          clearMemorySource ? null : memorySource ?? this.memorySource,
      memoryInvalidationReason: clearMemoryInvalidationReason
          ? null
          : memoryInvalidationReason ?? this.memoryInvalidationReason,
      persistentCacheRead: persistentCacheRead ?? this.persistentCacheRead,
      persistentCacheHitShadow:
          persistentCacheHitShadow ?? this.persistentCacheHitShadow,
      persistentCacheMiss: persistentCacheMiss ?? this.persistentCacheMiss,
      persistentCacheValidation:
          persistentCacheValidation ?? this.persistentCacheValidation,
      persistentCacheAge: clearPersistentCacheAge
          ? null
          : persistentCacheAge ?? this.persistentCacheAge,
      persistentCacheWrite: persistentCacheWrite ?? this.persistentCacheWrite,
      persistentCacheDelete:
          persistentCacheDelete ?? this.persistentCacheDelete,
      persistentCacheDeleteReason: clearPersistentCacheDeleteReason
          ? null
          : persistentCacheDeleteReason ?? this.persistentCacheDeleteReason,
      persistentCacheComparison: clearPersistentCacheComparison
          ? null
          : persistentCacheComparison ?? this.persistentCacheComparison,
      persistentCacheStaleDiscard:
          persistentCacheStaleDiscard ?? this.persistentCacheStaleDiscard,
    );
  }
}

@immutable
class _BootstrapProfileDecisionPersistentRead {
  const _BootstrapProfileDecisionPersistentRead({
    required this.validation,
    this.entry,
    this.age,
  });

  final BootstrapProfileCacheValidation validation;
  final CachedBootstrapProfileDecision? entry;
  final Duration? age;
}

@immutable
class _BootstrapProfileDecisionPersistentIntent {
  const _BootstrapProfileDecisionPersistentIntent({
    required this.entry,
    required this.storeVersion,
    required this.sessionGeneration,
  });

  final CachedBootstrapProfileDecision entry;
  final int storeVersion;
  final int sessionGeneration;
}

@immutable
class AuthoritativeBootstrapDecisionLoadResult {
  const AuthoritativeBootstrapDecisionLoadResult({
    required this.decision,
    required this.totalDuration,
    required this.inflightWaitDuration,
    required this.remoteQueryDuration,
    required this.mapDuration,
    required this.remoteCallCount,
    required this.payloadColumnCount,
    this.deduplicatedLoadCount = 0,
    this.staleResultDiscarded = false,
    this.error,
  });

  final AuthoritativeBootstrapDecision? decision;
  final AuthoritativeBootstrapDecisionReadException? error;
  final Duration totalDuration;
  final Duration inflightWaitDuration;
  final Duration remoteQueryDuration;
  final Duration mapDuration;
  final int remoteCallCount;
  final int payloadColumnCount;
  final int deduplicatedLoadCount;
  final bool staleResultDiscarded;

  bool get isSuccess => decision != null && error == null;

  AuthoritativeBootstrapDecisionLoadResult copyWith({
    AuthoritativeBootstrapDecision? decision,
    bool clearDecision = false,
    AuthoritativeBootstrapDecisionReadException? error,
    bool clearError = false,
    Duration? totalDuration,
    Duration? inflightWaitDuration,
    Duration? remoteQueryDuration,
    Duration? mapDuration,
    int? remoteCallCount,
    int? payloadColumnCount,
    int? deduplicatedLoadCount,
    bool? staleResultDiscarded,
  }) {
    return AuthoritativeBootstrapDecisionLoadResult(
      decision: clearDecision ? null : decision ?? this.decision,
      error: clearError ? null : error ?? this.error,
      totalDuration: totalDuration ?? this.totalDuration,
      inflightWaitDuration: inflightWaitDuration ?? this.inflightWaitDuration,
      remoteQueryDuration: remoteQueryDuration ?? this.remoteQueryDuration,
      mapDuration: mapDuration ?? this.mapDuration,
      remoteCallCount: remoteCallCount ?? this.remoteCallCount,
      payloadColumnCount: payloadColumnCount ?? this.payloadColumnCount,
      deduplicatedLoadCount:
          deduplicatedLoadCount ?? this.deduplicatedLoadCount,
      staleResultDiscarded: staleResultDiscarded ?? this.staleResultDiscarded,
    );
  }
}

class ProfileRepository {
  ProfileRepository({
    SupabaseClient? client,
    CurrentProfileUserIdProvider? currentUserIdProvider,
    BootstrapProfileDecisionCache? bootstrapProfileDecisionCache,
    DateTime Function()? nowProvider,
  })  : _client = client ?? RutioSupabaseClient.instance,
        _currentUserIdProvider = currentUserIdProvider,
        _bootstrapProfileDecisionCache = bootstrapProfileDecisionCache ??
            SharedPreferencesBootstrapProfileDecisionCache(
              environmentNamespace: RutioSupabaseConfig.supabaseUrl,
            ),
        _nowProvider = nowProvider ?? DateTime.now;

  final SupabaseClient _client;
  final CurrentProfileUserIdProvider? _currentUserIdProvider;
  final BootstrapProfileDecisionCache _bootstrapProfileDecisionCache;
  final DateTime Function() _nowProvider;
  final Set<String> _unsupportedColumns = <String>{};
  final Map<String, Future<RepositoryResult<RemoteProfile?>>>
      _inFlightProfiles = <String, Future<RepositoryResult<RemoteProfile?>>>{};
  final Map<String, Future<BootstrapProfileDecisionLoadResult>>
      _inFlightBootstrapProfileDecisions =
      <String, Future<BootstrapProfileDecisionLoadResult>>{};
  final Map<String, Future<AuthoritativeBootstrapDecisionLoadResult>>
      _inFlightAuthoritativeBootstrapDecisions =
      <String, Future<AuthoritativeBootstrapDecisionLoadResult>>{};
  final Map<String, BootstrapProfileDecisionMemoryEntry>
      _bootstrapProfileDecisionMemory =
      <String, BootstrapProfileDecisionMemoryEntry>{};
  final Map<String, int>
      _bootstrapProfileDecisionPersistentOperationVersionByUser =
      <String, int>{};
  final Map<String, _BootstrapProfileDecisionPersistentIntent>
      _bootstrapProfileDecisionPersistentLatestEntryByUser =
      <String, _BootstrapProfileDecisionPersistentIntent>{};
  int _bootstrapProfileDecisionSessionGeneration = 0;
  int _bootstrapProfileDecisionStoreVersion = 0;

  static const String _profilesTable = 'profiles';
  static const int _maxRetryableColumnDrops = 12;
  static const String _bootstrapProfileDecisionColumns =
      'id,onboarding_status,onboarding_version,onboarding_completed_at';
  static const int _bootstrapProfileDecisionColumnCount = 4;
  static const int _authoritativeBootstrapDecisionColumnCount = 11;
  static const int bootstrapOnboardingPolicyVersion = 1;

  User? get currentUser => _client.auth.currentUser;

  Future<RepositoryResult<RemoteProfile?>> fetchCurrentProfile() async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<RemoteProfile?>.failure(_notAuthenticated());
    }

    final inFlight = _inFlightProfiles[userId];
    if (inFlight != null) {
      return inFlight;
    }

    late final Future<RepositoryResult<RemoteProfile?>> future;
    future = _fetchCurrentProfileRemote(userId).whenComplete(() {
      if (identical(_inFlightProfiles[userId], future)) {
        _inFlightProfiles.remove(userId);
      }
    });
    _inFlightProfiles[userId] = future;
    return future;
  }

  Future<AuthoritativeBootstrapDecision> fetchAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
  }) async {
    final result = await loadAuthoritativeBootstrapDecision(
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
    );
    if (result.decision != null) {
      return result.decision!;
    }
    throw result.error ??
        const AuthoritativeBootstrapDecisionReadException(
          code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
          message: 'Could not fetch authoritative bootstrap decision.',
        );
  }

  Future<AuthoritativeBootstrapDecisionLoadResult>
      loadAuthoritativeBootstrapDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: const AuthoritativeBootstrapDecisionReadException(
          code: AuthoritativeBootstrapDecisionFailureCode.notAuthenticated,
          message: 'No authenticated user session is available.',
        ),
        totalDuration: Duration.zero,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 0,
        payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
      );
    }

    final inFlightKey = _authoritativeBootstrapDecisionInFlightKey(
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      sessionGeneration: _bootstrapProfileDecisionSessionGeneration,
    );
    final inFlight = _inFlightAuthoritativeBootstrapDecisions[inFlightKey];
    if (inFlight != null) {
      final waitStopwatch = Stopwatch()..start();
      final shared = await inFlight;
      waitStopwatch.stop();
      return shared.copyWith(
        totalDuration: waitStopwatch.elapsed,
        inflightWaitDuration: waitStopwatch.elapsed,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 0,
        deduplicatedLoadCount: shared.deduplicatedLoadCount + 1,
      );
    }

    final sessionGeneration = _bootstrapProfileDecisionSessionGeneration;
    final requestStoreVersion = ++_bootstrapProfileDecisionStoreVersion;
    late final Future<AuthoritativeBootstrapDecisionLoadResult> future;
    future = _loadAuthoritativeBootstrapDecisionRemote(
      userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      sessionGeneration: sessionGeneration,
      requestStoreVersion: requestStoreVersion,
    ).whenComplete(() {
      if (identical(
          _inFlightAuthoritativeBootstrapDecisions[inFlightKey], future)) {
        _inFlightAuthoritativeBootstrapDecisions.remove(inFlightKey);
      }
    });
    _inFlightAuthoritativeBootstrapDecisions[inFlightKey] = future;
    return future;
  }

  Future<BootstrapProfileDecisionLoadResult> fetchBootstrapProfileDecision({
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.failure(
          _notAuthenticated(),
        ),
        totalDuration: Duration.zero,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 0,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
      );
    }

    final persistentRead = await _readBootstrapProfileDecisionPersistentEntry(
      userId: userId,
      scopeUserId: scopeUserId,
      onboardingPolicyVersion: onboardingPolicyVersion,
    );
    final persistentShadowHit =
        persistentRead.validation == BootstrapProfileCacheValidation.valid;

    final memoryRead = _readBootstrapProfileDecisionMemoryEntry(
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
    );
    if (memoryRead.entry != null) {
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.success(
          data: memoryRead.entry!.decision,
        ),
        totalDuration: Duration.zero,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 0,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
        memoryHit: true,
        memorySource: memoryRead.entry!.source,
        persistentCacheRead: true,
        persistentCacheHitShadow: persistentShadowHit,
        persistentCacheMiss: !persistentShadowHit,
        persistentCacheValidation: persistentRead.validation,
        persistentCacheAge: persistentRead.age,
        persistentCacheComparison: _comparePersistentCacheWithDecision(
          persistentRead.entry,
          memoryRead.entry!.decision,
        ),
      );
    }

    final inFlightKey = _bootstrapProfileDecisionInFlightKey(
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      sessionGeneration: _bootstrapProfileDecisionSessionGeneration,
    );
    final inFlight = _inFlightBootstrapProfileDecisions[inFlightKey];
    if (inFlight != null) {
      final waitStopwatch = Stopwatch()..start();
      final shared = await inFlight;
      waitStopwatch.stop();
      return shared.copyWith(
        totalDuration: waitStopwatch.elapsed,
        inflightWaitDuration: waitStopwatch.elapsed,
        remoteQueryDuration: Duration.zero,
        mapDuration: Duration.zero,
        remoteCallCount: 0,
        deduplicatedLoadCount: shared.deduplicatedLoadCount + 1,
        memoryHit: false,
        memoryMiss: true,
        memoryInvalidationReason: memoryRead.invalidationReason,
        persistentCacheRead: true,
        persistentCacheHitShadow: persistentShadowHit,
        persistentCacheMiss: !persistentShadowHit,
        persistentCacheValidation: persistentRead.validation,
        persistentCacheAge: persistentRead.age,
      );
    }

    final sessionGeneration = _bootstrapProfileDecisionSessionGeneration;
    final requestStoreVersion = ++_bootstrapProfileDecisionStoreVersion;
    late final Future<BootstrapProfileDecisionLoadResult> future;
    future = _fetchBootstrapProfileDecisionRemote(
      userId,
      persistentEntry: persistentRead.entry,
      persistentValidation: persistentRead.validation,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      sessionGeneration: sessionGeneration,
      requestStoreVersion: requestStoreVersion,
    ).whenComplete(() {
      if (identical(_inFlightBootstrapProfileDecisions[inFlightKey], future)) {
        _inFlightBootstrapProfileDecisions.remove(inFlightKey);
      }
    });
    _inFlightBootstrapProfileDecisions[inFlightKey] = future;
    return (await future).copyWith(
      memoryMiss: true,
      memoryInvalidationReason: memoryRead.invalidationReason,
      persistentCacheRead: true,
      persistentCacheHitShadow: persistentShadowHit,
      persistentCacheMiss: !persistentShadowHit,
      persistentCacheValidation: persistentRead.validation,
      persistentCacheAge: persistentRead.age,
    );
  }

  BootstrapProfileDecision? readBootstrapProfileDecisionFromMemory({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
  }) {
    return _readBootstrapProfileDecisionMemoryEntry(
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
    ).entry?.decision;
  }

  Future<void> storeBootstrapProfileDecisionInMemory({
    required BootstrapProfileDecision decision,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
  }) async {
    final requestStoreVersion = ++_bootstrapProfileDecisionStoreVersion;
    _storeBootstrapProfileDecisionInMemory(
      decision: decision,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      source: source,
      sessionGeneration: _bootstrapProfileDecisionSessionGeneration,
      requestStoreVersion: requestStoreVersion,
    );
    await _writeBootstrapProfileDecisionPersistent(
      decision: decision,
      source: _persistentSourceFromMemorySource(source),
      onboardingPolicyVersion: onboardingPolicyVersion,
      sessionGeneration: _bootstrapProfileDecisionSessionGeneration,
      requestStoreVersion: requestStoreVersion,
      scopeUserId: scopeUserId,
    );
  }

  Future<void> storeBootstrapProfileDecisionFromRemoteProfileInMemory({
    required RemoteProfile profile,
    required String scopeUserId,
    required int scopeEpoch,
    int onboardingPolicyVersion = bootstrapOnboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    String? expectedUserId,
  }) {
    final decision = profile.toBootstrapProfileDecision(
      expectedUserId: expectedUserId,
    );
    return storeBootstrapProfileDecisionInMemory(
      decision: decision,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      source: source,
    );
  }

  Future<void> invalidateBootstrapProfileDecisionMemory({
    String? userId,
    BootstrapProfileDecisionMemoryInvalidationReason reason =
        BootstrapProfileDecisionMemoryInvalidationReason.explicitInvalidation,
    bool bumpSessionGeneration = false,
  }) async {
    if (bumpSessionGeneration) {
      _bootstrapProfileDecisionSessionGeneration += 1;
    }
    if (userId == null) {
      _bootstrapProfileDecisionMemory.clear();
      _bootstrapProfileDecisionPersistentOperationVersionByUser.clear();
      _bootstrapProfileDecisionPersistentLatestEntryByUser.clear();
      _inFlightAuthoritativeBootstrapDecisions.clear();
      await _safeClearPersistentBootstrapProfileDecisionCache();
      return;
    }
    final invalidationVersion = ++_bootstrapProfileDecisionStoreVersion;
    _bootstrapProfileDecisionMemory.remove(userId);
    _bootstrapProfileDecisionPersistentOperationVersionByUser[userId] =
        invalidationVersion;
    _bootstrapProfileDecisionPersistentLatestEntryByUser.remove(userId);
    if (reason ==
        BootstrapProfileDecisionMemoryInvalidationReason
            .invalidRemoteResponse) {
      _inFlightProfiles.remove(userId);
    }
    await _safeDeletePersistentBootstrapProfileDecisionCache(
      userId: userId,
      reason: _persistentDeleteReasonFromMemoryReason(reason),
    );
  }

  Future<RepositoryResult<RemoteProfile?>> _fetchCurrentProfileRemote(
    String userId,
  ) async {
    try {
      final row = await _client
          .from(_profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (row == null) {
        return const RepositoryResult<RemoteProfile?>.success(data: null);
      }
      return RepositoryResult<RemoteProfile?>.success(
        data: RemoteProfile.fromMap(Map<String, dynamic>.from(row)),
      );
    } on RemoteProfileParseException catch (error) {
      return RepositoryResult<RemoteProfile?>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteProfile?>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch profile.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[profile_repository] unexpected fetch error: $error');
      }
      return RepositoryResult<RemoteProfile?>.failure(
        _mapUnexpectedError(
          error,
          fallbackMessage: 'Could not fetch profile.',
        ),
      );
    }
  }

  Future<BootstrapProfileDecisionLoadResult>
      _fetchBootstrapProfileDecisionRemote(
    String userId, {
    required CachedBootstrapProfileDecision? persistentEntry,
    required BootstrapProfileCacheValidation persistentValidation,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
    required int sessionGeneration,
    required int requestStoreVersion,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final queryStopwatch = Stopwatch();
    final mapStopwatch = Stopwatch();
    try {
      queryStopwatch.start();
      final row = await _client
          .from(_profilesTable)
          .select(_bootstrapProfileDecisionColumns)
          .eq('id', userId)
          .maybeSingle();
      queryStopwatch.stop();
      if (row == null) {
        final deletePerformed = await _deleteBootstrapProfileDecisionPersistent(
          userId: userId,
          sessionGeneration: sessionGeneration,
          requestStoreVersion: requestStoreVersion,
          reason: BootstrapProfilePersistentCacheDeleteReason.remoteMissing,
        );
        totalStopwatch.stop();
        return BootstrapProfileDecisionLoadResult(
          result: const RepositoryResult<BootstrapProfileDecision?>.success(
            data: null,
          ),
          totalDuration: totalStopwatch.elapsed,
          inflightWaitDuration: Duration.zero,
          remoteQueryDuration: queryStopwatch.elapsed,
          mapDuration: Duration.zero,
          remoteCallCount: 1,
          payloadColumnCount: _bootstrapProfileDecisionColumnCount,
          persistentCacheDelete: deletePerformed,
          persistentCacheDeleteReason: deletePerformed
              ? BootstrapProfilePersistentCacheDeleteReason.remoteMissing
              : null,
          persistentCacheComparison: persistentValidation ==
                  BootstrapProfileCacheValidation.valid
              ? BootstrapProfilePersistentCacheComparison.remoteMissing
              : persistentValidation == BootstrapProfileCacheValidation.missing
                  ? BootstrapProfilePersistentCacheComparison.cacheMissing
                  : BootstrapProfilePersistentCacheComparison.cacheInvalid,
          persistentCacheStaleDiscard: !deletePerformed &&
              persistentValidation == BootstrapProfileCacheValidation.valid,
        );
      }

      mapStopwatch.start();
      final decision = BootstrapProfileDecision.fromMap(
        Map<String, dynamic>.from(row),
        expectedUserId: userId,
      );
      mapStopwatch.stop();
      final persistentComparison = _comparePersistentCacheWithDecision(
        persistentEntry,
        decision,
      );
      final persistentWritePerformed =
          await _writeBootstrapProfileDecisionPersistent(
        decision: decision,
        source: BootstrapProfileDecisionCacheSource.remoteDecision,
        onboardingPolicyVersion: onboardingPolicyVersion,
        sessionGeneration: sessionGeneration,
        requestStoreVersion: requestStoreVersion,
        scopeUserId: scopeUserId,
      );
      totalStopwatch.stop();
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.success(
          data: decision,
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
        memoryStored: _storeBootstrapProfileDecisionInMemory(
          decision: decision,
          scopeUserId: scopeUserId,
          scopeEpoch: scopeEpoch,
          onboardingPolicyVersion: onboardingPolicyVersion,
          source: BootstrapProfileDecisionMemorySource.remoteDecision,
          sessionGeneration: sessionGeneration,
          requestStoreVersion: requestStoreVersion,
        ),
        memorySource: BootstrapProfileDecisionMemorySource.remoteDecision,
        persistentCacheWrite: persistentWritePerformed,
        persistentCacheComparison: persistentComparison,
        persistentCacheStaleDiscard: !persistentWritePerformed &&
            sessionGeneration != _bootstrapProfileDecisionSessionGeneration,
      );
    } on RemoteProfileParseException catch (error) {
      if (queryStopwatch.isRunning) {
        queryStopwatch.stop();
      }
      if (mapStopwatch.isRunning) {
        mapStopwatch.stop();
      }
      totalStopwatch.stop();
      final deletePerformed = persistentValidation ==
              BootstrapProfileCacheValidation.valid
          ? await _deleteBootstrapProfileDecisionPersistent(
              userId: userId,
              sessionGeneration: sessionGeneration,
              requestStoreVersion: requestStoreVersion,
              reason: BootstrapProfilePersistentCacheDeleteReason.remoteInvalid,
            )
          : false;
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.failure(
          RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: error.message,
            cause: error,
          ),
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
        persistentCacheDelete: deletePerformed,
        persistentCacheDeleteReason: deletePerformed
            ? BootstrapProfilePersistentCacheDeleteReason.remoteInvalid
            : null,
        persistentCacheComparison: persistentValidation ==
                BootstrapProfileCacheValidation.valid
            ? BootstrapProfilePersistentCacheComparison.remoteInvalid
            : persistentValidation == BootstrapProfileCacheValidation.missing
                ? BootstrapProfilePersistentCacheComparison.cacheMissing
                : BootstrapProfilePersistentCacheComparison.cacheInvalid,
      );
    } on PostgrestException catch (error) {
      if (queryStopwatch.isRunning) {
        queryStopwatch.stop();
      }
      totalStopwatch.stop();
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.failure(
          _mapPostgrestError(
            error,
            fallbackMessage: 'Could not fetch bootstrap profile decision.',
          ),
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: Duration.zero,
        remoteCallCount: 1,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
      );
    } catch (error) {
      if (queryStopwatch.isRunning) {
        queryStopwatch.stop();
      }
      if (mapStopwatch.isRunning) {
        mapStopwatch.stop();
      }
      totalStopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[profile_repository] unexpected bootstrap decision fetch error: '
          '$error',
        );
      }
      return BootstrapProfileDecisionLoadResult(
        result: RepositoryResult<BootstrapProfileDecision?>.failure(
          _mapUnexpectedError(
            error,
            fallbackMessage: 'Could not fetch bootstrap profile decision.',
          ),
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _bootstrapProfileDecisionColumnCount,
      );
    }
  }

  Future<AuthoritativeBootstrapDecisionLoadResult>
      _loadAuthoritativeBootstrapDecisionRemote(
    String userId, {
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
    required int sessionGeneration,
    required int requestStoreVersion,
  }) async {
    final totalStopwatch = Stopwatch()..start();
    final queryStopwatch = Stopwatch();
    final mapStopwatch = Stopwatch();
    try {
      queryStopwatch.start();
      final response = await _client.rpc(
        'get_current_user_bootstrap_decision',
      );
      queryStopwatch.stop();
      final row = _authoritativeDecisionRowFromResponse(response);
      if (row == null) {
        totalStopwatch.stop();
        return AuthoritativeBootstrapDecisionLoadResult(
          decision: null,
          error: const AuthoritativeBootstrapDecisionReadException(
            code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
            message: 'Authoritative bootstrap RPC returned no row.',
          ),
          totalDuration: totalStopwatch.elapsed,
          inflightWaitDuration: Duration.zero,
          remoteQueryDuration: queryStopwatch.elapsed,
          mapDuration: Duration.zero,
          remoteCallCount: 1,
          payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
        );
      }

      mapStopwatch.start();
      final decision = AuthoritativeBootstrapDecision.fromMap(
        row,
        expectedUserId: userId,
      );
      mapStopwatch.stop();
      final stale = !_isCurrentAuthoritativeBootstrapOperation(
        userId: userId,
        scopeUserId: scopeUserId,
        scopeEpoch: scopeEpoch,
        sessionGeneration: sessionGeneration,
      );
      totalStopwatch.stop();
      if (stale) {
        return AuthoritativeBootstrapDecisionLoadResult(
          decision: null,
          error: const AuthoritativeBootstrapDecisionReadException(
            code: AuthoritativeBootstrapDecisionFailureCode.staleResult,
            message: 'Stale authoritative bootstrap result discarded.',
          ),
          totalDuration: totalStopwatch.elapsed,
          inflightWaitDuration: Duration.zero,
          remoteQueryDuration: queryStopwatch.elapsed,
          mapDuration: mapStopwatch.elapsed,
          remoteCallCount: 1,
          payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
          staleResultDiscarded: true,
        );
      }
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: decision,
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
        staleResultDiscarded: stale,
      );
    } on AuthoritativeBootstrapDecisionParseException catch (error) {
      if (queryStopwatch.isRunning) queryStopwatch.stop();
      if (mapStopwatch.isRunning) mapStopwatch.stop();
      totalStopwatch.stop();
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: _authoritativeBootstrapDecisionErrorFromParse(
          error,
          responseKind: 'invalid_payload',
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
      );
    } on PostgrestException catch (error) {
      if (queryStopwatch.isRunning) queryStopwatch.stop();
      totalStopwatch.stop();
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: _authoritativeBootstrapDecisionErrorFromPostgrest(error),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: Duration.zero,
        remoteCallCount: 1,
        payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
      );
    } catch (error) {
      if (queryStopwatch.isRunning) queryStopwatch.stop();
      if (mapStopwatch.isRunning) mapStopwatch.stop();
      totalStopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[profile_repository] unexpected authoritative bootstrap fetch error: '
          '$error',
        );
      }
      return AuthoritativeBootstrapDecisionLoadResult(
        decision: null,
        error: AuthoritativeBootstrapDecisionReadException(
          code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
          message: 'Could not fetch authoritative bootstrap decision.',
          cause: error,
        ),
        totalDuration: totalStopwatch.elapsed,
        inflightWaitDuration: Duration.zero,
        remoteQueryDuration: queryStopwatch.elapsed,
        mapDuration: mapStopwatch.elapsed,
        remoteCallCount: 1,
        payloadColumnCount: _authoritativeBootstrapDecisionColumnCount,
      );
    }
  }

  String _bootstrapProfileDecisionInFlightKey({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
    required int sessionGeneration,
  }) {
    return '$userId|$scopeUserId|$scopeEpoch|$onboardingPolicyVersion|'
        '$sessionGeneration';
  }

  String _authoritativeBootstrapDecisionInFlightKey({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
    required int sessionGeneration,
  }) {
    return '$userId|$scopeUserId|$scopeEpoch|$onboardingPolicyVersion|'
        '$sessionGeneration';
  }

  Map<String, dynamic>? _authoritativeDecisionRowFromResponse(
      Object? response) {
    if (response == null) {
      return null;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response.cast<String, dynamic>());
    }
    if (response is List) {
      if (response.isEmpty) return null;
      if (response.length != 1) {
        throw const AuthoritativeBootstrapDecisionParseException(
          'Authoritative bootstrap RPC returned multiple rows.',
        );
      }
      final row = response.single;
      if (row is! Map) {
        throw const AuthoritativeBootstrapDecisionParseException(
          'Authoritative bootstrap RPC returned an invalid row.',
        );
      }
      return Map<String, dynamic>.from(row.cast<String, dynamic>());
    }
    throw const AuthoritativeBootstrapDecisionParseException(
      'Authoritative bootstrap RPC returned an invalid response.',
    );
  }

  bool _isCurrentAuthoritativeBootstrapOperation({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required int sessionGeneration,
  }) {
    final currentUserId = _currentUserId();
    return currentUserId == userId &&
        sessionGeneration == _bootstrapProfileDecisionSessionGeneration &&
        scopeUserId == userId &&
        scopeEpoch >= 0;
  }

  AuthoritativeBootstrapDecisionReadException
      _authoritativeBootstrapDecisionErrorFromPostgrest(
    PostgrestException error,
  ) {
    if (kDebugMode) {
      debugPrint(
        '[profile_repository] authoritative rpc error (${error.code}): '
        '${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == '42501') {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
        message: 'Could not fetch authoritative bootstrap decision.',
        cause: error,
      );
    }
    if (code == 'PGRST116') {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.emptyResponse,
        message: 'Authoritative bootstrap RPC returned no row.',
        cause: error,
      );
    }
    if (code == 'PGRST204' || code == '42703' || code == '42P01') {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.invalidPayload,
        message: 'Authoritative bootstrap RPC returned an invalid payload.',
        cause: error,
      );
    }

    final rawMessage = error.message.toLowerCase();
    if (rawMessage.contains('timeout') ||
        rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('connection')) {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
        message: 'Could not fetch authoritative bootstrap decision.',
        cause: error,
      );
    }

    return AuthoritativeBootstrapDecisionReadException(
      code: AuthoritativeBootstrapDecisionFailureCode.rpcUnavailable,
      message: 'Could not fetch authoritative bootstrap decision.',
      cause: error,
    );
  }

  AuthoritativeBootstrapDecisionReadException
      _authoritativeBootstrapDecisionErrorFromParse(
    AuthoritativeBootstrapDecisionParseException error, {
    required String responseKind,
  }) {
    final raw = error.message.toLowerCase();
    if (raw.contains('unknown decision')) {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.unknownDecision,
        message: error.message,
        cause: error,
      );
    }
    if (raw.contains('did not match the authenticated user') ||
        raw.contains('did not match current user')) {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.identityMismatch,
        message: error.message,
        cause: error,
      );
    }
    if (raw.contains('not coherent') ||
        raw.contains('violates the required onboarding policy')) {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.inconsistentContract,
        message: error.message,
        cause: error,
      );
    }
    if (raw.contains('unknown account_status') ||
        raw.contains('unknown profile_state') ||
        raw.contains('unknown onboarding_enforcement') ||
        raw.contains('missing required') ||
        raw.contains('invalid "') ||
        raw.contains('must be >= 1')) {
      return AuthoritativeBootstrapDecisionReadException(
        code: AuthoritativeBootstrapDecisionFailureCode.invalidPayload,
        message: error.message,
        cause: error,
      );
    }
    return AuthoritativeBootstrapDecisionReadException(
      code: AuthoritativeBootstrapDecisionFailureCode.invalidPayload,
      message: error.message.isEmpty
          ? 'Authoritative bootstrap RPC returned an invalid payload.'
          : error.message,
      cause: error,
    );
  }

  _BootstrapProfileDecisionMemoryRead _readBootstrapProfileDecisionMemoryEntry({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
  }) {
    final entry = _bootstrapProfileDecisionMemory[userId];
    if (entry == null) {
      return const _BootstrapProfileDecisionMemoryRead();
    }
    final reason = _validateBootstrapProfileDecisionMemoryEntry(
      entry,
      userId: userId,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
    );
    if (reason != null) {
      _bootstrapProfileDecisionMemory.remove(userId);
      return _BootstrapProfileDecisionMemoryRead(
        invalidationReason: reason,
      );
    }
    return _BootstrapProfileDecisionMemoryRead(entry: entry);
  }

  BootstrapProfileDecisionMemoryInvalidationReason?
      _validateBootstrapProfileDecisionMemoryEntry(
    BootstrapProfileDecisionMemoryEntry entry, {
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
  }) {
    if (entry.userId != userId || entry.decision.userId != userId) {
      return BootstrapProfileDecisionMemoryInvalidationReason.userMismatch;
    }
    if (entry.sessionGeneration != _bootstrapProfileDecisionSessionGeneration) {
      return BootstrapProfileDecisionMemoryInvalidationReason.sessionChanged;
    }
    if (entry.scopeUserId != scopeUserId) {
      return BootstrapProfileDecisionMemoryInvalidationReason.scopeChanged;
    }
    if (entry.scopeEpoch != scopeEpoch) {
      return BootstrapProfileDecisionMemoryInvalidationReason.epochChanged;
    }
    if (entry.onboardingPolicyVersion != onboardingPolicyVersion) {
      return BootstrapProfileDecisionMemoryInvalidationReason
          .onboardingVersionChanged;
    }
    try {
      entry.decision.toRemoteProfile();
    } on RemoteProfileParseException {
      return BootstrapProfileDecisionMemoryInvalidationReason.incompleteEntry;
    }
    return null;
  }

  bool _storeBootstrapProfileDecisionInMemory({
    required BootstrapProfileDecision decision,
    required String scopeUserId,
    required int scopeEpoch,
    required int onboardingPolicyVersion,
    required BootstrapProfileDecisionMemorySource source,
    required int sessionGeneration,
    required int requestStoreVersion,
  }) {
    if (sessionGeneration != _bootstrapProfileDecisionSessionGeneration) {
      return false;
    }
    try {
      decision.toRemoteProfile();
    } on RemoteProfileParseException {
      return false;
    }
    final current = _bootstrapProfileDecisionMemory[decision.userId];
    if (current != null && current.storeVersion > requestStoreVersion) {
      return false;
    }
    _bootstrapProfileDecisionMemory[decision.userId] =
        BootstrapProfileDecisionMemoryEntry(
      userId: decision.userId,
      decision: decision,
      sessionGeneration: sessionGeneration,
      scopeUserId: scopeUserId,
      scopeEpoch: scopeEpoch,
      onboardingPolicyVersion: onboardingPolicyVersion,
      source: source,
      storeVersion: requestStoreVersion,
    );
    return true;
  }

  Future<RepositoryResult<RemoteProfile>> ensureCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final existingResult = await fetchCurrentProfile();
    if (!existingResult.isSuccess) {
      return RepositoryResult<RemoteProfile>.failure(existingResult.error!);
    }

    final existingProfile = existingResult.data;
    if (existingProfile != null) {
      return RepositoryResult<RemoteProfile>.success(data: existingProfile);
    }

    return upsertCurrentProfile(
      email: email,
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  Future<RepositoryResult<RemoteProfile>> upsertCurrentProfile({
    String? email,
    String? displayName,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    final userId = user?.id.trim();
    if (user == null || userId == null || userId.isEmpty) {
      return RepositoryResult<RemoteProfile>.failure(_notAuthenticated());
    }

    final payload = <String, dynamic>{
      'email': _firstNonEmptyValue(
        email,
        user.email,
      ),
      'display_name': _firstNonEmptyValue(
        displayName,
        user.userMetadata?['display_name']?.toString(),
        user.userMetadata?['name']?.toString(),
      ),
      'avatar_url': _firstNonEmptyValue(
        avatarUrl,
        user.userMetadata?['avatar_url']?.toString(),
        user.userMetadata?['avatarUrl']?.toString(),
      ),
    }..removeWhere((_, value) => value == null);

    return _upsertScopedProfilePatch(
      user: user,
      patch: payload,
      fallbackMessage: 'Could not upsert profile.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updateProfileBasics({
    String? email,
    String? displayName,
    String? avatarUrl,
    bool clearAvatarUrl = false,
  }) {
    final patch = <String, dynamic>{};
    if (email != null) {
      patch['email'] = _nullableTrim(email);
    }
    if (displayName != null) {
      patch['display_name'] = _nullableTrim(displayName);
    }
    if (avatarUrl != null) {
      patch['avatar_url'] = _nullableTrim(avatarUrl);
    }
    if (clearAvatarUrl) {
      patch['avatar_url'] = null;
    }

    if (patch.isEmpty) {
      return ensureCurrentProfile();
    }

    return _upsertScopedProfilePatch(
      patch: patch,
      fallbackMessage: 'Could not update profile basics.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updatePreferredLanguage(
    String? languageCode,
  ) {
    final normalized = _nullableTrim(languageCode)?.toLowerCase();
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{'preferred_language_code': normalized},
      fallbackMessage: 'Could not update preferred language.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? dailyMotivationEnabled,
    bool? marketingNotificationsEnabled,
    String? dailyMotivationTime,
    bool includeDailyMotivationTime = false,
  }) {
    final patch = <String, dynamic>{};
    if (notificationsEnabled != null) {
      patch['notifications_enabled'] = notificationsEnabled;
    }
    if (dailyMotivationEnabled != null) {
      patch['daily_motivation_enabled'] = dailyMotivationEnabled;
    }
    if (marketingNotificationsEnabled != null) {
      patch['marketing_notifications_enabled'] = marketingNotificationsEnabled;
    }
    if (includeDailyMotivationTime) {
      patch['daily_motivation_time'] = _nullableTrim(dailyMotivationTime);
    }

    if (patch.isEmpty) {
      return ensureCurrentProfile();
    }

    return _upsertScopedProfilePatch(
      patch: patch,
      fallbackMessage: 'Could not update notification settings.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> touchLastLogin({
    DateTime? at,
  }) {
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{
        'last_login_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
      },
      fallbackMessage: 'Could not update last login.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> touchLastSeen({
    DateTime? at,
  }) {
    return _upsertScopedProfilePatch(
      patch: <String, dynamic>{
        'last_seen_at': (at ?? DateTime.now()).toUtc().toIso8601String(),
      },
      fallbackMessage: 'Could not update last seen.',
    );
  }

  Future<RepositoryResult<RemoteProfile>> markOnboardingInProgress({
    int onboardingVersion = 1,
  }) async {
    if (onboardingVersion < 1) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Onboarding version must be >= 1.',
        ),
      );
    }

    final currentResult = await _fetchRequiredCurrentProfile();
    if (!currentResult.isSuccess) {
      return RepositoryResult<RemoteProfile>.failure(currentResult.error!);
    }

    final current = currentResult.data!;
    if (current.onboardingStatus == OnboardingStatus.completed) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Cannot move completed onboarding back to in_progress.',
        ),
      );
    }
    if (onboardingVersion != current.onboardingVersion) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Onboarding version must match the current remote version.',
        ),
      );
    }

    final result = await _upsertScopedProfilePatch(
      patch: <String, dynamic>{
        'onboarding_status': OnboardingStatus.inProgress.toSupabase(),
        'onboarding_version': current.onboardingVersion,
        'onboarding_completed_at': null,
      },
      fallbackMessage: 'Could not mark onboarding in progress.',
    );
    invalidateBootstrapProfileDecisionMemory(
      userId: current.id,
      reason: BootstrapProfileDecisionMemoryInvalidationReason.profileMutation,
    );
    return result;
  }

  Future<_BootstrapProfileDecisionPersistentRead>
      _readBootstrapProfileDecisionPersistentEntry({
    required String userId,
    required String scopeUserId,
    required int onboardingPolicyVersion,
  }) async {
    try {
      final readResult = await _bootstrapProfileDecisionCache.read(userId);
      if (scopeUserId != userId) {
        return const _BootstrapProfileDecisionPersistentRead(
          validation: BootstrapProfileCacheValidation.userMismatch,
        );
      }
      final entry = readResult.entry;
      if (readResult.validation != BootstrapProfileCacheValidation.valid ||
          entry == null) {
        return _BootstrapProfileDecisionPersistentRead(
          validation: readResult.validation,
        );
      }
      if (entry.userId != userId || entry.decision.userId != userId) {
        return const _BootstrapProfileDecisionPersistentRead(
          validation: BootstrapProfileCacheValidation.userMismatch,
        );
      }
      if (entry.onboardingPolicyVersion != onboardingPolicyVersion) {
        return _BootstrapProfileDecisionPersistentRead(
          validation: BootstrapProfileCacheValidation.onboardingVersionMismatch,
          age: _cacheAge(entry),
        );
      }
      return _BootstrapProfileDecisionPersistentRead(
        validation: BootstrapProfileCacheValidation.valid,
        entry: entry,
        age: _cacheAge(entry),
      );
    } catch (_) {
      return const _BootstrapProfileDecisionPersistentRead(
        validation: BootstrapProfileCacheValidation.corrupt,
      );
    }
  }

  Duration? _cacheAge(CachedBootstrapProfileDecision entry) {
    final now = _nowProvider().toUtc();
    if (entry.remoteVerifiedAt.isAfter(now)) {
      return Duration.zero;
    }
    return now.difference(entry.remoteVerifiedAt);
  }

  BootstrapProfilePersistentCacheComparison _comparePersistentCacheWithDecision(
    CachedBootstrapProfileDecision? persistentEntry,
    BootstrapProfileDecision decision,
  ) {
    if (persistentEntry == null) {
      return BootstrapProfilePersistentCacheComparison.cacheMissing;
    }
    final cachedDecision = persistentEntry.decision;
    final matches = cachedDecision.userId == decision.userId &&
        cachedDecision.onboardingStatus == decision.onboardingStatus &&
        cachedDecision.onboardingVersion == decision.onboardingVersion &&
        cachedDecision.onboardingCompletedAt == decision.onboardingCompletedAt;
    return matches
        ? BootstrapProfilePersistentCacheComparison.match
        : BootstrapProfilePersistentCacheComparison.remoteNewerOrChanged;
  }

  BootstrapProfileDecisionCacheSource _persistentSourceFromMemorySource(
    BootstrapProfileDecisionMemorySource source,
  ) {
    switch (source) {
      case BootstrapProfileDecisionMemorySource.remoteDecision:
        return BootstrapProfileDecisionCacheSource.remoteDecision;
      case BootstrapProfileDecisionMemorySource.remoteProfile:
        return BootstrapProfileDecisionCacheSource.remoteProfile;
      case BootstrapProfileDecisionMemorySource.remoteProfileUpsert:
        return BootstrapProfileDecisionCacheSource.remoteProfileUpsert;
      case BootstrapProfileDecisionMemorySource.onboardingCompletion:
        return BootstrapProfileDecisionCacheSource.onboardingCompletion;
    }
  }

  BootstrapProfilePersistentCacheDeleteReason
      _persistentDeleteReasonFromMemoryReason(
    BootstrapProfileDecisionMemoryInvalidationReason reason,
  ) {
    switch (reason) {
      case BootstrapProfileDecisionMemoryInvalidationReason.userMismatch:
        return BootstrapProfilePersistentCacheDeleteReason.userMismatch;
      case BootstrapProfileDecisionMemoryInvalidationReason.sessionChanged:
      case BootstrapProfileDecisionMemoryInvalidationReason.scopeChanged:
      case BootstrapProfileDecisionMemoryInvalidationReason.epochChanged:
      case BootstrapProfileDecisionMemoryInvalidationReason
            .explicitInvalidation:
      case BootstrapProfileDecisionMemoryInvalidationReason
            .onboardingVersionChanged:
      case BootstrapProfileDecisionMemoryInvalidationReason.incompleteEntry:
        return BootstrapProfilePersistentCacheDeleteReason.staleOperation;
      case BootstrapProfileDecisionMemoryInvalidationReason.logout:
        return BootstrapProfilePersistentCacheDeleteReason.logout;
      case BootstrapProfileDecisionMemoryInvalidationReason.userChanged:
        return BootstrapProfilePersistentCacheDeleteReason.userChanged;
      case BootstrapProfileDecisionMemoryInvalidationReason.profileMutation:
        return BootstrapProfilePersistentCacheDeleteReason.profileMutation;
      case BootstrapProfileDecisionMemoryInvalidationReason
            .invalidRemoteResponse:
        return BootstrapProfilePersistentCacheDeleteReason.remoteInvalid;
    }
  }

  Future<bool> _writeBootstrapProfileDecisionPersistent({
    required BootstrapProfileDecision decision,
    required BootstrapProfileDecisionCacheSource source,
    required int onboardingPolicyVersion,
    required int sessionGeneration,
    required int requestStoreVersion,
    required String scopeUserId,
  }) async {
    if (sessionGeneration != _bootstrapProfileDecisionSessionGeneration) {
      return false;
    }
    if (decision.userId != _currentUserId()) {
      return false;
    }
    if (scopeUserId != decision.userId) {
      return false;
    }
    final current = _bootstrapProfileDecisionMemory[decision.userId];
    if (current != null && current.storeVersion > requestStoreVersion) {
      return false;
    }
    final entry = CachedBootstrapProfileDecision(
      cacheSchemaVersion: CachedBootstrapProfileDecision.currentSchemaVersion,
      userId: decision.userId,
      decision: decision,
      onboardingPolicyVersion: onboardingPolicyVersion,
      remoteVerifiedAt: _nowProvider().toUtc(),
      source: source,
    );
    _bootstrapProfileDecisionPersistentOperationVersionByUser[decision.userId] =
        requestStoreVersion;
    _bootstrapProfileDecisionPersistentLatestEntryByUser[decision.userId] =
        _BootstrapProfileDecisionPersistentIntent(
      entry: entry,
      storeVersion: requestStoreVersion,
      sessionGeneration: sessionGeneration,
    );
    try {
      await _bootstrapProfileDecisionCache.write(entry);
      final latestOperationVersion =
          _bootstrapProfileDecisionPersistentOperationVersionByUser[
              decision.userId];
      final latestIntent =
          _bootstrapProfileDecisionPersistentLatestEntryByUser[decision.userId];
      if (sessionGeneration != _bootstrapProfileDecisionSessionGeneration ||
          latestOperationVersion != requestStoreVersion ||
          latestIntent == null ||
          latestIntent.storeVersion != requestStoreVersion ||
          latestIntent.sessionGeneration != sessionGeneration) {
        await _restoreLatestPersistentIntentIfNeeded(
          userId: decision.userId,
          requestStoreVersion: requestStoreVersion,
        );
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteBootstrapProfileDecisionPersistent({
    required String userId,
    required int sessionGeneration,
    required int requestStoreVersion,
    required BootstrapProfilePersistentCacheDeleteReason reason,
  }) async {
    if (sessionGeneration != _bootstrapProfileDecisionSessionGeneration) {
      return false;
    }
    final current = _bootstrapProfileDecisionMemory[userId];
    if (current != null && current.storeVersion > requestStoreVersion) {
      return false;
    }
    _bootstrapProfileDecisionPersistentOperationVersionByUser[userId] =
        requestStoreVersion;
    _bootstrapProfileDecisionPersistentLatestEntryByUser.remove(userId);
    try {
      await _bootstrapProfileDecisionCache.delete(userId);
      final latestOperationVersion =
          _bootstrapProfileDecisionPersistentOperationVersionByUser[userId];
      if (latestOperationVersion != requestStoreVersion) {
        await _restoreLatestPersistentIntentIfNeeded(
          userId: userId,
          requestStoreVersion: requestStoreVersion,
        );
        return false;
      }
      return sessionGeneration == _bootstrapProfileDecisionSessionGeneration;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restoreLatestPersistentIntentIfNeeded({
    required String userId,
    required int requestStoreVersion,
  }) async {
    final latestIntent =
        _bootstrapProfileDecisionPersistentLatestEntryByUser[userId];
    if (latestIntent == null ||
        latestIntent.storeVersion <= requestStoreVersion) {
      try {
        await _bootstrapProfileDecisionCache.delete(userId);
      } catch (_) {}
      return;
    }
    try {
      await _bootstrapProfileDecisionCache.write(latestIntent.entry);
    } catch (_) {}
  }

  Future<void> _safeDeletePersistentBootstrapProfileDecisionCache({
    required String userId,
    required BootstrapProfilePersistentCacheDeleteReason reason,
  }) async {
    try {
      await _bootstrapProfileDecisionCache.delete(userId);
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[profile_repository] bootstrap decision persistent delete failed '
          'reason=${reason.name}',
        );
      }
    }
  }

  Future<void> _safeClearPersistentBootstrapProfileDecisionCache() async {
    try {
      await _bootstrapProfileDecisionCache.clear();
    } catch (_) {
      if (kDebugMode) {
        debugPrint(
          '[profile_repository] bootstrap decision persistent clear failed',
        );
      }
    }
  }

  Future<RepositoryResult<RemoteProfile>> markOnboardingCompleted({
    int onboardingVersion = 1,
  }) async {
    if (onboardingVersion < 1) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Onboarding version must be >= 1.',
        ),
      );
    }

    final currentResult = await _fetchRequiredCurrentProfile();
    if (!currentResult.isSuccess) {
      return RepositoryResult<RemoteProfile>.failure(currentResult.error!);
    }

    final current = currentResult.data!;
    if (onboardingVersion != current.onboardingVersion) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: 'Onboarding version must match the current remote version.',
        ),
      );
    }

    return _updateScopedProfilePatch(
      patch: <String, dynamic>{
        'onboarding_status': OnboardingStatus.completed.toSupabase(),
        'onboarding_version': current.onboardingVersion,
      },
      fallbackMessage: 'Could not mark onboarding completed.',
    );
  }

  /// Legacy compatibility method for existing callers that still expect a map.
  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final result = await fetchCurrentProfile();
    if (!result.isSuccess || result.data == null) return null;
    return result.data!.toMap();
  }

  Future<RepositoryResult<RemoteProfile>> _upsertScopedProfilePatch({
    required Map<String, dynamic> patch,
    required String fallbackMessage,
    User? user,
  }) async {
    final activeUser = user ?? currentUser;
    final userId = user?.id.trim() ?? _currentUserId();
    if (userId == null || userId.isEmpty) {
      return RepositoryResult<RemoteProfile>.failure(_notAuthenticated());
    }

    var payload = <String, dynamic>{
      'id': userId,
      ...patch,
    };

    // Keep email best-effort for row creation safety when the column exists.
    if (!payload.containsKey('email')) {
      final fallbackEmail = _nullableTrim(activeUser?.email);
      if (fallbackEmail != null) {
        payload['email'] = fallbackEmail;
      }
    }

    payload = _removeKnownUnsupportedColumns(payload);
    if (!payload.containsKey('id')) {
      payload['id'] = userId;
    }

    var droppedColumns = 0;

    while (true) {
      try {
        final row = await _client
            .from(_profilesTable)
            .upsert(payload, onConflict: 'id')
            .select()
            .single();
        final profile = RemoteProfile.fromMap(Map<String, dynamic>.from(row));
        if (profile.id != userId) {
          return RepositoryResult<RemoteProfile>.failure(
            RepositoryError(
              code: RepositoryErrorCode.invalidResponse,
              message: 'Profile upsert response did not match current user.',
            ),
          );
        }
        return RepositoryResult<RemoteProfile>.success(data: profile);
      } on RemoteProfileParseException catch (error) {
        return RepositoryResult<RemoteProfile>.failure(
          RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: error.message,
            cause: error,
          ),
        );
      } on PostgrestException catch (error) {
        final missingColumn = _extractMissingColumn(error);
        final canRetryWithColumnDropped = missingColumn != null &&
            missingColumn != 'id' &&
            payload.containsKey(missingColumn) &&
            droppedColumns < _maxRetryableColumnDrops;

        if (canRetryWithColumnDropped) {
          droppedColumns += 1;
          _unsupportedColumns.add(missingColumn);
          payload = Map<String, dynamic>.from(payload)
            ..remove(missingColumn)
            ..['id'] = userId;
          if (kDebugMode) {
            debugPrint(
              '[profile_repository] ignoring unsupported column "$missingColumn" for profiles upsert',
            );
          }
          continue;
        }

        return RepositoryResult<RemoteProfile>.failure(
          _mapPostgrestError(
            error,
            fallbackMessage: fallbackMessage,
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[profile_repository] unexpected upsert error: $error');
        }
        return RepositoryResult<RemoteProfile>.failure(
          _mapUnexpectedError(
            error,
            fallbackMessage: fallbackMessage,
          ),
        );
      }
    }
  }

  Future<RepositoryResult<RemoteProfile>> _updateScopedProfilePatch({
    required Map<String, dynamic> patch,
    required String fallbackMessage,
  }) async {
    final userId = _currentUserId();
    if (userId == null || userId.isEmpty) {
      return RepositoryResult<RemoteProfile>.failure(_notAuthenticated());
    }

    final payload = _removeKnownUnsupportedColumns(patch);

    try {
      final row = await _client
          .from(_profilesTable)
          .update(payload)
          .eq('id', userId)
          .select()
          .single();
      final profile = RemoteProfile.fromMap(Map<String, dynamic>.from(row));
      if (profile.id != userId) {
        return RepositoryResult<RemoteProfile>.failure(
          RepositoryError(
            code: RepositoryErrorCode.invalidResponse,
            message: 'Profile update response did not match current user.',
          ),
        );
      }
      return RepositoryResult<RemoteProfile>.success(data: profile);
    } on RemoteProfileParseException catch (error) {
      return RepositoryResult<RemoteProfile>.failure(
        RepositoryError(
          code: RepositoryErrorCode.invalidResponse,
          message: error.message,
          cause: error,
        ),
      );
    } on PostgrestException catch (error) {
      return RepositoryResult<RemoteProfile>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: fallbackMessage,
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[profile_repository] unexpected update error: $error');
      }
      return RepositoryResult<RemoteProfile>.failure(
        _mapUnexpectedError(
          error,
          fallbackMessage: fallbackMessage,
        ),
      );
    }
  }

  Map<String, dynamic> _removeKnownUnsupportedColumns(
    Map<String, dynamic> payload,
  ) {
    if (_unsupportedColumns.isEmpty) return payload;

    final filtered = Map<String, dynamic>.from(payload);
    for (final key in _unsupportedColumns) {
      if (key == 'id') continue;
      filtered.remove(key);
    }
    return filtered;
  }

  String? _extractMissingColumn(PostgrestException error) {
    final combined = [
      error.message,
      error.details,
      error.hint,
    ].whereType<String>().join('\n');

    final patterns = <RegExp>[
      RegExp(r'column\s+"([a-zA-Z0-9_]+)"', caseSensitive: false),
      RegExp(r"column\s+'([a-zA-Z0-9_]+)'", caseSensitive: false),
      RegExp(r"'([a-zA-Z0-9_]+)'\s+column", caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(combined);
      final column = match?.group(1)?.trim();
      if (column != null && column.isNotEmpty) {
        return column;
      }
    }
    return null;
  }

  String? _currentUserId() {
    final userId = (_currentUserIdProvider?.call() ?? currentUser?.id)?.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  Future<RepositoryResult<RemoteProfile>> _fetchRequiredCurrentProfile() async {
    final result = await fetchCurrentProfile();
    if (!result.isSuccess) {
      return RepositoryResult<RemoteProfile>.failure(result.error!);
    }
    final profile = result.data;
    if (profile == null) {
      return RepositoryResult<RemoteProfile>.failure(
        const RepositoryError(
          code: RepositoryErrorCode.notFound,
          message: 'Profile row was not found.',
        ),
      );
    }
    return RepositoryResult<RemoteProfile>.success(data: profile);
  }

  RepositoryError _notAuthenticated() {
    return const RepositoryError(
      code: RepositoryErrorCode.notAuthenticated,
      message: 'No authenticated user session is available.',
    );
  }

  String? _firstNonEmptyValue(String? first, [String? second, String? third]) {
    final values = <String?>[first, second, third];
    for (final value in values) {
      final normalized = _nullableTrim(value);
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  RepositoryError _mapPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[profile_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Profile row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for profile operation.',
        cause: error,
      );
    }
    if (code == '42703' || code == 'PGRST204') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: 'Profile schema is missing one or more expected columns.',
        cause: error,
      );
    }

    final rawMessage = error.message.toLowerCase();
    if (rawMessage.contains('invalid onboarding transition') ||
        rawMessage.contains('onboarding_version')) {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message: error.message,
        cause: error,
      );
    }
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: 'Network error while accessing profile data.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }

  RepositoryError _mapUnexpectedError(
    Object error, {
    required String fallbackMessage,
  }) {
    final rawMessage = error.toString().toLowerCase();
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection') ||
        rawMessage.contains('failed host lookup')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: 'Network error while accessing profile data.',
        cause: error,
      );
    }

    return RepositoryError(
      code: RepositoryErrorCode.unknown,
      message: fallbackMessage,
      cause: error,
    );
  }
}

@immutable
class _BootstrapProfileDecisionMemoryRead {
  const _BootstrapProfileDecisionMemoryRead({
    this.entry,
    this.invalidationReason,
  });

  final BootstrapProfileDecisionMemoryEntry? entry;
  final BootstrapProfileDecisionMemoryInvalidationReason? invalidationReason;
}
