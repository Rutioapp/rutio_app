import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/diary_entry.dart';

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
  });
}
