import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/repositories/user_progress_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('UserProgressRepository.fetchCurrentProgress', () {
    test('returns notAuthenticated failure safely without auth', () async {
      final client = _QueueingHttpClient();
      final repository = UserProgressRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => null,
      );

      final result = await repository.fetchCurrentProgress();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
      expect(client.callCount, 0);
    });

    test('maps current user progress row from remote response', () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <String, dynamic>{
            'user_id': 'user-123',
            'level': 6,
            'total_xp': 412,
            'current_level_xp': 12,
            'next_level_xp': 88,
            'ambar_balance': 91,
            'total_ambar_earned': 140,
            'total_ambar_spent': 49,
            'created_at': '2026-06-20T08:00:00.000Z',
            'updated_at': '2026-06-21T08:00:00.000Z',
          },
        );
      final repository = UserProgressRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchCurrentProgress();

      expect(result.isSuccess, isTrue);
      expect(client.lastUri?.path, '/rest/v1/user_progress');
      expect(client.lastUri?.queryParameters['user_id'], 'eq.user-123');
      final progress = result.data;
      expect(progress, isNotNull);
      expect(progress!.userId, 'user-123');
      expect(progress.level, 6);
      expect(progress.totalXp, 412);
      expect(progress.currentLevelXp, 12);
      expect(progress.nextLevelXp, 88);
      expect(progress.ambarBalance, 91);
      expect(progress.totalAmbarEarned, 140);
      expect(progress.totalAmbarSpent, 49);
    });

    test('returns null when no remote progress row exists', () async {
      final client = _QueueingHttpClient()
        ..enqueueRaw(statusCode: 200, body: 'null');
      final repository = UserProgressRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchCurrentProgress();

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}

class _QueueingHttpClient extends http.BaseClient {
  final List<_QueuedResponse> _responses = <_QueuedResponse>[];

  Uri? lastUri;
  int callCount = 0;

  void enqueueJson({
    required int statusCode,
    required Object body,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    enqueueRaw(
      statusCode: statusCode,
      body: jsonEncode(body),
      headers: headers,
    );
  }

  void enqueueRaw({
    required int statusCode,
    required String body,
    Map<String, String> headers = const <String, String>{
      'content-type': 'application/json',
    },
  }) {
    _responses.add(
      _QueuedResponse(
        statusCode: statusCode,
        body: body,
        headers: headers,
      ),
    );
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    callCount += 1;
    lastUri = request.url;

    if (_responses.isEmpty) {
      throw StateError('No queued response for ${request.method} ${request.url}');
    }

    final next = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(next.body)),
      next.statusCode,
      request: request,
      headers: next.headers,
    );
  }
}

class _QueuedResponse {
  const _QueuedResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}
