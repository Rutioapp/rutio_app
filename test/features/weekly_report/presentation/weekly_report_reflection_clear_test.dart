import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/models/diary_entry.dart';

void main() {
  test('clearing a weekly reflection preserves identity and mood', () {
    const original = DiaryEntry(
      id: 'reflection-1',
      createdAt: 1,
      text: 'Primera reflexión',
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

    expect(cleared.id, original.id);
    expect(cleared.createdAt, original.createdAt);
    expect(cleared.weeklyReportId, original.weeklyReportId);
    expect(cleared.mood, original.mood);
    expect(cleared.text, isEmpty);
    expect(cleared.legacyText, isEmpty);
  });

  test('normal reflection edits still replace text', () {
    const edited = DiaryEntry(
      id: 'reflection-1',
      createdAt: 1,
      text: 'B',
      mood: 2,
      entryType: DiaryEntryContentType.reflection,
      weeklyReportId: 'report-1',
    );
    expect(edited.text, 'B');
  });
}
