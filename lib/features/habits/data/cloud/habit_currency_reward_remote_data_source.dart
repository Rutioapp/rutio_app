import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/supabase/rutio_supabase_client.dart';

abstract class HabitCurrencyRewardRemoteDataSource {
  Future<Object?> applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  });

  Future<Object?> reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  });
}

class SupabaseHabitCurrencyRewardRemoteDataSource
    implements HabitCurrencyRewardRemoteDataSource {
  SupabaseHabitCurrencyRewardRemoteDataSource({
    SupabaseClient? client,
    Future<String> Function()? clientVersionProvider,
  })  : _client = client,
        _clientVersionProvider = clientVersionProvider ?? _platformVersion;

  final SupabaseClient? _client;
  final Future<String> Function() _clientVersionProvider;

  SupabaseClient get _clientOrInstance =>
      _client ?? RutioSupabaseClient.instance;

  @override
  Future<Object?> applyHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  }) async {
    final clientVersion = await _clientVersionProvider();
    return _clientOrInstance.rpc(
      'complete_habit_economy_v1',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_habit_id': habitId,
        'p_logical_date': logicalDateKey,
        'p_is_completed': true,
        'p_value': value,
        'p_note': null,
        'p_client_version': clientVersion,
      },
    );
  }

  @override
  Future<Object?> reverseHabitCompletionReward({
    required String requestId,
    required String habitId,
    required String logicalDateKey,
    required String completionEventId,
    int value = 0,
  }) async {
    final clientVersion = await _clientVersionProvider();
    return _clientOrInstance.rpc(
      'complete_habit_economy_v1',
      params: <String, dynamic>{
        'p_request_id': requestId,
        'p_habit_id': habitId,
        'p_logical_date': logicalDateKey,
        'p_is_completed': false,
        'p_value': value,
        'p_note': null,
        'p_client_version': clientVersion,
      },
    );
  }

  static Future<String> _platformVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version.trim();
    if (!RegExp(r'^\d+(\.\d+){0,3}$').hasMatch(version)) {
      throw StateError(
          'Rutio app version is not a valid economy client version.');
    }
    return version;
  }
}
