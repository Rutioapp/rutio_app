import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/features/habits/data/cloud/habit_currency_reward_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('sends the numeric app version to the economy RPC', () async {
    final capture = _CaptureClient();
    final client = SupabaseClient(
      'https://staging.example.supabase.co',
      'test-anon-key',
      httpClient: capture,
    );
    final dataSource = SupabaseHabitCurrencyRewardRemoteDataSource(
      client: client,
      clientVersionProvider: () async => '1.0.4',
    );

    await dataSource.applyHabitCompletionReward(
      requestId: 'request-1',
      habitId: 'habit-1',
      logicalDateKey: '2026-10-18',
      completionEventId: 'event-1',
      value: 3,
    );

    final body = jsonDecode(capture.body) as Map<String, dynamic>;
    expect(capture.url.path, '/rest/v1/rpc/complete_habit_economy_v1');
    expect(body['p_client_version'], '1.0.4');
    expect(body['p_request_id'], 'request-1');
    expect(body['p_value'], 3);
  });
}

class _CaptureClient extends http.BaseClient {
  late Uri url;
  late String body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    url = request.url;
    body = await request.finalize().bytesToString();
    final response = http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
    return response;
  }
}
