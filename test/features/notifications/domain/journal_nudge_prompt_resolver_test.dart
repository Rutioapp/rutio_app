import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/journal_nudge_prompt_resolver.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

void main() {
  const resolver = JournalNudgePromptResolver();
  const templateIds = <String>[
    'journal.nudge.milestone.7.insight_01',
    'journal.nudge.milestone.7.change_01',
    'journal.nudge.milestone.7.ease_01',
    'journal.nudge.milestone.7.return_01',
    'journal.nudge.milestone.7.memory_01',
    'journal.nudge.milestone.14.insight_01',
    'journal.nudge.milestone.14.change_01',
    'journal.nudge.milestone.14.ease_01',
    'journal.nudge.milestone.14.return_01',
    'journal.nudge.milestone.14.memory_01',
    'journal.nudge.milestone.30.insight_01',
    'journal.nudge.milestone.30.change_01',
    'journal.nudge.milestone.30.ease_01',
    'journal.nudge.milestone.30.return_01',
    'journal.nudge.milestone.30.memory_01',
    'journal.nudge.perfect_day.insight_01',
    'journal.nudge.perfect_day.difference_01',
    'journal.nudge.perfect_day.decision_01',
    'journal.nudge.perfect_day.energy_01',
    'journal.nudge.perfect_day.ease_01',
    'journal.nudge.perfect_day.tomorrow_01',
    'journal.nudge.perfect_day.moment_01',
    'journal.nudge.perfect_day.learning_01',
    'journal.nudge.perfect_day.feeling_01',
    'journal.nudge.perfect_day.marker_01',
    'journal.nudge.perfect_day.meaning_01',
    'journal.nudge.perfect_day.note_01',
    'journal.nudge.end_of_day.reflection_01',
    'journal.nudge.end_of_day.energy_01',
    'journal.nudge.end_of_day.drain_01',
    'journal.nudge.end_of_day.memory_01',
    'journal.nudge.end_of_day.difference_01',
    'journal.nudge.end_of_day.learning_01',
    'journal.nudge.end_of_day.describe_01',
    'journal.nudge.end_of_day.keep_01',
    'journal.nudge.end_of_day.surprise_01',
    'journal.nudge.end_of_day.release_01',
    'journal.nudge.end_of_day.notice_01',
    'journal.nudge.end_of_day.question_01',
  ];

  test('resolves every prompt in Spanish and English', () {
    final es = AppLocalizationsEs();
    final en = AppLocalizationsEn();

    expect(
      templateIds
          .map((id) => resolver.resolve(l10n: es, templateId: id))
          .every((prompt) => prompt != null && prompt.isNotEmpty),
      isTrue,
    );
    expect(
      templateIds
          .map((id) => resolver.resolve(l10n: en, templateId: id))
          .every((prompt) => prompt != null && prompt.isNotEmpty),
      isTrue,
    );
  });

  test('returns null for an unknown template', () {
    expect(
      resolver.resolve(
        l10n: AppLocalizationsEs(),
        templateId: 'journal.nudge.unknown',
      ),
      isNull,
    );
  });
}
