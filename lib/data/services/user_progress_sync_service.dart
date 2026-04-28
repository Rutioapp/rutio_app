import 'package:flutter/foundation.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_currency_event.dart';
import '../models/remote/remote_xp_event.dart';
import '../repositories/currency_event_repository.dart';
import '../repositories/user_progress_repository.dart';
import '../repositories/xp_event_repository.dart';

/// Best-effort remote mirroring for local progression and reward events.
///
/// This service must never throw into UI/store mutation flows.
class UserProgressSyncService {
  UserProgressSyncService({
    UserProgressRepository? userProgressRepository,
    XpEventRepository? xpEventRepository,
    CurrencyEventRepository? currencyEventRepository,
  })  : _userProgressRepository = userProgressRepository,
        _xpEventRepository = xpEventRepository,
        _currencyEventRepository = currencyEventRepository;

  UserProgressRepository? _userProgressRepository;
  XpEventRepository? _xpEventRepository;
  CurrencyEventRepository? _currencyEventRepository;

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
    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('progress sync skipped: no authenticated session');
        return false;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'progress sync skipped: local user does not match active auth user',
        );
        return false;
      }

      final result = await _userProgressRepo.touchProgressFromLocalState(
        level: level,
        totalXp: totalXp,
        currentLevelXp: currentLevelXp,
        nextLevelXp: nextLevelXp,
        ambarBalance: ambarBalance,
        ambarEarnedDelta: ambarEarnedDelta,
        ambarSpentDelta: ambarSpentDelta,
      );

      if (!result.isSuccess) {
        _debugWarn(
          'progress sync failed: ${result.error?.code.name}: ${result.error?.message}',
        );
      } else if (kDebugMode) {
        debugPrint('[user_progress_sync] progress upsert success');
      }
      return result.isSuccess;
    } catch (error) {
      _debugWarn('progress sync unexpected error: $error');
      return false;
    }
  }

  Future<bool> recordXpEvent({
    required int amount,
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    if (amount <= 0) return true;

    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('xp event sync skipped: no authenticated session');
        return false;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'xp event sync skipped: local user does not match active auth user',
        );
        return false;
      }

      final mappedSource = _mapXpSource(source);
      final result = await _xpEventRepo.insertXpEvent(
        RemoteXpEvent(
          userId: authenticatedUserId,
          amount: amount,
          source: mappedSource,
          sourceId: _uuidOrNull(sourceId),
          description: _nullableTrim(description),
        ),
      );

      if (!result.isSuccess) {
        _debugWarn(
          'xp event sync failed: ${result.error?.code.name}: ${result.error?.message}',
        );
      } else if (kDebugMode) {
        debugPrint('[user_progress_sync] xp event insert success');
      }
      return result.isSuccess;
    } catch (error) {
      _debugWarn('xp event sync unexpected error: $error');
      return false;
    }
  }

  Future<bool> recordCurrencyEvent({
    required int amount,
    String currency = 'ambar',
    String? source,
    String? sourceId,
    String? description,
    String? expectedLocalUserId,
  }) async {
    if (amount == 0) return true;

    try {
      final authenticatedUserId = _currentAuthenticatedUserId();
      if (authenticatedUserId == null) {
        _debugWarn('currency event sync skipped: no authenticated session');
        return false;
      }

      if (!_isExpectedUser(authenticatedUserId, expectedLocalUserId)) {
        _debugWarn(
          'currency event sync skipped: local user does not match active auth user',
        );
        return false;
      }

      final mappedSource = _mapCurrencySource(source);
      final result = await _currencyEventRepo.insertCurrencyEvent(
        RemoteCurrencyEvent(
          userId: authenticatedUserId,
          amount: amount,
          currency: currency,
          source: mappedSource,
          sourceId: _uuidOrNull(sourceId),
          description: _nullableTrim(description),
        ),
      );

      if (!result.isSuccess) {
        _debugWarn(
          'currency event sync failed: '
          '${result.error?.code.name}: ${result.error?.message}',
        );
      } else if (kDebugMode) {
        debugPrint('[user_progress_sync] currency event insert success');
      }
      return result.isSuccess;
    } catch (error) {
      _debugWarn('currency event sync unexpected error: $error');
      return false;
    }
  }

  String _mapXpSource(String? source) {
    final normalized = (source ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'habit_completion':
      case 'habit_completed':
        return 'habit_completed';
      case 'habit_count_progress':
        return 'habit_count_progress';
      case 'journal_entry':
        return 'journal_entry';
      case 'achievement':
      case 'achievement_unlocked':
        return 'achievement_unlocked';
      case 'level_bonus':
        return 'level_bonus';
      case 'migration':
        return 'migration';
      case 'system':
        return 'system';
      default:
        return 'system';
    }
  }

  String _mapCurrencySource(String? source) {
    final normalized = (source ?? '').trim().toLowerCase();
    switch (normalized) {
      case 'habit_completion':
      case 'habit_completed':
      case 'habit_count_progress':
        return 'habit_completed';
      case 'journal_entry':
        return 'journal_entry';
      case 'achievement':
      case 'achievement_unlocked':
        return 'achievement_unlocked';
      case 'shop_purchase':
        return 'shop_purchase';
      case 'refund':
        return 'refund';
      case 'migration':
        return 'migration';
      case 'system':
        return 'system';
      default:
        return 'system';
    }
  }

  UserProgressRepository get _userProgressRepo {
    return _userProgressRepository ??= UserProgressRepository();
  }

  XpEventRepository get _xpEventRepo {
    return _xpEventRepository ??= XpEventRepository();
  }

  CurrencyEventRepository get _currencyEventRepo {
    return _currencyEventRepository ??= CurrencyEventRepository();
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

  String? _uuidOrNull(String? value) {
    final normalized = _nullableTrim(value);
    if (normalized == null) return null;
    final uuidRegExp = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegExp.hasMatch(normalized) ? normalized : null;
  }

  void _debugWarn(String message) {
    if (!kDebugMode) return;
    debugPrint('[user_progress_sync] $message');
  }
}
