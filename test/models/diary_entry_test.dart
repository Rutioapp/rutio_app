import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/diary_entry.dart';
import 'package:rutio/data/mappers/journal_entry_remote_mapper.dart';

void main() {
  group('DiaryEntry', () {
    test('loads legacy json with only text safely', () {
      final entry = DiaryEntry.fromJson({
        'id': 'legacy',
        'createdAt': 123,
        'text': 'Deporte\n\nHoy sali a caminar.',
      });

      expect(entry.title, 'Deporte');
      expect(entry.body, 'Hoy sali a caminar.');
      expect(entry.legacyText, 'Deporte\n\nHoy sali a caminar.');
    });

    test('loads legacy json without entryType as null', () {
      final entry = DiaryEntry.fromJson({
        'id': 'legacy-null-type',
        'createdAt': 123,
        'text': 'Entrada sin clasificacion',
      });

      expect(entry.entryType, isNull);
    });

    test('loads new json with title and body safely', () {
      final entry = DiaryEntry.fromJson({
        'id': 'new',
        'createdAt': 123,
        'title': 'Deporte',
        'body': 'Hoy sali a caminar.',
      });

      expect(entry.title, 'Deporte');
      expect(entry.body, 'Hoy sali a caminar.');
      expect(entry.text, 'Deporte\n\nHoy sali a caminar.');
    });

    test('toJson preserves compatibility fields', () {
      const entry = DiaryEntry(
        id: 'entry',
        createdAt: 123,
        text: '',
        title: 'Deporte',
        body: 'Hoy sali a caminar.',
      );

      final json = entry.toJson();

      expect(json['title'], 'Deporte');
      expect(json['body'], 'Hoy sali a caminar.');
      expect(json['text'], 'Deporte\n\nHoy sali a caminar.');
    });

    test('serializes and deserializes learning entryType', () {
      const entry = DiaryEntry(
        id: 'learning',
        createdAt: 123,
        text: 'Aprendizaje del dia',
        entryType: DiaryEntryContentType.learning,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.entryType, DiaryEntryContentType.learning);
      expect(restored.toJson()['entryType'], 'learning');
    });

    test('serializes and deserializes reflection entryType', () {
      const entry = DiaryEntry(
        id: 'reflection',
        createdAt: 123,
        text: 'Reflexion del dia',
        entryType: DiaryEntryContentType.reflection,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.entryType, DiaryEntryContentType.reflection);
      expect(restored.toJson()['entryType'], 'reflection');
    });

    test('serializes and deserializes moment entryType', () {
      const entry = DiaryEntry(
        id: 'moment',
        createdAt: 123,
        text: 'Momento del dia',
        entryType: DiaryEntryContentType.moment,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.entryType, DiaryEntryContentType.moment);
      expect(restored.toJson()['entryType'], 'moment');
    });

    test('serializes and deserializes gratitude entryType', () {
      const entry = DiaryEntry(
        id: 'gratitude',
        createdAt: 123,
        text: 'Gratitud del dia',
        entryType: DiaryEntryContentType.gratitude,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.entryType, DiaryEntryContentType.gratitude);
      expect(restored.toJson()['entryType'], 'gratitude');
    });

    test('unknown entryType values are ignored safely', () {
      final entry = DiaryEntry.fromJson({
        'id': 'unknown',
        'createdAt': 123,
        'text': 'Texto',
        'entryType': 'legacy-unknown',
      });

      expect(entry.entryType, isNull);
    });

    test('fromJson without tags defaults to empty list', () {
      final entry = DiaryEntry.fromJson({
        'id': 'no-tags',
        'createdAt': 123,
        'text': 'Entrada simple',
      });

      expect(entry.tags, isEmpty);
    });

    test('fromJson with tags loads normalized supported tags', () {
      final entry = DiaryEntry.fromJson({
        'id': 'with-tags',
        'createdAt': 123,
        'text': 'Entrada simple',
        'tags': ['gratitude', ' energy ', 'custom', 'GRATITUDE'],
      });

      expect(entry.tags, <String>['gratitude', 'energy']);
    });

    test('one-line legacy text becomes title with empty body', () {
      final entry = DiaryEntry.fromJson({
        'id': 'one-line',
        'createdAt': 123,
        'text': 'Solo una linea',
      });

      expect(entry.title, 'Solo una linea');
      expect(entry.body, isNull);
      expect(entry.textParts.body, isEmpty);
    });

    test('multi-line legacy text falls back to first non-empty line plus rest', () {
      final entry = DiaryEntry.fromJson({
        'id': 'multi-line',
        'createdAt': 123,
        'text': '\n  Deporte  \n\n  Hoy me senti mejor. \n  Sali a caminar.  ',
      });

      expect(entry.title, 'Deporte');
      expect(entry.body, 'Hoy me senti mejor.\nSali a caminar.');
    });

    test('whitespace-only legacy text stays safe and null-friendly', () {
      final entry = DiaryEntry.fromJson({
        'id': 'blank',
        'createdAt': '123',
        'text': '  \n \n  ',
        'title': '   ',
        'body': '\n\n',
      });

      expect(entry.title, isNull);
      expect(entry.body, isNull);
      expect(entry.text, isEmpty);
      expect(entry.legacyText, isEmpty);
      expect(entry.textParts.title, isEmpty);
      expect(entry.textParts.body, isEmpty);
    });

    test('body-only entries keep body without fabricating a title in json', () {
      const entry = DiaryEntry(
        id: 'body-only',
        createdAt: 123,
        text: '',
        body: 'Hoy me senti sin energia pero sali a caminar.',
      );

      final json = entry.toJson();

      expect(json['title'], isNull);
      expect(json['body'], 'Hoy me senti sin energia pero sali a caminar.');
      expect(json['text'], 'Hoy me senti sin energia pero sali a caminar.');
    });

    test('serialization round-trip preserves legacy compatibility fields', () {
      const entry = DiaryEntry(
        id: 'round-trip',
        createdAt: 123,
        text: '',
        title: 'Deporte',
        body: 'Hoy me senti mejor.',
        remoteId: 'remote-1',
        habitId: 'habit-1',
        familyId: 'body',
        mood: 1,
        entryType: DiaryEntryContentType.moment,
        tags: <String>['focus', 'sleep'],
        isPinned: true,
      );

      final restored = DiaryEntry.fromJson(entry.toJson());

      expect(restored.id, 'round-trip');
      expect(restored.createdAt, 123);
      expect(restored.title, 'Deporte');
      expect(restored.body, 'Hoy me senti mejor.');
      expect(restored.text, 'Deporte\n\nHoy me senti mejor.');
      expect(restored.remoteId, 'remote-1');
      expect(restored.habitId, 'habit-1');
      expect(restored.familyId, 'body');
      expect(restored.mood, 1);
      expect(restored.entryType, DiaryEntryContentType.moment);
      expect(restored.tags, <String>['focus', 'sleep']);
      expect(restored.isPinned, isTrue);
    });

    test('copyWith preserves, changes and clears entryType', () {
      const entry = DiaryEntry(
        id: 'copy-with',
        createdAt: 123,
        text: 'Texto',
        entryType: DiaryEntryContentType.learning,
      );

      final preserved = entry.copyWith();
      final changed = entry.copyWith(
        entryType: DiaryEntryContentType.gratitude,
      );
      final cleared = entry.copyWith(entryType: null);

      expect(preserved.entryType, DiaryEntryContentType.learning);
      expect(changed.entryType, DiaryEntryContentType.gratitude);
      expect(cleared.entryType, isNull);
    });
  });

  group('JournalEntryRemoteMapper', () {
    test('maps legacy text entries without requiring title/body columns', () {
      final localEntryMap = <String, dynamic>{
        'id': 'legacy',
        'createdAt': 1718236800000,
        'text': 'Deporte\n\nHoy sali a caminar.',
      };

      final localEntry = DiaryEntry.fromJson(localEntryMap);
      final remote = JournalEntryRemoteMapper.toRemoteJournalEntry(
        localEntry: localEntry,
        localEntryMap: localEntryMap,
        userId: 'user-1',
        activeHabits: const [],
      );

      expect(remote, isNotNull);
      expect(remote!.content, 'Deporte\n\nHoy sali a caminar.');
      expect(remote.title, 'Deporte');
      expect(remote.toUpsertMap().containsKey('body'), isFalse);
    });

    test('maps new title/body entries while preserving legacy content', () {
      final localEntryMap = <String, dynamic>{
        'id': 'new',
        'createdAt': 1718236800000,
        'title': 'Deporte',
        'body': 'Hoy sali a caminar.',
        'text': 'Deporte\n\nHoy sali a caminar.',
        'updatedAtRemote': '2026-06-13T10:15:00Z',
      };

      final localEntry = DiaryEntry.fromJson(localEntryMap);
      final remote = JournalEntryRemoteMapper.toRemoteJournalEntry(
        localEntry: localEntry,
        localEntryMap: localEntryMap,
        userId: 'user-1',
        activeHabits: const [],
      );

      expect(remote, isNotNull);
      expect(remote!.title, 'Deporte');
      expect(remote.content, 'Deporte\n\nHoy sali a caminar.');
      expect(remote.updatedAt?.toUtc().toIso8601String(), '2026-06-13T10:15:00.000Z');
      expect(remote.toUpsertMap()['content'], 'Deporte\n\nHoy sali a caminar.');
      expect(remote.toUpsertMap().containsKey('body'), isFalse);
    });
  });
}
