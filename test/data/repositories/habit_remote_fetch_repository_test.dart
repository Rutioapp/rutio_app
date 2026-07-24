import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/models/remote/remote_habit.dart';
import 'package:rutio/data/repositories/habit_log_repository.dart';
import 'package:rutio/data/repositories/habit_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('HabitRepository remote fetch', () {
    test('fetchHabitsForCurrentUser returns empty safely without auth',
        () async {
      final client = _QueueingHttpClient();
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => null,
      );

      final result = await repository.fetchHabitsForCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
      expect(client.callCount, 0);
    });

    test(
        'fetchHabitsForCurrentUser maps remote habits and preserves remote user scope rows',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440000',
              'user_id': 'user-123',
              'name': 'Drink Water',
              'family_id': 'health',
              'emoji': '💧',
              'habit_type': 'check',
              'target_count': null,
              'unit': null,
              'color_id': 'blue',
              'reminder_enabled': true,
              'reminder_time': '08:30:00',
              'schedule': <String, dynamic>{
                'type': 'weekly',
                'weekdays': <int>[1, 3, 5],
              },
              'is_archived': true,
              'sort_order': 2,
              'created_at': '2026-06-20T08:00:00.000Z',
              'updated_at': '2026-06-21T08:00:00.000Z',
            },
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440001',
              'user_id': 'user-123',
              'name': 'Push Ups',
              'family_id': 'fitness',
              'emoji': '💪',
              'habit_type': 'count',
              'target_count': 25,
              'unit': 'reps',
              'color_id': 'red',
              'reminder_enabled': false,
              'reminder_time': null,
              'is_archived': false,
              'sort_order': 3,
              'created_at': '2026-06-19T08:00:00.000Z',
              'updated_at': '2026-06-21T09:00:00.000Z',
            },
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440999',
              'user_id': 'user-999',
              'name': 'Foreign Habit',
              'habit_type': 'check',
              'reminder_enabled': false,
              'is_archived': false,
              'sort_order': 99,
            },
          ],
        );
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchHabitsForCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(3));
      expect(client.lastUri?.path, '/rest/v1/habits');
      expect(client.lastUri?.queryParameters['user_id'], 'eq.user-123');

      final archivedHabit = result.data!.first;
      expect(archivedHabit.id, '550e8400-e29b-41d4-a716-446655440000');
      expect(archivedHabit.userId, 'user-123');
      expect(archivedHabit.habitType, 'check');
      expect(archivedHabit.isArchived, isTrue);
      expect(archivedHabit.reminderTime, '08:30:00');
      expect(archivedHabit.schedule, {
        'type': 'weekly',
        'weekdays': <int>[1, 3, 5],
      });

      final countHabit = result.data![1];
      expect(countHabit.id, '550e8400-e29b-41d4-a716-446655440001');
      expect(countHabit.habitType, 'count');
      expect(countHabit.targetCount, 25);
      expect(countHabit.unit, 'reps');

      final foreignHabit = result.data![2];
      expect(foreignHabit.id, '550e8400-e29b-41d4-a716-446655440999');
      expect(foreignHabit.userId, 'user-999');
    });

    test('fetchHabitsForCurrentUser returns empty collection for empty remote',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(statusCode: 200, body: const <dynamic>[]);
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchHabitsForCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('upsertHabitForCurrentUser sends canonical schedule to Supabase',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <String, dynamic>{
            'id': '550e8400-e29b-41d4-a716-446655440000',
            'user_id': 'user-123',
            'name': 'Read',
            'habit_type': 'check',
            'reminder_enabled': false,
            'schedule': <String, dynamic>{
              'type': 'timesPerWeek',
              'timesPerWeek': 3,
              'weekStartsOn': 1,
            },
            'is_archived': false,
            'sort_order': 0,
          },
        );
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.upsertHabitForCurrentUser(
        const RemoteHabit(
          userId: 'user-123',
          name: 'Read',
          habitType: 'check',
          reminderEnabled: false,
          schedule: <String, dynamic>{
            'type': 'timesPerWeek',
            'timesPerWeekTarget': 3,
            'weekStartsOn': 1,
          },
          isArchived: false,
          sortOrder: 0,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(client.lastMethod, 'POST');
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['schedule'], {
        'type': 'timesPerWeek',
        'timesPerWeek': 3,
        'weekStartsOn': 1,
      });
    });

    test(
        'upsertHabitForCurrentUser backfills schedule when editing existing habit',
        () async {
      const remoteHabitId = '550e8400-e29b-41d4-a716-446655440000';
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': remoteHabitId,
              'user_id': 'user-123',
              'name': 'Read',
              'habit_type': 'check',
              'reminder_enabled': false,
              'schedule': <String, dynamic>{
                'type': 'weekly',
                'weekdays': <int>[1, 3, 5],
              },
              'is_archived': false,
              'sort_order': 0,
            },
          ],
        );
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.upsertHabitForCurrentUser(
        const RemoteHabit(
          id: remoteHabitId,
          userId: 'user-123',
          name: 'Read',
          habitType: 'check',
          reminderEnabled: false,
          schedule: <String, dynamic>{
            'type': 'weekly',
            'weekdays': <int>[5, 1, 3],
          },
          isArchived: false,
          sortOrder: 0,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(client.lastMethod, 'PATCH');
      expect(client.lastUri?.queryParameters['id'], 'eq.$remoteHabitId');
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(body['schedule'], {
        'type': 'weekly',
        'weekdays': <int>[1, 3, 5],
      });
    });

    test('fetchHabitsForCurrentUser maps permission errors consistently',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueRaw(
          statusCode: 403,
          body: jsonEncode(
            <String, dynamic>{
              'code': '42501',
              'message': 'permission denied for table habits',
            },
          ),
        );
      final repository = HabitRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchHabitsForCurrentUser();

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.permissionDenied);
    });
  });

  group('HabitLogRepository remote fetch', () {
    test('fetch methods return empty safely without auth', () async {
      final client = _QueueingHttpClient();
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => null,
      );

      final rangeResult = await repository.fetchLogsForDateRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );
      final habitResult = await repository.fetchLogsForHabit(
        '550e8400-e29b-41d4-a716-446655440000',
      );
      final habitsResult = await repository.fetchLogsForHabits(
        const <String>['550e8400-e29b-41d4-a716-446655440000'],
      );

      expect(rangeResult.isSuccess, isTrue);
      expect(rangeResult.data, isEmpty);
      expect(habitResult.isSuccess, isTrue);
      expect(habitResult.data, isEmpty);
      expect(habitsResult.isSuccess, isTrue);
      expect(habitsResult.data, isEmpty);
      expect(client.callCount, 0);
    });

    test(
        'fetchLogsForHabits maps count/check rows and preserves remote ownership fields',
        () async {
      const habitA = '550e8400-e29b-41d4-a716-446655440000';
      const habitB = '550e8400-e29b-41d4-a716-446655440001';

      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440000',
              'user_id': 'user-123',
              'habit_id': habitA,
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'note': 'Done early',
              'source': 'manual',
              'created_at': '2026-06-20T06:00:00.000Z',
              'updated_at': '2026-06-20T06:30:00.000Z',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440001',
              'user_id': 'user-123',
              'habit_id': habitB,
              'log_date': '2026-06-21',
              'value': 7,
              'is_completed': false,
              'note': 'Partial',
              'source': 'system',
              'created_at': '2026-06-21T06:00:00.000Z',
              'updated_at': '2026-06-21T06:30:00.000Z',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440002',
              'user_id': 'user-999',
              'habit_id': habitA,
              'log_date': '2026-06-22',
              'value': 1,
              'is_completed': true,
              'note': 'Foreign user',
              'source': 'manual',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440003',
              'user_id': 'user-123',
              'habit_id': '550e8400-e29b-41d4-a716-446655449999',
              'log_date': '2026-06-22',
              'value': 10,
              'is_completed': true,
              'note': 'Foreign habit',
              'source': 'manual',
            },
          ],
        );
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchLogsForHabits(
        const <String>[habitA, habitB],
        start: DateTime(2026, 6, 20),
        end: DateTime(2026, 6, 21),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(4));
      expect(client.lastUri?.path, '/rest/v1/habit_logs');
      expect(client.lastUri?.queryParameters['user_id'], 'eq.user-123');
      expect(client.lastUri?.queryParameters['log_date'], 'lte.2026-06-21');
      expect(client.lastUri?.queryParameters['habit_id'], contains(habitA));
      expect(client.lastUri?.queryParameters['habit_id'], contains(habitB));

      final checkLog = result.data!.first;
      expect(checkLog.habitId, habitA);
      expect(checkLog.value, 1);
      expect(checkLog.isCompleted, isTrue);
      expect(checkLog.note, 'Done early');

      final countLog = result.data![1];
      expect(countLog.habitId, habitB);
      expect(countLog.value, 7);
      expect(countLog.isCompleted, isFalse);
      expect(countLog.source, 'system');

      final foreignUserLog = result.data![2];
      expect(foreignUserLog.userId, 'user-999');
      expect(foreignUserLog.habitId, habitA);

      final foreignHabitLog = result.data![3];
      expect(foreignHabitLog.userId, 'user-123');
      expect(foreignHabitLog.habitId, '550e8400-e29b-41d4-a716-446655449999');
    });

    test('fetchLogsForHabit applies auth scope and preserves returned rows',
        () async {
      const habitId = '550e8400-e29b-41d4-a716-446655440000';

      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440010',
              'user_id': 'user-123',
              'habit_id': habitId,
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'source': 'manual',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440011',
              'user_id': 'user-999',
              'habit_id': habitId,
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'source': 'manual',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440012',
              'user_id': 'user-123',
              'habit_id': '550e8400-e29b-41d4-a716-446655449999',
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'source': 'manual',
            },
          ],
        );
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchLogsForHabit(habitId);

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(3));
      expect(client.lastUri?.path, '/rest/v1/habit_logs');
      expect(client.lastUri?.queryParameters['user_id'], 'eq.user-123');
      expect(client.lastUri?.queryParameters['habit_id'], 'eq.$habitId');
      expect(result.data!.first.userId, 'user-123');
      expect(result.data!.first.habitId, habitId);
      expect(result.data![1].userId, 'user-999');
      expect(result.data![2].habitId, '550e8400-e29b-41d4-a716-446655449999');
    });

    test(
        'fetchLogsForDateRange applies auth scope query and preserves returned rows',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(
          statusCode: 200,
          body: <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440020',
              'user_id': 'user-123',
              'habit_id': '550e8400-e29b-41d4-a716-446655440000',
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'source': 'manual',
            },
            <String, dynamic>{
              'id': '660e8400-e29b-41d4-a716-446655440021',
              'user_id': 'user-999',
              'habit_id': '550e8400-e29b-41d4-a716-446655440000',
              'log_date': '2026-06-20',
              'value': 1,
              'is_completed': true,
              'source': 'manual',
            },
          ],
        );
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchLogsForDateRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(2));
      expect(client.lastUri?.path, '/rest/v1/habit_logs');
      expect(client.lastUri?.queryParameters['user_id'], 'eq.user-123');
      expect(result.data!.first.userId, 'user-123');
      expect(result.data![1].userId, 'user-999');
    });

    test('fetchLogsForHabit returns empty collection for empty remote',
        () async {
      final client = _QueueingHttpClient()
        ..enqueueJson(statusCode: 200, body: const <dynamic>[]);
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchLogsForHabit(
        '550e8400-e29b-41d4-a716-446655440000',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('fetchLogsForDateRange maps permission errors consistently', () async {
      final client = _QueueingHttpClient()
        ..enqueueRaw(
          statusCode: 403,
          body: jsonEncode(
            <String, dynamic>{
              'code': '42501',
              'message': 'permission denied for table habit_logs',
            },
          ),
        );
      final repository = HabitLogRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchLogsForDateRange(
        DateTime(2026, 6, 1),
        DateTime(2026, 6, 30),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.permissionDenied);
    });
  });
}

class _QueueingHttpClient extends http.BaseClient {
  final List<_QueuedResponse> _responses = <_QueuedResponse>[];

  Uri? lastUri;
  String? lastMethod;
  String? lastBody;
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
    lastMethod = request.method;
    lastBody = await request.finalize().bytesToString();

    if (_responses.isEmpty) {
      throw StateError(
          'No queued HTTP response for ${request.method} ${request.url}');
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
