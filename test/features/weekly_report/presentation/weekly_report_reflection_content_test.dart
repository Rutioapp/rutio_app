import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/diary_entry.dart';

void main() {
  test('weekly reflection stores content once in canonical text', () {
    const entry = DiaryEntry(
      id: 'reflection-1',
      createdAt: 1,
      text: 'Ha sido una buena semana',
      body: null,
      mood: 2,
      entryType: DiaryEntryContentType.reflection,
      weeklyReportId: 'report-1',
    );

    expect(entry.text, 'Ha sido una buena semana');
    expect(entry.body, isNull);
    expect(entry.title, isNull);
    expect(entry.legacyText, 'Ha sido una buena semana');
    expect(entry.toJson()['body'], isNull);
  });

  test('canonical text still supports update and clear', () {
    const updated = DiaryEntry(
      id: 'reflection-1',
      createdAt: 1,
      text: 'Texto B',
      mood: 2,
      entryType: DiaryEntryContentType.reflection,
      weeklyReportId: 'report-1',
    );
    const cleared = DiaryEntry(
      id: 'reflection-1',
      createdAt: 1,
      text: '',
      mood: 2,
      entryType: DiaryEntryContentType.reflection,
      weeklyReportId: 'report-1',
    );

    expect(updated.legacyText, 'Texto B');
    expect(cleared.legacyText, isEmpty);
    expect(cleared.id, updated.id);
    expect(cleared.weeklyReportId, updated.weeklyReportId);
  });
}
