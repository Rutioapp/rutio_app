import 'package:flutter_test/flutter_test.dart';
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
      expect(entry.tags, <String>['energy', 'idea']);
      expect(entry.isPinned, isTrue);
      expect(entry.habitId, 'habit-1');
      expect(entry.familyId, 'body');
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
  });
}
