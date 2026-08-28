import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/local/asset_json_loader.dart';
import 'package:rutio/features/notifications/data/local/local_notification_template_catalog.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationLocalizedCopyResolver', () {
    final catalog = LocalNotificationTemplateCatalog(
      assetJsonLoader: AssetJsonLoader(),
    );
    final resolver = NotificationLocalizedCopyResolver();

    Future<NotificationTemplateDescriptor> loadTemplate(
        String templateId) async {
      final template = await catalog.getById(templateId);
      expect(template, isNotNull);
      return template!;
    }

    test('renders a template without variables', () async {
      final template = await loadTemplate('general.morning.gentle_01');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(),
        localeCode: 'en',
      );

      expect(content.templateId, template.templateId);
      expect(content.title, 'Rutio is still here');
      expect(
          content.body, 'Start at your own pace. A small step still counts.');
      expect(content.resolvedVariables, isEmpty);
    });

    test('renders optional displayName when present and preserves characters',
        () async {
      final template = await loadTemplate('general.comeback.gentle_02');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(displayName: 'Álex'),
        localeCode: 'es',
      );

      expect(content.body, contains('Álex'));
      expect(content.body, isNot(contains('{displayName}')));
    });

    test('uses fallback branch when an optional variable is absent', () async {
      final template = await loadTemplate('general.motivation.gentle_02');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(),
        localeCode: 'es',
      );

      expect(content.body, 'Lo importante hoy es no perder el hilo.');
      expect(content.resolvedVariables, isEmpty);
    });

    test('renders required streak and preserves template metadata', () async {
      final template = await loadTemplate('general.streak.encouragement_01');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(streak: 12),
        localeCode: 'en',
      );

      expect(content.templateId, 'general.streak.encouragement_01');
      expect(content.category, NotificationTemplateCategory.streak);
      expect(content.body, contains('12-day streak'));
    });

    test('renders progress and habitName together', () async {
      final template = await loadTemplate('general.progress.habit_01');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(
          habitName: 'Leer',
          progress: '3/5',
        ),
        localeCode: 'es',
      );

      expect(content.body, contains('Leer'));
      expect(content.body, contains('3/5'));
    });

    test('fails fast when a required variable is missing', () async {
      final template = await loadTemplate('general.progress.pending_01');

      expect(
        () => resolver.renderForLocale(
          template: template,
          context: NotificationRenderContext(),
          localeCode: 'en',
        ),
        throwsA(isA<NotificationTemplateRenderException>()),
      );
    });

    test('falls back to base locale when locale is unsupported', () async {
      final template = await loadTemplate('general.morning.gentle_01');

      final content = resolver.renderForLocale(
        template: template,
        context: NotificationRenderContext(),
        localeCode: 'fr',
      );

      expect(content.locale, 'es');
      expect(content.title, 'Rutio sigue aquí');
    });

    test('renders deterministically across repeated calls', () async {
      final template = await loadTemplate('general.consistency.name_01');
      final context = NotificationRenderContext(
        displayName: 'Sam',
        progress: '4/4',
      );

      final first = resolver.renderForLocale(
        template: template,
        context: context,
        localeCode: 'en',
      );
      final second = resolver.renderForLocale(
        template: template,
        context: context,
        localeCode: 'en',
      );

      expect(first, second);
    });

    test('renders every seed template in every supported locale', () async {
      final templates = await catalog.listAll();

      for (final template in templates) {
        final declared = template.declaredVariables.toSet();
        final context = NotificationRenderContext(
          displayName:
              declared.contains(NotificationTemplateVariable.displayName)
                  ? 'Nora'
                  : null,
          streak:
              declared.contains(NotificationTemplateVariable.streak) ? 5 : null,
          progress: declared.contains(NotificationTemplateVariable.progress)
              ? '2/3'
              : null,
          pendingCount:
              declared.contains(NotificationTemplateVariable.pendingCount)
                  ? 1
                  : null,
          completedCount: declared.contains(
            NotificationTemplateVariable.completedCount,
          )
              ? 2
              : null,
          totalCount: declared.contains(NotificationTemplateVariable.totalCount)
              ? 3
              : null,
          habitName: declared.contains(NotificationTemplateVariable.habitName)
              ? 'Caminar'
              : null,
          weekday: declared.contains(NotificationTemplateVariable.weekday)
              ? 'Friday'
              : null,
          timeOfDay: declared.contains(NotificationTemplateVariable.timeOfDay)
              ? '19:45'
              : null,
        );

        for (final locale
            in NotificationAppLocalizationsProvider.supportedLocaleCodes) {
          final content = resolver.renderForLocale(
            template: template,
            context: context,
            localeCode: locale,
          );

          expect(content.title, isNotEmpty, reason: template.templateId);
          expect(content.body, isNotEmpty, reason: template.templateId);
          expect(content.title, isNot(contains('{')),
              reason: template.templateId);
          expect(content.body, isNot(contains('{')),
              reason: template.templateId);
        }
      }
    });
  });
}
