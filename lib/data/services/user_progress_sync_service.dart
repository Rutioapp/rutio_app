import 'package:flutter/foundation.dart';


/// Result of a legacy event mirror request.
///
/// Event tables are intentionally read-only for clients. A skipped result is
/// explicit so callers cannot mistake a local-only fallback for a persisted
/// server-side economic movement.
enum LegacyEventSyncOutcome { skippedLegacyEventWrite }

/// Best-effort remote mirroring for local progression and reward events.
///
/// This service must never throw into UI/store mutation flows.
class UserProgressSyncService {
  UserProgressSyncService();

  Future<bool> syncCurrentProgressFromLocalState({
    required int level,
    required int totalXp,
    required int currentLevelXp,
    required int nextLevelXp,
    required int ambarBalance,
    int ambarEarnedDelta = 0,
    int ambarSpentDelta = 0,
    String? expectedLocalUserId,
  }) async {
    _debugWarn(
      'progress write skipped: user_progress is refreshed by authoritative RPCs',
    );
    return false;
  }

  Future<LegacyEventSyncOutcome> recordXpEvent({
    required int amount,
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    if (amount <= 0) return LegacyEventSyncOutcome.skippedLegacyEventWrite;
    _debugWarn(
      'xp event remote write skipped: xp_events is read-only for clients',
    );
    return LegacyEventSyncOutcome.skippedLegacyEventWrite;
  }

  Future<LegacyEventSyncOutcome> recordCurrencyEvent({
    required int amount,
    String currency = 'ambar',
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    if (amount == 0) {
      return LegacyEventSyncOutcome.skippedLegacyEventWrite;
    }
    _debugWarn(
      'currency event remote write skipped: currency_events is read-only for clients',
    );
    return LegacyEventSyncOutcome.skippedLegacyEventWrite;
  }

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[user_progress_sync] $message');
  }
}
