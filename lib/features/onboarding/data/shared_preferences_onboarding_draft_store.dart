import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/onboarding_draft.dart';
import '../domain/onboarding_draft_store.dart';
import '../domain/onboarding_retention.dart';
import 'onboarding_draft_codec.dart';

/// SharedPreferences-backed local store. The payload is kept under one
/// namespaced key per scope; SharedPreferences is the app's existing local
/// persistence mechanism and is sufficient for this small JSON document.
class SharedPreferencesOnboardingDraftStore implements OnboardingDraftStore {
  SharedPreferencesOnboardingDraftStore({
    OnboardingDraftCodec? codec,
    OnboardingDraftRetentionPolicy? retentionPolicy,
    DateTime Function()? now,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? environmentNamespace,
  })  : _codec = codec ?? OnboardingDraftCodec(),
        _retentionPolicy =
            retentionPolicy ?? const OnboardingDraftRetentionPolicy(),
        _now = now ?? DateTime.now,
        _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _environmentNamespace = _normalizeNamespace(environmentNamespace);

  static const String _storagePrefix = 'rutio_onboarding_draft_v1_';

  final OnboardingDraftCodec _codec;
  final OnboardingDraftRetentionPolicy _retentionPolicy;
  final DateTime Function() _now;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String _environmentNamespace;

  @override
  Future<OnboardingDraft?> loadAnonymousDraft() async =>
      (await loadAnonymousDraftResult()).draft;

  @override
  Future<OnboardingDraftLoadResult> loadAnonymousDraftResult() async {
    return _load(
      _keyForAnonymous(),
      expectedUserId: null,
    );
  }

  @override
  Future<void> saveAnonymousDraft(OnboardingDraft draft) async {
    if (draft.boundUserId != null) {
      throw const OnboardingDraftBindingException(
        'A user-bound draft cannot be saved in anonymous scope.',
      );
    }
    await _write(_keyForAnonymous(), draft);
  }

  @override
  Future<void> deleteAnonymousDraft() async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_keyForAnonymous());
  }

  @override
  Future<bool> hasAnonymousDraft() async {
    final result = await loadAnonymousDraftResult();
    final draft = result.draft;
    return draft != null && _retentionPolicy.isReanudable(draft, now: _now());
  }

  @override
  Future<OnboardingDraft?> loadForUser(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return null;
    final result = await _load(
      _keyForUser(normalizedUserId),
      expectedUserId: normalizedUserId,
    );
    return result.draft;
  }

  @override
  Future<void> saveForUser(String userId, OnboardingDraft draft) async {
    final normalizedUserId = _requireUserId(userId);
    if (draft.boundUserId != normalizedUserId) {
      throw const OnboardingDraftBindingException(
        'A user-bound draft must match the target user scope.',
      );
    }
    await _write(_keyForUser(normalizedUserId), draft);
  }

  @override
  Future<void> deleteForUser(String userId) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return;
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_keyForUser(normalizedUserId));
  }

  String storageKeyForAnonymous() => _keyForAnonymous();

  String storageKeyForUser(String userId) =>
      _keyForUser(_requireUserId(userId));

  Future<OnboardingDraftLoadResult> _load(
    String key, {
    required String? expectedUserId,
  }) async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        return const OnboardingDraftLoadResult.missing();
      }
      final decoded = _codec.decodeString(raw);
      final draft = decoded.draft;
      if (draft == null) {
        return OnboardingDraftLoadResult(
          status: _mapStatus(decoded.status),
          message: decoded.message,
        );
      }

      if (expectedUserId == null && draft.boundUserId != null) {
        return const OnboardingDraftLoadResult(
          status: OnboardingDraftLoadStatus.recoverableError,
          message: 'Anonymous draft unexpectedly contains a bound user.',
        );
      }
      if (expectedUserId != null && draft.boundUserId != expectedUserId) {
        return const OnboardingDraftLoadResult(
          status: OnboardingDraftLoadStatus.recoverableError,
          message: 'Draft belongs to another user.',
        );
      }

      if (decoded.status == OnboardingDraftDecodeStatus.migrated) {
        // Migration is persisted only after the result has decoded into a
        // valid draft. If this write fails, the old valid raw payload remains.
        try {
          await prefs.setString(key, jsonEncode(_codec.encode(draft)));
        } catch (_) {
          // Loading a valid migrated draft remains possible on this run.
        }
      }

      return OnboardingDraftLoadResult(
        status: _mapStatus(decoded.status),
        draft: draft,
        message: decoded.message,
      );
    } catch (_) {
      return const OnboardingDraftLoadResult(
        status: OnboardingDraftLoadStatus.corrupt,
        message: 'Draft storage could not be read.',
      );
    }
  }

  Future<void> _write(String key, OnboardingDraft draft) async {
    // Encode and validate before touching storage. A failed validation never
    // replaces the last known-good payload.
    final encoded = jsonEncode(_codec.encode(draft));
    final prefs = await _sharedPreferencesProvider();
    final written = await prefs.setString(key, encoded);
    if (!written) throw StateError('Could not persist onboarding draft.');
  }

  String _keyForAnonymous() => '${_storagePrefixForEnvironment()}anonymous';

  String _keyForUser(String userId) =>
      '${_storagePrefixForEnvironment()}user_${_safeFragment(userId)}';

  String _storagePrefixForEnvironment() =>
      '$_storagePrefix${_safeFragment(_environmentNamespace)}_';

  static OnboardingDraftLoadStatus _mapStatus(
    OnboardingDraftDecodeStatus status,
  ) {
    switch (status) {
      case OnboardingDraftDecodeStatus.valid:
        return OnboardingDraftLoadStatus.valid;
      case OnboardingDraftDecodeStatus.migrated:
        return OnboardingDraftLoadStatus.migrated;
      case OnboardingDraftDecodeStatus.recoverableError:
        return OnboardingDraftLoadStatus.recoverableError;
      case OnboardingDraftDecodeStatus.corrupt:
        return OnboardingDraftLoadStatus.corrupt;
      case OnboardingDraftDecodeStatus.unsupportedFutureSchema:
        return OnboardingDraftLoadStatus.unsupportedFutureSchema;
    }
  }

  static String _requireUserId(String value) {
    final normalized = _normalizeUserId(value);
    if (normalized == null) {
      throw ArgumentError.value(value, 'userId', 'User id must not be empty.');
    }
    return normalized;
  }

  static String? _normalizeUserId(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String _normalizeNamespace(String? value) {
    return _normalizeUserId(value) ?? 'default';
  }

  static String _safeFragment(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
}
