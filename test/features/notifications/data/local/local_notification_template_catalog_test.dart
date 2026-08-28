import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/asset_json_loader.dart';
import 'package:rutio/features/notifications/data/local/local_notification_template_catalog.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalNotificationTemplateCatalog', () {
    final catalog = LocalNotificationTemplateCatalog(
      assetJsonLoader: AssetJsonLoader(),
    );

    test('loads the seeded notification catalog', () async {
      final templates = await catalog.listAll();

      expect(templates, hasLength(26));
      expect(
        templates.map((template) => template.templateId).toSet(),
        hasLength(26),
      );
    });

    test('returns a template by id with its metadata', () async {
      final template = await catalog.getById('general.streak.encouragement_02');

      expect(template, isNotNull);
      expect(template!.templateKey, 'generalStreakEncouragement02');
      expect(template.category, NotificationTemplateCategory.streak);
      expect(template.isFallbackCandidate, isFalse);
      expect(template.eligibility.requiresDisplayName, isTrue);
      expect(template.eligibility.minStreak, 3);
      expect(
        template.requiredVariables,
        <NotificationTemplateVariable>[
          NotificationTemplateVariable.displayName,
          NotificationTemplateVariable.streak,
        ],
      );
    });

    test('filters templates by kind and category', () async {
      final streakTemplates = await catalog.listByKind(
        NotificationKind.generalStreakRisk,
      );
      final reflectionTemplates = await catalog.listByCategory(
        NotificationTemplateCategory.reflection,
      );

      expect(streakTemplates, isNotEmpty);
      expect(
        streakTemplates.every(
          (template) => template.supports(NotificationKind.generalStreakRisk),
        ),
        isTrue,
      );
      expect(reflectionTemplates, hasLength(3));
      expect(
        reflectionTemplates.every(
          (template) =>
              template.category == NotificationTemplateCategory.reflection,
        ),
        isTrue,
      );
    });

    test('reads selection metadata such as fallback and time windows',
        () async {
      final fallbackTemplate = await catalog.getById(
        'general.encouragement.neutral_01',
      );
      final morningTemplate = await catalog.getById(
        'general.morning.gentle_01',
      );

      expect(fallbackTemplate, isNotNull);
      expect(fallbackTemplate!.isFallbackCandidate, isTrue);
      expect(fallbackTemplate.eligibility.hasRules, isFalse);

      expect(morningTemplate, isNotNull);
      expect(
        morningTemplate!.eligibility.allowedTimesOfDay,
        <NotificationContextTimeOfDay>[NotificationContextTimeOfDay.morning],
      );
    });
  });
}
