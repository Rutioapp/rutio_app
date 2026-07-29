import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/remote/remote_profile.dart';

enum BootstrapProfileDecisionCacheSource {
  remoteDecision,
  remoteProfile,
  remoteProfileUpsert,
  onboardingCompletion;

  String toStorageValue() {
    switch (this) {
      case BootstrapProfileDecisionCacheSource.remoteDecision:
        return 'remote_decision';
      case BootstrapProfileDecisionCacheSource.remoteProfile:
        return 'remote_profile';
      case BootstrapProfileDecisionCacheSource.remoteProfileUpsert:
        return 'remote_profile_upsert';
      case BootstrapProfileDecisionCacheSource.onboardingCompletion:
        return 'onboarding_completion';
    }
  }

  static BootstrapProfileDecisionCacheSource? fromStorageValue(String value) {
    switch (value.trim()) {
      case 'remote_decision':
        return BootstrapProfileDecisionCacheSource.remoteDecision;
      case 'remote_profile':
        return BootstrapProfileDecisionCacheSource.remoteProfile;
      case 'remote_profile_upsert':
        return BootstrapProfileDecisionCacheSource.remoteProfileUpsert;
      case 'onboarding_completion':
        return BootstrapProfileDecisionCacheSource.onboardingCompletion;
    }
    return null;
  }
}

enum BootstrapProfileCacheValidation {
  valid,
  missing,
  corrupt,
  userMismatch,
  schemaMismatch,
  onboardingVersionMismatch,
  incompleteDecision,
  invalidStatus,
}

@immutable
class CachedBootstrapProfileDecision {
  const CachedBootstrapProfileDecision({
    required this.cacheSchemaVersion,
    required this.userId,
    required this.decision,
    required this.onboardingPolicyVersion,
    required this.remoteVerifiedAt,
    required this.source,
  });

  static const int currentSchemaVersion = 1;

  final int cacheSchemaVersion;
  final String userId;
  final BootstrapProfileDecision decision;
  final int onboardingPolicyVersion;
  final DateTime remoteVerifiedAt;
  final BootstrapProfileDecisionCacheSource source;

  factory CachedBootstrapProfileDecision.fromJson(
    Map<String, dynamic> json, {
    required String expectedUserId,
  }) {
    final schemaVersion = _readPositiveInt(json['cacheSchemaVersion']);
    if (schemaVersion == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cache schema version.',
      );
    }
    if (schemaVersion != currentSchemaVersion) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.schemaMismatch,
        'Cache schema version is not compatible.',
      );
    }

    final topLevelUserId = _readTrimmedString(json['userId']);
    if (topLevelUserId == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cached user id.',
      );
    }
    if (topLevelUserId != expectedUserId) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.userMismatch,
        'Cached user id does not match requested user.',
      );
    }

    final decisionJson = json['decision'];
    if (decisionJson is! Map) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cached decision payload.',
      );
    }

    final decisionUserId = _readTrimmedString(
      decisionJson['userId'] ?? decisionJson['id'],
    );
    if (decisionUserId == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cached decision user id.',
      );
    }
    if (decisionUserId != topLevelUserId) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.userMismatch,
        'Cached decision belongs to another user.',
      );
    }

    final onboardingStatusRaw =
        _readTrimmedString(decisionJson['onboardingStatus']);
    if (onboardingStatusRaw == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cached onboarding status.',
      );
    }

    final onboardingStatus = _parseOnboardingStatus(onboardingStatusRaw);
    if (onboardingStatus == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.invalidStatus,
        'Cached onboarding status is unknown.',
      );
    }

    final onboardingVersion =
        _readPositiveInt(decisionJson['onboardingVersion']);
    if (onboardingVersion == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing cached onboarding version.',
      );
    }

    final onboardingCompletedAt = _readNullableDateTimeUtc(
      decisionJson['onboardingCompletedAt'],
    );
    try {
      RemoteProfile(
        id: decisionUserId,
        onboardingStatus: onboardingStatus,
        onboardingVersion: onboardingVersion,
        onboardingCompletedAt: onboardingCompletedAt,
      ).toBootstrapProfileDecision(expectedUserId: decisionUserId);
    } on RemoteProfileParseException {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Cached decision is not coherent.',
      );
    }

    final onboardingPolicyVersion =
        _readPositiveInt(json['onboardingPolicyVersion']);
    if (onboardingPolicyVersion == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing onboarding policy version.',
      );
    }

    final remoteVerifiedAt = _readNullableDateTimeUtc(json['remoteVerifiedAt']);
    if (remoteVerifiedAt == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.incompleteDecision,
        'Missing remote verification timestamp.',
      );
    }

    final sourceRaw = _readTrimmedString(json['source']);
    final source = sourceRaw == null
        ? null
        : BootstrapProfileDecisionCacheSource.fromStorageValue(sourceRaw);
    if (source == null) {
      throw const _CachedBootstrapProfileDecisionParseException(
        BootstrapProfileCacheValidation.corrupt,
        'Cached source is not compatible.',
      );
    }

    return CachedBootstrapProfileDecision(
      cacheSchemaVersion: schemaVersion,
      userId: topLevelUserId,
      decision: BootstrapProfileDecision(
        userId: decisionUserId,
        onboardingStatus: onboardingStatus,
        onboardingVersion: onboardingVersion,
        onboardingCompletedAt: onboardingCompletedAt,
      ),
      onboardingPolicyVersion: onboardingPolicyVersion,
      remoteVerifiedAt: remoteVerifiedAt,
      source: source,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cacheSchemaVersion': cacheSchemaVersion,
      'userId': userId,
      'decision': <String, dynamic>{
        'userId': decision.userId,
        'onboardingStatus': decision.onboardingStatus.toSupabase(),
        'onboardingVersion': decision.onboardingVersion,
        'onboardingCompletedAt':
            decision.onboardingCompletedAt?.toUtc().toIso8601String(),
      },
      'onboardingPolicyVersion': onboardingPolicyVersion,
      'remoteVerifiedAt': remoteVerifiedAt.toUtc().toIso8601String(),
      'source': source.toStorageValue(),
    };
  }

  CachedBootstrapProfileDecision copyWith({
    int? cacheSchemaVersion,
    String? userId,
    BootstrapProfileDecision? decision,
    int? onboardingPolicyVersion,
    DateTime? remoteVerifiedAt,
    BootstrapProfileDecisionCacheSource? source,
  }) {
    return CachedBootstrapProfileDecision(
      cacheSchemaVersion: cacheSchemaVersion ?? this.cacheSchemaVersion,
      userId: userId ?? this.userId,
      decision: decision ?? this.decision,
      onboardingPolicyVersion:
          onboardingPolicyVersion ?? this.onboardingPolicyVersion,
      remoteVerifiedAt: remoteVerifiedAt ?? this.remoteVerifiedAt,
      source: source ?? this.source,
    );
  }
}

@immutable
class BootstrapProfileDecisionCacheReadResult {
  const BootstrapProfileDecisionCacheReadResult({
    required this.validation,
    this.entry,
  });

  const BootstrapProfileDecisionCacheReadResult.valid(
    CachedBootstrapProfileDecision this.entry,
  ) : validation = BootstrapProfileCacheValidation.valid;

  const BootstrapProfileDecisionCacheReadResult.missing()
      : validation = BootstrapProfileCacheValidation.missing,
        entry = null;

  final BootstrapProfileCacheValidation validation;
  final CachedBootstrapProfileDecision? entry;
}

abstract interface class BootstrapProfileDecisionCache {
  Future<BootstrapProfileDecisionCacheReadResult> read(String userId);

  Future<void> write(CachedBootstrapProfileDecision entry);

  Future<void> delete(String userId);

  Future<void> clear();
}

class SharedPreferencesBootstrapProfileDecisionCache
    implements BootstrapProfileDecisionCache {
  SharedPreferencesBootstrapProfileDecisionCache({
    String? environmentNamespace,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  })  : _environmentNamespace =
            _normalizeEnvironmentNamespace(environmentNamespace),
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String _storagePrefix = 'rutio_bootstrap_profile_decision_v1_';

  final String _environmentNamespace;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<BootstrapProfileDecisionCacheReadResult> read(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      return const BootstrapProfileDecisionCacheReadResult.missing();
    }

    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(storageKeyForUser(normalizedUserId));
      if (raw == null || raw.trim().isEmpty) {
        return const BootstrapProfileDecisionCacheReadResult.missing();
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return const BootstrapProfileDecisionCacheReadResult(
          validation: BootstrapProfileCacheValidation.corrupt,
        );
      }

      final entry = CachedBootstrapProfileDecision.fromJson(
        Map<String, dynamic>.from(decoded.cast<String, dynamic>()),
        expectedUserId: normalizedUserId,
      );
      return BootstrapProfileDecisionCacheReadResult.valid(entry);
    } on _CachedBootstrapProfileDecisionParseException catch (error) {
      return BootstrapProfileDecisionCacheReadResult(
        validation: error.validation,
      );
    } catch (_) {
      return const BootstrapProfileDecisionCacheReadResult(
        validation: BootstrapProfileCacheValidation.corrupt,
      );
    }
  }

  @override
  Future<void> write(CachedBootstrapProfileDecision entry) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(
      storageKeyForUser(entry.userId),
      jsonEncode(entry.toJson()),
    );
  }

  @override
  Future<void> delete(String userId) async {
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

  String storageKeyForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }
    return '${_storagePrefixForEnvironment()}${_safeKeyFragment(normalizedUserId)}';
  }

  String _storagePrefixForEnvironment() {
    return '$_storagePrefix${_safeKeyFragment(_environmentNamespace)}_';
  }
}

class InMemoryBootstrapProfileDecisionCache
    implements BootstrapProfileDecisionCache {
  final Map<String, CachedBootstrapProfileDecision> _entries =
      <String, CachedBootstrapProfileDecision>{};
  final Set<String> _corruptUsers = <String>{};
  final Set<String> _readFailures = <String>{};
  final Set<String> _writeFailures = <String>{};
  final Set<String> _deleteFailures = <String>{};

  void seedCorrupt(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    _corruptUsers.add(normalizedUserId);
    _entries.remove(normalizedUserId);
  }

  void failReadsForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    _readFailures.add(normalizedUserId);
  }

  void failWritesForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    _writeFailures.add(normalizedUserId);
  }

  void failDeletesForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    _deleteFailures.add(normalizedUserId);
  }

  CachedBootstrapProfileDecision? peek(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return null;
    return _entries[normalizedUserId];
  }

  @override
  Future<BootstrapProfileDecisionCacheReadResult> read(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      return const BootstrapProfileDecisionCacheReadResult.missing();
    }
    if (_readFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache read failure for $normalizedUserId');
    }
    if (_corruptUsers.contains(normalizedUserId)) {
      return const BootstrapProfileDecisionCacheReadResult(
        validation: BootstrapProfileCacheValidation.corrupt,
      );
    }
    final entry = _entries[normalizedUserId];
    if (entry == null) {
      return const BootstrapProfileDecisionCacheReadResult.missing();
    }
    return BootstrapProfileDecisionCacheReadResult.valid(entry);
  }

  @override
  Future<void> write(CachedBootstrapProfileDecision entry) async {
    final normalizedUserId = _normalizeUserId(entry.userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(entry.userId, 'entry.userId');
    }
    if (_writeFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache write failure for $normalizedUserId');
    }
    _entries[normalizedUserId] = entry;
    _corruptUsers.remove(normalizedUserId);
  }

  @override
  Future<void> delete(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    if (_deleteFailures.contains(normalizedUserId)) {
      throw StateError('Injected cache delete failure for $normalizedUserId');
    }
    _entries.remove(normalizedUserId);
    _corruptUsers.remove(normalizedUserId);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
    _corruptUsers.clear();
  }
}

String? _normalizeUserId(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? null : normalized;
}

String _normalizeEnvironmentNamespace(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty ? 'default' : normalized;
}

String _safeKeyFragment(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\\-]'), '_');
}

String? _readTrimmedString(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _readPositiveInt(Object? value) {
  if (value is int) return value > 0 ? value : null;
  if (value is num) {
    final normalized = value.toInt();
    return normalized > 0 ? normalized : null;
  }
  final parsed = int.tryParse((value ?? '').toString().trim());
  if (parsed == null || parsed <= 0) return null;
  return parsed;
}

DateTime? _readNullableDateTimeUtc(Object? value) {
  final raw = _readTrimmedString(value);
  if (raw == null) return null;
  final parsed = DateTime.tryParse(raw);
  return parsed?.toUtc();
}

OnboardingStatus? _parseOnboardingStatus(String raw) {
  try {
    return OnboardingStatus.fromSupabase(raw);
  } on RemoteProfileParseException {
    return null;
  }
}

class _CachedBootstrapProfileDecisionParseException implements FormatException {
  const _CachedBootstrapProfileDecisionParseException(
    this.validation,
    this.message,
  );

  final BootstrapProfileCacheValidation validation;

  @override
  final String message;

  @override
  dynamic get source => null;

  @override
  int? get offset => null;
}
