import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/notifications/domain/personalized_notifications.dart';
import 'package:rutio/l10n/gen/app_localizations_en.dart';
import 'package:rutio/l10n/gen/app_localizations_es.dart';

void main() {
  final validator = NotificationTemplateCatalogValidator(
    copyResolver: NotificationLocalizedCopyResolver(),
  );

  NotificationTemplateDescriptor buildTemplate({
    String templateId = 'general.test.template_01',
    String templateKey = 'generalMorningGentle01',
    NotificationTemplateCategory category =
        NotificationTemplateCategory.morning,
    List<NotificationTemplateVariable> declaredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationTemplateVariable> requiredVariables =
        const <NotificationTemplateVariable>[],
    List<NotificationKind> compatibleKinds = const <NotificationKind>[
      NotificationKind.generalProgressNudge
    ],
  }) {
    return NotificationTemplateDescriptor(
      templateId: templateId,
      templateKey: templateKey,
      localeNamespace: 'personalizedNotifications',
      category: category,
      variantTags: const <String>['seed'],
      declaredVariables: declaredVariables,
      requiredVariables: requiredVariables,
      weight: 10,
      cooldown: const Duration(hours: 48),
      maxUsesPer7d: 2,
      compatibleKinds: compatibleKinds,
    );
  }

  group('NotificationTemplateCatalogValidator', () {
    test('accepts a valid template definition', () {
      expect(
        () => validator.validate(<NotificationTemplateDescriptor>[
          buildTemplate(),
        ]),
        returnsNormally,
      );
    });

    test('fails on duplicate template ids', () {
      final template = buildTemplate();

      expect(
        () => validator.validate(<NotificationTemplateDescriptor>[
          template,
          buildTemplate(templateKey: 'generalMotivationGentle01'),
        ]),
        throwsA(isA<NotificationTemplateCatalogValidationError>()),
      );
    });

    test('fails when copy uses variables not declared in metadata', () {
      final template = buildTemplate(
        templateId: 'general.test.pending_01',
        templateKey: 'generalPendingProgress01',
      );

      expect(
        () => validator.validate(<NotificationTemplateDescriptor>[template]),
        throwsA(isA<NotificationTemplateCatalogValidationError>()),
      );
    });

    test('fails when required variables are undeclared', () {
      final template = buildTemplate(
        requiredVariables: const <NotificationTemplateVariable>[
          NotificationTemplateVariable.displayName,
        ],
      );

      expect(
        () => validator.validate(<NotificationTemplateDescriptor>[template]),
        throwsA(isA<NotificationTemplateCatalogValidationError>()),
      );
    });

    test('fails when kinds cross different families', () {
      final template = buildTemplate(
        compatibleKinds: const <NotificationKind>[
          NotificationKind.generalProgressNudge,
          NotificationKind.celebrationStreak,
        ],
      );

      expect(
        () => validator.validate(<NotificationTemplateDescriptor>[template]),
        throwsA(isA<NotificationTemplateCatalogValidationError>()),
      );
    });

    test('fails when localized copy is empty', () {
      final resolver = NotificationLocalizedCopyResolver(
        templateDefinitions: <String, NotificationTemplateCopyDefinition>{
          'brokenTemplate': NotificationTemplateCopyDefinition(
            referencedVariables: const <NotificationTemplateVariable>{},
            render: (l10n, context) => const NotificationRenderedTemplateCopy(
              title: ' ',
              body: 'Valid body',
            ),
          ),
        },
      );
      final localValidator = NotificationTemplateCatalogValidator(
        copyResolver: resolver,
      );
      final template = buildTemplate(
        templateId: 'general.test.broken_01',
        templateKey: 'brokenTemplate',
      );

      expect(
        () =>
            localValidator.validate(<NotificationTemplateDescriptor>[template]),
        throwsA(isA<NotificationTemplateRenderException>()),
      );
    });

    test('fails when a locale is missing from the resolver definitions', () {
      final resolver = NotificationLocalizedCopyResolver(
        templateDefinitions: <String, NotificationTemplateCopyDefinition>{
          'missingLocaleTemplate': NotificationTemplateCopyDefinition(
            referencedVariables: const <NotificationTemplateVariable>{},
            render: (l10n, context) {
              if (l10n is AppLocalizationsEn) {
                return const NotificationRenderedTemplateCopy(
                  title: 'Hello',
                  body: 'World',
                );
              }
              if (l10n is AppLocalizationsEs) {
                return const NotificationRenderedTemplateCopy(
                  title: 'Hola',
                  body: '{displayName}',
                );
              }
              return const NotificationRenderedTemplateCopy(
                title: 'Fallback',
                body: 'Fallback',
              );
            },
          ),
        },
      );
      final localValidator = NotificationTemplateCatalogValidator(
        copyResolver: resolver,
      );
      final template = buildTemplate(
        templateId: 'general.test.locale_01',
        templateKey: 'missingLocaleTemplate',
      );

      expect(
        () =>
            localValidator.validate(<NotificationTemplateDescriptor>[template]),
        throwsA(isA<NotificationTemplateRenderException>()),
      );
    });
  });
}
