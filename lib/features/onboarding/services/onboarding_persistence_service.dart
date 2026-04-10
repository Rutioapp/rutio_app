import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/onboarding_step.dart';

class OnboardingPersistenceService {
  static const String _storageKeyPrefix = 'rutio_onboarding_step_progress_v2';
  static const String _legacySeenStepsKeyPrefix =
      'rutio_onboarding_seen_steps_v1';
  static final Set<String> _sessionDismissedKeys = <String>{};

  Future<Map<String, OnboardingStepProgress>> readStepProgressMap({
    String? scopeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressMap = _readPersistedProgressMap(
      prefs,
      scopeId: scopeId,
    );
    final legacyMap = _readLegacyCompletedProgressMap(
      prefs,
      scopeId: scopeId,
    );

    if (legacyMap.isEmpty) {
      return progressMap;
    }

    final merged = <String, OnboardingStepProgress>{
      ...progressMap,
    };

    legacyMap.forEach((stepId, legacyProgress) {
      final existingProgress = merged[stepId];
      if (existingProgress?.isCompleted == true) {
        return;
      }

      merged[stepId] = legacyProgress;
    });

    return merged;
  }

  Future<OnboardingStepProgress> markStepDismissed(
    String stepId, {
    String? scopeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressMap = await readStepProgressMap(scopeId: scopeId);
    final updatedProgress =
        (progressMap[stepId] ?? const OnboardingStepProgress())
            .markDismissed(DateTime.now().toUtc());

    progressMap[stepId] = updatedProgress;
    _sessionDismissedKeys.add(_sessionKey(stepId, scopeId));
    await _writeProgressMap(
      prefs,
      progressMap,
      scopeId: scopeId,
    );

    return updatedProgress;
  }

  Future<OnboardingStepProgress> markStepCompleted(
    String stepId, {
    String? scopeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progressMap = await readStepProgressMap(scopeId: scopeId);
    final updatedProgress =
        (progressMap[stepId] ?? const OnboardingStepProgress())
            .markCompleted(DateTime.now().toUtc());

    progressMap[stepId] = updatedProgress;
    _sessionDismissedKeys.remove(_sessionKey(stepId, scopeId));
    await _writeProgressMap(
      prefs,
      progressMap,
      scopeId: scopeId,
    );

    return updatedProgress;
  }

  bool isDismissedInSession(String stepId, {String? scopeId}) {
    return _sessionDismissedKeys.contains(_sessionKey(stepId, scopeId));
  }

  String _storageKey(String? scopeId) {
    final normalizedScope = _normalizeScope(scopeId);
    return '$_storageKeyPrefix::$normalizedScope';
  }

  String _normalizeScope(String? scopeId) {
    final trimmed = scopeId?.trim().toLowerCase() ?? '';
    if (trimmed.isEmpty) {
      return 'anonymous';
    }

    return trimmed.replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
  }

  String _legacyStorageKey(String? scopeId) {
    final normalizedScope = _normalizeScope(scopeId);
    return '$_legacySeenStepsKeyPrefix::$normalizedScope';
  }

  String _sessionKey(String stepId, String? scopeId) {
    return '${_normalizeScope(scopeId)}::$stepId';
  }

  Map<String, OnboardingStepProgress> _readPersistedProgressMap(
    SharedPreferences prefs, {
    String? scopeId,
  }) {
    final raw = prefs.getString(_storageKey(scopeId));
    if (raw == null || raw.trim().isEmpty) {
      return <String, OnboardingStepProgress>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, OnboardingStepProgress>{};
      }

      return decoded.map<String, OnboardingStepProgress>((key, value) {
        return MapEntry(
          key.toString(),
          OnboardingStepProgress.fromJson(value),
        );
      });
    } catch (_) {
      return <String, OnboardingStepProgress>{};
    }
  }

  Map<String, OnboardingStepProgress> _readLegacyCompletedProgressMap(
    SharedPreferences prefs, {
    String? scopeId,
  }) {
    final legacySeenSteps =
        prefs.getStringList(_legacyStorageKey(scopeId)) ?? const <String>[];

    return {
      for (final stepId in legacySeenSteps)
        stepId: const OnboardingStepProgress(
          status: OnboardingStepStatus.completed,
        ),
    };
  }

  Future<void> _writeProgressMap(
    SharedPreferences prefs,
    Map<String, OnboardingStepProgress> progressMap, {
    String? scopeId,
  }) async {
    final normalizedMap = <String, dynamic>{
      for (final entry in progressMap.entries) entry.key: entry.value.toJson(),
    };

    await prefs.setString(
      _storageKey(scopeId),
      jsonEncode(normalizedMap),
    );
  }
}
