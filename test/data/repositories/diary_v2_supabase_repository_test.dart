import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rutio/data/repositories/diary_v2_supabase_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/models/daily_mood.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('DiaryV2SupabaseRepository diary entry mapping', () {
    test('maps DiaryEntry to Supabase row safely', () {
      const entry = DiaryEntry(
        id: 'local-entry-1',
        createdAt: 1718445600123,
        text: 'ignored legacy payload',
        title: 'Morning reset',
        body: 'I walked outside before breakfast.',
        remoteId: 'remote-ignored-locally',
        mood: 2,
        entryType: DiaryEntryContentType.learning,
        tags: <String>['focus', 'Focus', 'sleep', 'unknown'],
        isPinned: true,
        habitId: 'habit-1',
        familyId: 'mind',
      );

      final row = DiaryV2SupabaseRepository.diaryEntryToRow(
        entry,
        userId: 'user-123',
      );

      expect(row['user_id'], 'user-123');
      expect(row['local_id'], 'local-entry-1');
      expect(row['entry_date'], '2024-06-15');
      expect(row['local_created_at_ms'], 1718445600123);
      expect(row['title'], 'Morning reset');
      expect(row['body'], 'I walked outside before breakfast.');
      expect(
        row['legacy_text'],
        'Morning reset\n\nI walked outside before breakfast.',
      );
      expect(row['mood'], 2);
      expect(row['entry_type'], 'learning');
      expect(row['tags'], <String>['focus', 'sleep']);
      expect(row['is_pinned'], isTrue);
      expect(row['habit_id'], 'habit-1');
      expect(row['family_id'], 'mind');
      expect(row['metadata'], <String, dynamic>{});
      expect(row.containsKey('id'), isFalse);
    });

    test('maps Supabase row to DiaryEntry with legacy fallback and tags', () {
      final row = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440000',
        'user_id': 'user-123',
        'local_id': 'local-entry-1',
        'entry_date': '2026-06-13',
        'created_at': '2026-06-13T10:15:00.000Z',
        'updated_at': '2026-06-13T11:15:00.000Z',
        'local_created_at_ms': 1718445600123,
        'title': null,
        'body': null,
        'legacy_text': 'Solo texto legado',
        'mood': '1',
        'entry_type': 'reflection',
        'tags': <String>['energy', 'Energy', 'idea', 'unsupported'],
        'is_pinned': true,
        'habit_id': 'habit-1',
        'family_id': 'body',
        'metadata': <String, dynamic>{},
      };

      final entry = DiaryV2SupabaseRepository.diaryEntryFromRow(row);

      expect(entry.id, 'local-entry-1');
      expect(entry.remoteId, '550e8400-e29b-41d4-a716-446655440000');
      expect(entry.createdAt, 1718445600123);
      expect(entry.title, isNull);
      expect(entry.body, isNull);
      expect(entry.text, 'Solo texto legado');
      expect(entry.legacyText, 'Solo texto legado');
      expect(entry.mood, 1);
      expect(entry.entryType, DiaryEntryContentType.reflection);
      expect(entry.tags, <String>['energy', 'idea']);
      expect(entry.isPinned, isTrue);
      expect(entry.habitId, 'habit-1');
      expect(entry.familyId, 'body');
    });

    test('unknown entry_type values are ignored safely', () {
      final row = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440222',
        'user_id': 'user-123',
        'local_id': 'local-entry-2',
        'entry_date': '2026-06-13',
        'legacy_text': 'Legacy',
        'entry_type': 'legacy-unknown',
        'metadata': <String, dynamic>{},
      };

      final entry = DiaryV2SupabaseRepository.diaryEntryFromRow(row);

      expect(entry.entryType, isNull);
    });

    test('entry mood and daily mood stay separate concepts', () {
      const entry = DiaryEntry(
        id: 'local-entry-2',
        createdAt: 1718445600123,
        text: 'Legacy',
        mood: -1,
      );
      final dailyMood = DailyMood(
        date: DateTime(2026, 6, 13),
        mood: 2,
        createdAt: 10,
        updatedAt: 20,
      );

      final entryRow = DiaryV2SupabaseRepository.diaryEntryToRow(
        entry,
        userId: 'user-123',
      );
      final dailyMoodRow = DiaryV2SupabaseRepository.dailyMoodToRow(
        dailyMood,
        userId: 'user-123',
      );

      expect(entryRow['mood'], -1);
      expect(dailyMoodRow['mood'], 2);
      expect(entryRow.containsKey('mood_date'), isFalse);
      expect(dailyMoodRow.containsKey('entry_date'), isFalse);
    });
  });

  group('DiaryV2SupabaseRepository diary entry requests', () {
    test('upsertDiaryEntry sends entry_type on insert', () async {
      final client = _EchoingHttpClient(
        responseBuilder: (request) {
          final body = _requestBodyAsMap(request);
          return <String, dynamic>{
            'id': '550e8400-e29b-41d4-a716-446655440333',
            ...body,
            'created_at': '2026-06-13T10:15:00.000Z',
            'updated_at': '2026-06-13T10:15:00.000Z',
            'metadata': <String, dynamic>{},
          };
        },
      );
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      const entry = DiaryEntry(
        id: 'local-entry-1',
        createdAt: 1718445600123,
        text: 'Learning entry',
        title: 'Learning entry',
        body: 'Notes',
        entryType: DiaryEntryContentType.learning,
      );

      final result = await repository.upsertDiaryEntry(entry);

      expect(result.isSuccess, isTrue);
      expect(result.data?.entryType, DiaryEntryContentType.learning);
      expect(client.lastRequestBodyMap?['entry_type'], 'learning');
      expect(client.lastMethod, 'POST');
      expect(client.lastUri?.path, '/rest/v1/diary_entries');
    });

    test('upsertDiaryEntry can modify entry_type and clear it back to null',
        () async {
      final client = _EchoingHttpClient(
        responseBuilder: (request) {
          final body = _requestBodyAsMap(request);
          return <String, dynamic>{
            'id': body['id'] ?? '550e8400-e29b-41d4-a716-446655440444',
            ...body,
            'created_at': '2026-06-13T10:15:00.000Z',
            'updated_at': '2026-06-13T11:15:00.000Z',
            'metadata': <String, dynamic>{},
          };
        },
      );
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      const firstEntry = DiaryEntry(
        id: 'local-entry-2',
        createdAt: 1718445600123,
        text: 'Reflection entry',
        title: 'Reflection entry',
        body: 'First version',
        entryType: DiaryEntryContentType.reflection,
      );
      final firstResult = await repository.upsertDiaryEntry(firstEntry);
      expect(firstResult.isSuccess, isTrue);
      expect(client.lastRequestBodyMap?['entry_type'], 'reflection');

      final updatedEntry = firstEntry.copyWith(
        text: 'Updated entry',
        title: 'Updated entry',
        body: 'Second version',
        entryType: null,
      );
      final secondResult = await repository.upsertDiaryEntry(updatedEntry);
      expect(secondResult.isSuccess, isTrue);
      expect(client.lastRequestBodyMap?['entry_type'], isNull);
      expect(secondResult.data?.entryType, isNull);
    });

    test('fetchDiaryEntriesForCurrentUser maps entry_type from remote rows',
        () async {
      final client = _EchoingHttpClient(
        responseBuilder: (request) => <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440555',
              'user_id': 'user-123',
              'local_id': 'local-entry-3',
              'entry_date': '2026-06-13',
              'created_at': '2026-06-13T10:15:00.000Z',
              'updated_at': '2026-06-13T11:15:00.000Z',
              'local_created_at_ms': 1718445600123,
              'title': 'Moment title',
              'body': 'Moment body',
              'legacy_text': 'Moment title\n\nMoment body',
              'mood': 2,
              'entry_type': 'moment',
              'tags': <String>['gratitude'],
              'is_pinned': false,
              'habit_id': null,
              'family_id': null,
              'metadata': <String, dynamic>{},
            },
          ],
        },
      );
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchDiaryEntriesForCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.single.entryType, DiaryEntryContentType.moment);
    });

    test('fetchDiaryEntriesForCurrentUser treats unknown entry_type as null',
        () async {
      final client = _EchoingHttpClient(
        responseBuilder: (request) => <String, dynamic>{
          'data': <Map<String, dynamic>>[
            <String, dynamic>{
              'id': '550e8400-e29b-41d4-a716-446655440666',
              'user_id': 'user-123',
              'local_id': 'local-entry-4',
              'entry_date': '2026-06-13',
              'created_at': '2026-06-13T10:15:00.000Z',
              'updated_at': '2026-06-13T11:15:00.000Z',
              'local_created_at_ms': 1718445600123,
              'legacy_text': 'Legacy',
              'entry_type': 'legacy-unknown',
              'metadata': <String, dynamic>{},
            },
          ],
        },
      );
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: client,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.fetchDiaryEntriesForCurrentUser();

      expect(result.isSuccess, isTrue);
      expect(result.data, hasLength(1));
      expect(result.data!.single.entryType, isNull);
    });
  });

  group('DiaryV2SupabaseRepository daily mood mapping', () {
    test('maps DailyMood to Supabase row safely', () {
      final dailyMood = DailyMood(
        date: DateTime(2026, 6, 13, 18, 45),
        mood: 2,
        note: 'Buen dia',
        createdAt: 100,
        updatedAt: 200,
      );

      final row = DiaryV2SupabaseRepository.dailyMoodToRow(
        dailyMood,
        userId: 'user-123',
      );

      expect(row['user_id'], 'user-123');
      expect(row['mood_date'], '2026-06-13');
      expect(row['mood'], 2);
      expect(row['note'], 'Buen dia');
      expect(row['local_created_at_ms'], 100);
      expect(row['local_updated_at_ms'], 200);
      expect(row['metadata'], <String, dynamic>{});
    });

    test('maps Supabase row to DailyMood with date conversion fallback', () {
      final row = <String, dynamic>{
        'id': '550e8400-e29b-41d4-a716-446655440111',
        'user_id': 'user-123',
        'mood_date': '2026-06-13',
        'mood': '2',
        'note': 'Buen dia',
        'created_at': '2026-06-13T08:00:00.000Z',
        'updated_at': '2026-06-13T09:00:00.000Z',
        'metadata': <String, dynamic>{},
      };

      final dailyMood = DiaryV2SupabaseRepository.dailyMoodFromRow(row);

      expect(dailyMood.date, DateTime(2026, 6, 13));
      expect(dailyMood.dateKey, '2026-06-13');
      expect(dailyMood.mood, 2);
      expect(dailyMood.note, 'Buen dia');
      expect(dailyMood.createdAt, greaterThan(0));
      expect(dailyMood.updatedAt, greaterThanOrEqualTo(dailyMood.createdAt));
    });
  });

  group('DiaryV2SupabaseRepository auth safety', () {
    test('upsertDiaryEntry fails safely without authenticated user', () async {
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient('https://example.com', 'anon-key'),
        currentUserIdProvider: () => null,
      );

      const entry = DiaryEntry(
        id: 'local-entry-1',
        createdAt: 1718445600123,
        text: 'Legacy',
      );

      final result = await repository.upsertDiaryEntry(entry);

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    });

    test('upsertDailyMood fails safely without authenticated user', () async {
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient('https://example.com', 'anon-key'),
        currentUserIdProvider: () => null,
      );

      final result = await repository.upsertDailyMood(
        DailyMood(
          date: DateTime(2026, 6, 13),
          mood: 2,
          createdAt: 10,
          updatedAt: 20,
        ),
      );

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    });

    test('fetch methods return empty results safely without authenticated user',
        () async {
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient('https://example.com', 'anon-key'),
        currentUserIdProvider: () => null,
      );

      final entriesResult = await repository.fetchDiaryEntriesForCurrentUser();
      final moodsResult = await repository.fetchDailyMoodsForCurrentUser();

      expect(entriesResult.isSuccess, isTrue);
      expect(entriesResult.data, isEmpty);
      expect(moodsResult.isSuccess, isTrue);
      expect(moodsResult.data, isEmpty);
    });

    test('deleteDiaryEntryByLocalId fails safely without authenticated user',
        () async {
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient('https://example.com', 'anon-key'),
        currentUserIdProvider: () => null,
      );

      final result = await repository.deleteDiaryEntryByLocalId('local-entry-1');

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    });

    test('deleteDailyMoodByDate fails safely without authenticated user',
        () async {
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient('https://example.com', 'anon-key'),
        currentUserIdProvider: () => null,
      );

      final result = await repository.deleteDailyMoodByDate(DateTime(2026, 6, 13));

      expect(result.isSuccess, isFalse);
      expect(result.error?.code, RepositoryErrorCode.notAuthenticated);
    });
  });

  group('DiaryV2SupabaseRepository delete behavior', () {
    test('deleteDiaryEntryByLocalId applies user_id and local_id filters',
        () async {
      final recordingClient = _RecordingHttpClient();
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: recordingClient,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.deleteDiaryEntryByLocalId('local-entry-1');

      expect(result.isSuccess, isTrue);
      expect(recordingClient.lastMethod, 'DELETE');
      expect(recordingClient.lastUri?.path, '/rest/v1/diary_entries');
      expect(recordingClient.lastUri?.queryParameters['user_id'], 'eq.user-123');
      expect(
        recordingClient.lastUri?.queryParameters['local_id'],
        'eq.local-entry-1',
      );
      expect(recordingClient.lastUri?.queryParameters.containsKey('id'), isFalse);
    });

    test('deleteDiaryEntry prefers local_id over remote uuid when both exist',
        () async {
      final recordingClient = _RecordingHttpClient();
      final repository = DiaryV2SupabaseRepository(
        client: SupabaseClient(
          'https://example.com',
          'anon-key',
          httpClient: recordingClient,
        ),
        currentUserIdProvider: () => 'user-123',
      );

      final result = await repository.deleteDiaryEntry(
        localId: 'local-entry-1',
        remoteId: '550e8400-e29b-41d4-a716-446655440000',
      );

      expect(result.isSuccess, isTrue);
      expect(recordingClient.lastUri?.queryParameters['user_id'], 'eq.user-123');
      expect(
        recordingClient.lastUri?.queryParameters['local_id'],
        'eq.local-entry-1',
      );
      expect(recordingClient.lastUri?.queryParameters.containsKey('id'), isFalse);
    });
  });
}

class _RecordingHttpClient extends http.BaseClient {
  Uri? lastUri;
  String? lastMethod;
  Map<String, String>? lastHeaders;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;
    lastHeaders = Map<String, String>.from(request.headers);

    return http.StreamedResponse(
      const Stream<List<int>>.empty(),
      204,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}

class _EchoingHttpClient extends http.BaseClient {
  _EchoingHttpClient({
    required this.responseBuilder,
  });

  final Map<String, dynamic> Function(http.BaseRequest request) responseBuilder;

  Uri? lastUri;
  String? lastMethod;
  String? lastRequestBody;
  Map<String, dynamic>? lastRequestBodyMap;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastUri = request.url;
    lastMethod = request.method;

    if (request is http.Request) {
      lastRequestBody = request.body;
      if (request.body.isNotEmpty) {
        final decoded = jsonDecode(request.body);
        if (decoded is Map<String, dynamic>) {
          lastRequestBodyMap = decoded;
        }
      }
    }

    final body = responseBuilder(request);
    final isArray = body.containsKey('data');
    final responseJson = isArray ? body['data'] : body;
    final bytes = utf8.encode(jsonEncode(responseJson));

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      200,
      request: request,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
}

Map<String, dynamic> _requestBodyAsMap(http.BaseRequest request) {
  if (request is! http.Request || request.body.isEmpty) {
    return <String, dynamic>{};
  }

  final decoded = jsonDecode(request.body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }

  return <String, dynamic>{};
}
