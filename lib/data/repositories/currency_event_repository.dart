import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/rutio_supabase_client.dart';
import '../models/remote/remote_currency_event.dart';
import 'repository_result.dart';

class CurrencyEventRepository {
  CurrencyEventRepository({SupabaseClient? client})
    : _client = client ?? RutioSupabaseClient.instance;

  final SupabaseClient _client;

  static const String _currencyEventsTable = 'currency_events';

  Future<RepositoryResult<List<RemoteCurrencyEvent>>>
  fetchRecentCurrencyEvents({int limit = 30}) async {
    final userId = _currentUserId();
    if (userId == null) {
      return RepositoryResult<List<RemoteCurrencyEvent>>.failure(
        _notAuthenticated(),
      );
    }

    final safeLimit = limit.clamp(1, 200).toInt();

    try {
      final rows = await _client
          .from(_currencyEventsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(safeLimit);

      final events = rows
          .whereType<Map>()
          .map(
            (row) => RemoteCurrencyEvent.fromMap(
              Map<String, dynamic>.from(row.cast<String, dynamic>()),
            ),
          )
          .toList(growable: false);

      return RepositoryResult<List<RemoteCurrencyEvent>>.success(data: events);
    } on PostgrestException catch (error) {
      return RepositoryResult<List<RemoteCurrencyEvent>>.failure(
        _mapPostgrestError(
          error,
          fallbackMessage: 'Could not fetch currency events.',
        ),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[currency_event_repository] unexpected fetch error: $error',
        );
      }
      return RepositoryResult<List<RemoteCurrencyEvent>>.failure(
        RepositoryError(
          code: RepositoryErrorCode.unknown,
          message: 'Could not fetch currency events.',
          cause: error,
        ),
      );
    }
  }

  String? _currentUserId() {
    final userId = _client.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return null;
    return userId;
  }

  RepositoryError _notAuthenticated() {
    return const RepositoryError(
      code: RepositoryErrorCode.notAuthenticated,
      message: 'No authenticated user session is available.',
    );
  }

  RepositoryError _mapPostgrestError(
    PostgrestException error, {
    required String fallbackMessage,
  }) {
    if (kDebugMode) {
      debugPrint(
        '[currency_event_repository] postgrest error (${error.code}): ${error.message}',
      );
    }

    final code = (error.code ?? '').trim();
    if (code == 'PGRST116') {
      return RepositoryError(
        code: RepositoryErrorCode.notFound,
        message: 'Currency event row was not found.',
        cause: error,
      );
    }
    if (code == '42501') {
      return RepositoryError(
        code: RepositoryErrorCode.permissionDenied,
        message: 'Permission denied for currency event operation.',
        cause: error,
      );
    }
    if (code == '42703' || code == 'PGRST204') {
      return RepositoryError(
        code: RepositoryErrorCode.invalidResponse,
        message:
            'Currency events schema is missing one or more expected columns.',
        cause: error,
      );
    }

    final rawMessage = error.message.toLowerCase();
    if (rawMessage.contains('network') ||
        rawMessage.contains('socket') ||
        rawMessage.contains('timeout') ||
        rawMessage.contains('connection')) {
      return RepositoryError(
        code: RepositoryErrorCode.network,
        message: 'Network error while accessing currency events.',
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
