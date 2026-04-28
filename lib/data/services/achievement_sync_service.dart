import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../../features/achievements/application/achievement_rewards.dart';
import '../../features/achievements/domain/models/achievement.dart';
import '../../features/achievements/domain/models/unlocked_achievement_record.dart';
import '../repositories/repository_result.dart';
import '../repositories/user_achievement_repository.dart';

@immutable
class AchievementBackfillSummary {
  const AchievementBackfillSummary({
    required this.totalCandidates,
    required this.uploadedCount,
    required this.skippedCount,
    required this.failedCount,
  });

  final int totalCandidates;
  final int uploadedCount;
  final int skippedCount;
  final int failedCount;
}

/// Best-effort remote mirroring for local achievement unlock state.
///
/// This service must never throw into UI/store mutation flows.
class AchievementSyncService {
  AchievementSyncService({UserAchievementRepository? repository})
      : _repository = repository;

  UserAchievementRepository? _repository;
  DateTime? _schemaUnavailableUntil;

  Future<void> syncAchievementUnlocked({
    required UnlockedAchievementRecord record,
    required bool rewardApplied,
    String? expectedLocalUserId,
  }) async {
    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('achievement sync skipped: no authenticated session');
        return;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'achievement sync skipped: local user does not match active auth user',
        );
        return;
      }

      if (_isSchemaUnavailable()) {
        _debugWarn('achievement sync skipped: schema marked unavailable');
        return;
      }

      final remoteTier = _remoteTierValue(record.tier);
      if (remoteTier == null) {
        _debugWarn(
          'achievement sync skipped: unsupported tier '
          'for achievementId="${record.id}" tier="${record.tier.name}"',
        );
        return;
      }

      _debugWarn(
        'achievement unlock sync triggered: '
        'achievementId="${record.id}", tier="$remoteTier", '
        'familyId="${_nullableTrim(record.familyId) ?? 'null'}", '
        'rewardApplied=$rewardApplied',
      );

      final rewardValues = AchievementRewards.getAchievementReward(record.tier);
      final result = await _repo.upsertUnlockedAchievement(
        achievementId: record.id,
        familyId: _nullableTrim(record.familyId),
        tier: remoteTier,
        unlockedAt: record.unlockedAt,
        rewardXp: rewardValues.rewardXp,
        rewardAmbar: rewardValues.rewardAmber,
        rewardApplied: rewardApplied,
      );

      if (!result.isSuccess) {
        _onRepositoryFailure(result.error);
      }
    } catch (error) {
      _debugWarn('achievement sync unexpected error: $error');
    }
  }

  Future<AchievementBackfillSummary> syncExistingLocalAchievementsOnce({
    required List<UnlockedAchievementRecord> localUnlockedAchievements,
    required Set<String> rewardAppliedAchievementIds,
    String? expectedLocalUserId,
    bool force = false,
  }) async {
    var uploadedCount = 0;
    var skippedCount = 0;
    var failedCount = 0;

    final uniqueRecords = <String, UnlockedAchievementRecord>{};
    for (final record in localUnlockedAchievements) {
      if (record.id.trim().isEmpty) continue;
      uniqueRecords[record.id] = record;
    }

    final records = uniqueRecords.values.toList(growable: false);
    final totalCandidates = records.length;

    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('achievement backfill skipped: no authenticated session');
        return const AchievementBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'achievement backfill skipped: local user does not match active auth user',
        );
        return const AchievementBackfillSummary(
          totalCandidates: 0,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: 0,
        );
      }

      if (force) {
        _schemaUnavailableUntil = null;
      }

      if (_isSchemaUnavailable()) {
        _debugWarn('achievement backfill skipped: schema marked unavailable');
        return AchievementBackfillSummary(
          totalCandidates: totalCandidates,
          uploadedCount: 0,
          skippedCount: 0,
          failedCount: totalCandidates == 0 ? 0 : totalCandidates,
        );
      }

      _debugWarn(
        'achievement backfill started: '
        'localUnlockedCount=${localUnlockedAchievements.length}, '
        'uniqueCandidates=$totalCandidates, '
        'rewardAppliedCount=${rewardAppliedAchievementIds.length}, '
        'force=$force',
      );

      for (final record in records) {
        final remoteTier = _remoteTierValue(record.tier);
        if (remoteTier == null) {
          skippedCount += 1;
          _debugWarn(
            'achievement backfill skipped record: unsupported tier '
            'for achievementId="${record.id}" tier="${record.tier.name}"',
          );
          continue;
        }

        final rewardValues = AchievementRewards.getAchievementReward(record.tier);
        final result = await _repo.upsertUnlockedAchievement(
          achievementId: record.id,
          familyId: _nullableTrim(record.familyId),
          tier: remoteTier,
          unlockedAt: record.unlockedAt,
          rewardXp: rewardValues.rewardXp,
          rewardAmbar: rewardValues.rewardAmber,
          rewardApplied: rewardAppliedAchievementIds.contains(record.id),
        );

        if (!result.isSuccess) {
          failedCount += 1;
          _onRepositoryFailure(result.error);
          if (_isSchemaUnavailable()) {
            failedCount += (records.length - uploadedCount - failedCount);
            break;
          }
          continue;
        }

        uploadedCount += 1;
      }
    } catch (error) {
      _debugWarn('achievement backfill unexpected error: $error');
      failedCount += 1;
    }

    _debugWarn(
      'achievement backfill finished: totalCandidates=$totalCandidates, '
      'uploaded=$uploadedCount, skipped=$skippedCount, failed=$failedCount',
    );

    return AchievementBackfillSummary(
      totalCandidates: totalCandidates,
      uploadedCount: uploadedCount,
      skippedCount: skippedCount,
      failedCount: failedCount,
    );
  }

  UserAchievementRepository get _repo {
    return _repository ??= UserAchievementRepository();
  }

  Future<int?> fetchCurrentUserAchievementCount({
    String? expectedLocalUserId,
  }) async {
    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) return null;
      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        return null;
      }

      final result = await _repo.fetchCurrentUserAchievements();
      if (!result.isSuccess || result.data == null) {
        _debugWarn(
          'achievement remote-count fetch failed: '
          '${result.error?.code.name}: ${result.error?.message}',
        );
        return null;
      }

      return result.data!.length;
    } catch (error) {
      _debugWarn('achievement remote-count fetch unexpected error: $error');
      return null;
    }
  }

  String? _currentAuthenticatedUserId() {
    if (!RutioSupabaseClient.isInitialized) return null;

    try {
      final userId = RutioSupabaseClient.instance.auth.currentUser?.id.trim();
      if (userId == null || userId.isEmpty) return null;
      return userId;
    } catch (_) {
      return null;
    }
  }

  bool _isExpectedUser(String authenticatedUserId, String? expectedLocalUserId) {
    final expected = (expectedLocalUserId ?? '').trim();
    if (expected.isEmpty) return true;
    return expected == authenticatedUserId;
  }

  String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool _isSchemaUnavailable() {
    final until = _schemaUnavailableUntil;
    if (until == null) return false;
    return DateTime.now().isBefore(until);
  }

  void _onRepositoryFailure(RepositoryError? error) {
    final message = error == null
        ? 'unknown repository error'
        : '${error.code.name}: ${error.message}';
    _debugWarn('achievement sync failed: $message');
    if (!_isSchemaMissingError(error)) {
      _debugWarn('schema-unavailable not set: failure is not a schema-missing class');
      return;
    }

    _schemaUnavailableUntil = DateTime.now().add(const Duration(minutes: 2));
    _debugWarn(
      'schema-unavailable set until $_schemaUnavailableUntil due to schema/cache-missing error',
    );
  }

  bool _isSchemaMissingError(RepositoryError? error) {
    if (error == null) return false;
    if (error.code != RepositoryErrorCode.invalidResponse) return false;

    final cause = error.cause;
    if (cause is PostgrestException) {
      final code = (cause.code ?? '').trim();
      if (code == 'PGRST205' || code == '42P01') {
        return true; // table/relation not found
      }
      if (code == 'PGRST204' || code == '42703') {
        return true; // missing expected column / stale schema cache
      }
      return false;
    }

    final message = error.message.toLowerCase();
    return message.contains('table is not available') ||
        message.contains('schema cache') ||
        message.contains('missing expected structure');
  }

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[achievement_sync] $message');
  }

  String? _remoteTierValue(AchievementTier tier) {
    switch (tier) {
      case AchievementTier.oldWood:
        return null;
      case AchievementTier.wood:
        return 'wood';
      case AchievementTier.stone:
        return 'stone';
      case AchievementTier.bronze:
        return 'bronze';
      case AchievementTier.silver:
        return 'silver';
      case AchievementTier.gold:
        return 'gold';
      case AchievementTier.diamond:
        return 'diamond';
      case AchievementTier.prismaticDiamond:
        return 'prismaticDiamond';
    }
  }
}
