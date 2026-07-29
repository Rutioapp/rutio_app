import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote/authoritative_bootstrap_decision.dart';
import '../models/remote/remote_profile.dart';

const int authoritativeBootstrapCacheSchemaVersionV2 = 2;
const Duration authoritativeBootstrapCacheDefaultTtl = Duration(hours: 6);
const Duration authoritativeBootstrapCacheFutureSkewTolerance =
    Duration(minutes: 5);

enum AuthoritativeBootstrapCacheReadStatusV2 {
  hit,
  notFound,
  expired,
  schemaMismatch,
  userMismatch,
  environmentMismatch,
  scopeMismatch,
  corrupt,
  contractInvalid,
  unknownEnum,
  storageError,
}

@immutable
class AuthoritativeBootstrapCacheEntryV2 {
  const AuthoritativeBootstrapCacheEntryV2({
    required this.schemaVersion,
    required this.userId,
    required this.environmentId,
    required this.scopeKey,
    required this.cachedAt,
    required this.expiresAt,
    required this.destination,
    required this.accountStatus,
    required this.profileState,
    required this.onboardingEnforcement,
    required this.requiredOnboardingVersion,
    required this.completedOnboardingVersion,
    required this.onboardingStatus,
    required this.onboardingCompletedAt,
    required this.profileRevision,
    required this.policyRevision,
  });

  factory AuthoritativeBootstrapCacheEntryV2.fromAuthoritativeDecision({
    required AuthoritativeBootstrapDecision decision,
    required String environmentId,
    required String scopeKey,
    required DateTime cachedAt,
    Duration ttl = authoritativeBootstrapCacheDefaultTtl,
  }) {
    final normalizedCachedAt = cachedAt.toUtc();
    final normalizedTtl = ttl.isNegative ? Duration.zero : ttl;
    final completedVersion = decision.completedOnboardingVersion ?? 0;
    return AuthoritativeBootstrapCacheEntryV2(
      schemaVersion: authoritativeBootstrapCacheSchemaVersionV2,
      userId: decision.userId,
      environmentId: _normalizeRequiredField(environmentId, 'environmentId'),
      scopeKey: _normalizeRequiredField(scopeKey, 'scopeKey'),
      cachedAt: normalizedCachedAt,
      expiresAt: normalizedCachedAt.add(normalizedTtl),
      destination: decision.decision,
      accountStatus: decision.accountStatus,
      profileState: decision.profileState,
      onboardingEnforcement: decision.onboardingEnforcement,
      requiredOnboardingVersion: decision.requiredOnboardingVersion,
      completedOnboardingVersion: completedVersion,
      onboardingStatus: decision.onboardingStatus,
      onboardingCompletedAt: decision.onboardingCompletedAt,
      profileRevision: decision.profileRevision,
      policyRevision: decision.policyRevision,
    );
  }

  final int schemaVersion;
  final String userId;
  final String environmentId;
  final String scopeKey;
  final DateTime cachedAt;
  final DateTime expiresAt;
  final AuthoritativeBootstrapDestination destination;
  final BootstrapAccountStatus accountStatus;
  final BootstrapProfileState profileState;
  final BootstrapOnboardingEnforcement onboardingEnforcement;
  final int requiredOnboardingVersion;
  final int completedOnboardingVersion;
  final OnboardingStatus? onboardingStatus;
  final DateTime? onboardingCompletedAt;
  final int profileRevision;
  final int policyRevision;

  bool matchesScopeKey(String expectedScopeKey) {
    return scopeKey == expectedScopeKey.trim();
  }

  bool isExpiredAt(DateTime now) {
    return !now.toUtc().isBefore(expiresAt.toUtc());
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'userId': userId,
      'environmentId': environmentId,
      'scopeKey': scopeKey,
      'cachedAt': cachedAt.toUtc().toIso8601String(),
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'destination': _destinationToStorageValue(destination),
      'accountStatus': _accountStatusToStorageValue(accountStatus),
      'profileState': _profileStateToStorageValue(profileState),
      'onboardingEnforcement':
          _onboardingEnforcementToStorageValue(onboardingEnforcement),
      'requiredOnboardingVersion': requiredOnboardingVersion,
      'completedOnboardingVersion': completedOnboardingVersion,
      'onboardingStatus': onboardingStatus?.toSupabase(),
      'onboardingCompletedAt': onboardingCompletedAt?.toUtc().toIso8601String(),
      'profileRevision': profileRevision,
      'policyRevision': policyRevision,
    };
  }
}

@immutable
class AuthoritativeBootstrapCacheReadResultV2 {
  const AuthoritativeBootstrapCacheReadResultV2({
    required this.status,
    this.entry,
  });

  const AuthoritativeBootstrapCacheReadResultV2.hit(this.entry)
      : status = AuthoritativeBootstrapCacheReadStatusV2.hit;

  const AuthoritativeBootstrapCacheReadResultV2.notFound()
      : status = AuthoritativeBootstrapCacheReadStatusV2.notFound,
        entry = null;

  final AuthoritativeBootstrapCacheReadStatusV2 status;
  final AuthoritativeBootstrapCacheEntryV2? entry;

  bool get isHit => status == AuthoritativeBootstrapCacheReadStatusV2.hit;
}

class AuthoritativeBootstrapCacheCodecV2 {
  const AuthoritativeBootstrapCacheCodecV2({
    required DateTime Function() nowProvider,
    this.ttl = authoritativeBootstrapCacheDefaultTtl,
    this.futureSkewTolerance = authoritativeBootstrapCacheFutureSkewTolerance,
  }) : _nowProvider = nowProvider;

  final DateTime Function() _nowProvider;
  final Duration ttl;
  final Duration futureSkewTolerance;

  Map<String, dynamic> encode(AuthoritativeBootstrapCacheEntryV2 entry) {
    return entry.toJson();
  }

  AuthoritativeBootstrapCacheReadResultV2 decode(
    Object? raw, {
    required String expectedUserId,
    required String expectedEnvironmentId,
    required String expectedScopeKey,
  }) {
    if (raw == null) {
      return const AuthoritativeBootstrapCacheReadResultV2.notFound();
    }

    final rawMap = _readJsonObject(raw);
    if (rawMap == null) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.corrupt,
      );
    }

    try {
      final entry = _decodeEntry(
        rawMap,
        expectedUserId: expectedUserId,
        expectedEnvironmentId: expectedEnvironmentId,
        expectedScopeKey: expectedScopeKey,
      );
      if (entry.isExpiredAt(_nowProvider().toUtc())) {
        return AuthoritativeBootstrapCacheReadResultV2(
          status: AuthoritativeBootstrapCacheReadStatusV2.expired,
          entry: entry,
        );
      }
      return AuthoritativeBootstrapCacheReadResultV2.hit(entry);
    } on _AuthoritativeBootstrapCacheSchemaMismatch catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.schemaMismatch,
      );
    } on _AuthoritativeBootstrapCacheUserMismatch catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.userMismatch,
      );
    } on _AuthoritativeBootstrapCacheEnvironmentMismatch catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.environmentMismatch,
      );
    } on _AuthoritativeBootstrapCacheScopeMismatch catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.scopeMismatch,
      );
    } on _AuthoritativeBootstrapCacheUnknownEnum catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.unknownEnum,
      );
    } on _AuthoritativeBootstrapCacheContractInvalid catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.contractInvalid,
      );
    } catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.corrupt,
      );
    }
  }

  AuthoritativeBootstrapCacheEntryV2 _decodeEntry(
    Map<String, dynamic> raw, {
    required String expectedUserId,
    required String expectedEnvironmentId,
    required String expectedScopeKey,
  }) {
    final schemaVersion = _readRequiredInt(raw['schemaVersion']);
    if (schemaVersion == null || schemaVersion < 0) {
      throw const _AuthoritativeBootstrapCacheSchemaMismatch();
    }
    if (schemaVersion != authoritativeBootstrapCacheSchemaVersionV2) {
      throw const _AuthoritativeBootstrapCacheSchemaMismatch();
    }

    final userId = _readRequiredString(raw['userId']);
    if (userId == null) {
      throw const _AuthoritativeBootstrapCacheUserMismatch();
    }
    if (userId != expectedUserId.trim()) {
      throw const _AuthoritativeBootstrapCacheUserMismatch();
    }

    final environmentId = _readRequiredString(raw['environmentId']);
    if (environmentId == null) {
      throw const _AuthoritativeBootstrapCacheEnvironmentMismatch();
    }
    if (environmentId != expectedEnvironmentId.trim()) {
      throw const _AuthoritativeBootstrapCacheEnvironmentMismatch();
    }

    final scopeKey = _readRequiredString(raw['scopeKey']);
    if (scopeKey == null) {
      throw const _AuthoritativeBootstrapCacheContractInvalid();
    }
    if (scopeKey != expectedScopeKey.trim()) {
      throw const _AuthoritativeBootstrapCacheScopeMismatch();
    }

    final cachedAt = _readRequiredDateTime(raw['cachedAt']);
    final expiresAt = _readRequiredDateTime(raw['expiresAt']);
    if (cachedAt == null || expiresAt == null) {
      throw const _AuthoritativeBootstrapCacheContractInvalid();
    }
    final now = _nowProvider().toUtc();
    if (cachedAt.isAfter(now.add(futureSkewTolerance))) {
      throw const _AuthoritativeBootstrapCacheContractInvalid();
    }
    if (!expiresAt.isAfter(cachedAt)) {
      throw const _AuthoritativeBootstrapCacheContractInvalid();
    }
    if (expiresAt.isAfter(cachedAt.add(ttl))) {
      throw const _AuthoritativeBootstrapCacheContractInvalid();
    }

    final destination = _parseDestination(raw['destination']);
    final accountStatus = _parseAccountStatus(raw['accountStatus']);
    final profileState = _parseProfileState(raw['profileState']);
    final onboardingEnforcement =
        _parseOnboardingEnforcement(raw['onboardingEnforcement']);
    final requiredOnboardingVersion =
        _readRequiredNonNegativeInt(raw['requiredOnboardingVersion']);
    final completedOnboardingVersion =
        _readRequiredNonNegativeInt(raw['completedOnboardingVersion']);
    final onboardingStatus = _parseOnboardingStatus(raw['onboardingStatus']);
    final onboardingCompletedAt =
        _readNullableDateTime(raw['onboardingCompletedAt']);
    final profileRevision = _readRequiredNonNegativeInt(raw['profileRevision']);
    final policyRevision = _readRequiredNonNegativeInt(raw['policyRevision']);

    _validateCoherence(
      destination: destination,
      accountStatus: accountStatus,
      profileState: profileState,
      onboardingEnforcement: onboardingEnforcement,
      requiredOnboardingVersion: requiredOnboardingVersion,
      completedOnboardingVersion: completedOnboardingVersion,
      onboardingStatus: onboardingStatus,
      onboardingCompletedAt: onboardingCompletedAt,
      profileRevision: profileRevision,
      policyRevision: policyRevision,
    );

    return AuthoritativeBootstrapCacheEntryV2(
      schemaVersion: schemaVersion,
      userId: userId,
      environmentId: environmentId,
      scopeKey: scopeKey,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
      destination: destination,
      accountStatus: accountStatus,
      profileState: profileState,
      onboardingEnforcement: onboardingEnforcement,
      requiredOnboardingVersion: requiredOnboardingVersion,
      completedOnboardingVersion: completedOnboardingVersion,
      onboardingStatus: onboardingStatus,
      onboardingCompletedAt: onboardingCompletedAt,
      profileRevision: profileRevision,
      policyRevision: policyRevision,
    );
  }
}

abstract interface class AuthoritativeBootstrapCacheStorageV2 {
  Future<AuthoritativeBootstrapCacheReadResultV2> read(
    String userId, {
    required String expectedScopeKey,
  });

  Future<void> write(AuthoritativeBootstrapCacheEntryV2 entry);

  Future<void> deleteForUser(String userId);

  Future<void> clear();
}

class SharedPreferencesAuthoritativeBootstrapCacheV2
    implements AuthoritativeBootstrapCacheStorageV2 {
  SharedPreferencesAuthoritativeBootstrapCacheV2({
    String? environmentId,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    DateTime Function()? nowProvider,
    Duration ttl = authoritativeBootstrapCacheDefaultTtl,
    Duration futureSkewTolerance =
        authoritativeBootstrapCacheFutureSkewTolerance,
  })  : _environmentId = _normalizeEnvironmentId(environmentId),
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _codec = AuthoritativeBootstrapCacheCodecV2(
          nowProvider: nowProvider ?? DateTime.now,
          ttl: ttl,
          futureSkewTolerance: futureSkewTolerance,
        );

  static const String _storagePrefix =
      'rutio_authoritative_bootstrap_cache_v2_';

  final String _environmentId;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final AuthoritativeBootstrapCacheCodecV2 _codec;

  String storageKeyForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }
    return '${_storagePrefixForEnvironment()}${_safeKeyFragment(normalizedUserId)}';
  }

  @override
  Future<AuthoritativeBootstrapCacheReadResultV2> read(
    String userId, {
    required String expectedScopeKey,
  }) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      return const AuthoritativeBootstrapCacheReadResultV2.notFound();
    }

    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(storageKeyForUser(normalizedUserId));
      return _codec.decode(
        raw,
        expectedUserId: normalizedUserId,
        expectedEnvironmentId: _environmentId,
        expectedScopeKey: expectedScopeKey,
      );
    } on AuthoritativeBootstrapCacheStorageException {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.storageError,
      );
    } catch (_) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.storageError,
      );
    }
  }

  @override
  Future<void> write(AuthoritativeBootstrapCacheEntryV2 entry) async {
    final normalizedUserId = _normalizeUserId(entry.userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(entry.userId, 'entry.userId');
    }
    if (normalizedUserId != entry.userId) {
      throw ArgumentError.value(entry.userId, 'entry.userId');
    }
    if (entry.environmentId != _environmentId) {
      throw ArgumentError.value(
        entry.environmentId,
        'entry.environmentId',
        'Entry environment does not match storage environment.',
      );
    }
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      storageKeyForUser(normalizedUserId),
      jsonEncode(_codec.encode(entry)),
    );
  }

  @override
  Future<void> deleteForUser(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(storageKeyForUser(normalizedUserId));
  }

  @override
  Future<void> clear() async {
    final prefs = await _sharedPreferencesProvider();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_storagePrefixForEnvironment())) {
        await prefs.remove(key);
      }
    }
  }

  String _storagePrefixForEnvironment() {
    return '$_storagePrefix${_safeKeyFragment(_environmentId)}_';
  }
}

class InMemoryAuthoritativeBootstrapCacheV2
    implements AuthoritativeBootstrapCacheStorageV2 {
  final Map<String, AuthoritativeBootstrapCacheEntryV2> _entries =
      <String, AuthoritativeBootstrapCacheEntryV2>{};
  final Set<String> _deleteFailures = <String>{};
  final Set<String> _readFailures = <String>{};
  final Set<String> _writeFailures = <String>{};

  void failReadsForUser(String userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) return;
    _readFailures.add(normalized);
  }

  void failWritesForUser(String userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) return;
    _writeFailures.add(normalized);
  }

  void failDeletesForUser(String userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) return;
    _deleteFailures.add(normalized);
  }

  AuthoritativeBootstrapCacheEntryV2? peek(String userId) {
    final normalized = _normalizeUserId(userId);
    if (normalized == null) return null;
    return _entries[normalized];
  }

  @override
  Future<AuthoritativeBootstrapCacheReadResultV2> read(
    String userId, {
    required String expectedScopeKey,
  }) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      return const AuthoritativeBootstrapCacheReadResultV2.notFound();
    }
    if (_readFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache read failure for $normalizedUserId');
    }
    final entry = _entries[normalizedUserId];
    if (entry == null) {
      return const AuthoritativeBootstrapCacheReadResultV2.notFound();
    }
    if (!entry.matchesScopeKey(expectedScopeKey)) {
      return const AuthoritativeBootstrapCacheReadResultV2(
        status: AuthoritativeBootstrapCacheReadStatusV2.scopeMismatch,
      );
    }
    return AuthoritativeBootstrapCacheReadResultV2.hit(entry);
  }

  @override
  Future<void> write(AuthoritativeBootstrapCacheEntryV2 entry) async {
    final normalizedUserId = _normalizeUserId(entry.userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(entry.userId, 'entry.userId');
    }
    if (_writeFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache write failure for $normalizedUserId');
    }
    _entries[normalizedUserId] = entry;
  }

  @override
  Future<void> deleteForUser(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    if (_deleteFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache delete failure for $normalizedUserId');
    }
    _entries.remove(normalizedUserId);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }
}

class AuthoritativeBootstrapCacheStorageException implements Exception {
  const AuthoritativeBootstrapCacheStorageException([this.message]);

  final String? message;
}

void _validateCoherence({
  required AuthoritativeBootstrapDestination destination,
  required BootstrapAccountStatus accountStatus,
  required BootstrapProfileState profileState,
  required BootstrapOnboardingEnforcement onboardingEnforcement,
  required int requiredOnboardingVersion,
  required int completedOnboardingVersion,
  required OnboardingStatus? onboardingStatus,
  required DateTime? onboardingCompletedAt,
  required int profileRevision,
  required int policyRevision,
}) {
  if (requiredOnboardingVersion < 0 ||
      completedOnboardingVersion < 0 ||
      profileRevision < 0 ||
      policyRevision < 0) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }

  switch (destination) {
    case AuthoritativeBootstrapDestination.home:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready ||
          onboardingStatus != OnboardingStatus.completed ||
          onboardingCompletedAt == null ||
          completedOnboardingVersion < requiredOnboardingVersion) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      if (onboardingEnforcement == BootstrapOnboardingEnforcement.required &&
          completedOnboardingVersion < requiredOnboardingVersion) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
    case AuthoritativeBootstrapDestination.onboarding:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready ||
          onboardingStatus == null) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      if (onboardingStatus == OnboardingStatus.completed) {
        if (completedOnboardingVersion < requiredOnboardingVersion ||
            onboardingCompletedAt == null) {
          throw const _AuthoritativeBootstrapCacheContractInvalid();
        }
        return;
      }
      if (onboardingStatus != OnboardingStatus.pending &&
          onboardingStatus != OnboardingStatus.inProgress) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      if (completedOnboardingVersion != 0 || onboardingCompletedAt != null) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
    case AuthoritativeBootstrapDestination.profileUninitialized:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.uninitialized ||
          onboardingStatus != null ||
          completedOnboardingVersion != 0 ||
          onboardingCompletedAt != null) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
    case AuthoritativeBootstrapDestination.profileDeleted:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.deleted ||
          onboardingStatus != null ||
          completedOnboardingVersion != 0 ||
          onboardingCompletedAt != null) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
    case AuthoritativeBootstrapDestination.accountSuspended:
    case AuthoritativeBootstrapDestination.accountPendingDeletion:
      if (accountStatus == BootstrapAccountStatus.active ||
          onboardingStatus != null ||
          completedOnboardingVersion != 0 ||
          onboardingCompletedAt != null) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
    case AuthoritativeBootstrapDestination.invalidProfile:
      if (accountStatus != BootstrapAccountStatus.active ||
          profileState != BootstrapProfileState.ready) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      final pendingInconsistent = onboardingStatus == null ||
          (onboardingStatus == OnboardingStatus.completed &&
              (completedOnboardingVersion < requiredOnboardingVersion ||
                  onboardingCompletedAt == null)) ||
          ((onboardingStatus == OnboardingStatus.pending ||
                  onboardingStatus == OnboardingStatus.inProgress) &&
              onboardingCompletedAt != null);
      if (!pendingInconsistent) {
        throw const _AuthoritativeBootstrapCacheContractInvalid();
      }
      return;
  }
}

AuthoritativeBootstrapDestination _parseDestination(Object? value) {
  final normalized = _readRequiredString(value);
  if (normalized == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  try {
    return AuthoritativeBootstrapDestination.fromSupabase(normalized);
  } on AuthoritativeBootstrapDecisionParseException {
    throw const _AuthoritativeBootstrapCacheUnknownEnum();
  }
}

BootstrapAccountStatus _parseAccountStatus(Object? value) {
  final normalized = _readRequiredString(value);
  if (normalized == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  try {
    return BootstrapAccountStatus.fromSupabase(normalized);
  } on AuthoritativeBootstrapDecisionParseException {
    throw const _AuthoritativeBootstrapCacheUnknownEnum();
  }
}

BootstrapProfileState _parseProfileState(Object? value) {
  final normalized = _readRequiredString(value);
  if (normalized == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  try {
    return BootstrapProfileState.fromSupabase(normalized);
  } on AuthoritativeBootstrapDecisionParseException {
    throw const _AuthoritativeBootstrapCacheUnknownEnum();
  }
}

BootstrapOnboardingEnforcement _parseOnboardingEnforcement(Object? value) {
  final normalized = _readRequiredString(value);
  if (normalized == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  try {
    return BootstrapOnboardingEnforcement.fromSupabase(normalized);
  } on AuthoritativeBootstrapDecisionParseException {
    throw const _AuthoritativeBootstrapCacheUnknownEnum();
  }
}

OnboardingStatus? _parseOnboardingStatus(Object? value) {
  final normalized = _readOptionalString(value);
  if (normalized == null) return null;
  try {
    return OnboardingStatus.fromSupabase(normalized);
  } on RemoteProfileParseException {
    throw const _AuthoritativeBootstrapCacheUnknownEnum();
  }
}

Map<String, dynamic>? _readJsonObject(Object? raw) {
  if (raw is Map<String, dynamic>) {
    return raw;
  }
  if (raw is Map) {
    return Map<String, dynamic>.from(raw.cast<String, dynamic>());
  }
  if (raw is String) {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded.cast<String, dynamic>());
    }
  }
  return null;
}

String? _readRequiredString(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

String? _readOptionalString(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _readRequiredInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

int _readRequiredNonNegativeInt(Object? value) {
  final parsed = _readRequiredInt(value);
  if (parsed == null || parsed < 0) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  return parsed;
}

DateTime? _readRequiredDateTime(Object? value) {
  final normalized = _readRequiredString(value);
  if (normalized == null) return null;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  return parsed.toUtc();
}

DateTime? _readNullableDateTime(Object? value) {
  final normalized = _readOptionalString(value);
  if (normalized == null) return null;
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) {
    throw const _AuthoritativeBootstrapCacheContractInvalid();
  }
  return parsed.toUtc();
}

String _destinationToStorageValue(
    AuthoritativeBootstrapDestination destination) {
  switch (destination) {
    case AuthoritativeBootstrapDestination.home:
      return 'home';
    case AuthoritativeBootstrapDestination.onboarding:
      return 'onboarding';
    case AuthoritativeBootstrapDestination.profileUninitialized:
      return 'profile_uninitialized';
    case AuthoritativeBootstrapDestination.profileDeleted:
      return 'profile_deleted';
    case AuthoritativeBootstrapDestination.accountSuspended:
      return 'account_suspended';
    case AuthoritativeBootstrapDestination.accountPendingDeletion:
      return 'account_pending_deletion';
    case AuthoritativeBootstrapDestination.invalidProfile:
      return 'invalid_profile';
  }
}

String _accountStatusToStorageValue(BootstrapAccountStatus status) {
  switch (status) {
    case BootstrapAccountStatus.active:
      return 'active';
    case BootstrapAccountStatus.suspended:
      return 'suspended';
    case BootstrapAccountStatus.pendingDeletion:
      return 'pending_deletion';
  }
}

String _profileStateToStorageValue(BootstrapProfileState state) {
  switch (state) {
    case BootstrapProfileState.uninitialized:
      return 'uninitialized';
    case BootstrapProfileState.ready:
      return 'ready';
    case BootstrapProfileState.deleted:
      return 'deleted';
  }
}

String _onboardingEnforcementToStorageValue(
  BootstrapOnboardingEnforcement enforcement,
) {
  switch (enforcement) {
    case BootstrapOnboardingEnforcement.advisory:
      return 'advisory';
    case BootstrapOnboardingEnforcement.required:
      return 'required';
  }
}

String? _normalizeUserId(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

String _normalizeEnvironmentId(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? 'default' : normalized;
}

String _normalizeRequiredField(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, '$name must not be empty.');
  }
  return normalized;
}

String _safeKeyFragment(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
}

class _AuthoritativeBootstrapCacheSchemaMismatch implements Exception {
  const _AuthoritativeBootstrapCacheSchemaMismatch();
}

class _AuthoritativeBootstrapCacheUserMismatch implements Exception {
  const _AuthoritativeBootstrapCacheUserMismatch();
}

class _AuthoritativeBootstrapCacheEnvironmentMismatch implements Exception {
  const _AuthoritativeBootstrapCacheEnvironmentMismatch();
}

class _AuthoritativeBootstrapCacheScopeMismatch implements Exception {
  const _AuthoritativeBootstrapCacheScopeMismatch();
}

class _AuthoritativeBootstrapCacheUnknownEnum implements Exception {
  const _AuthoritativeBootstrapCacheUnknownEnum();
}

class _AuthoritativeBootstrapCacheContractInvalid implements Exception {
  const _AuthoritativeBootstrapCacheContractInvalid();
}
