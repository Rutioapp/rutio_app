import '../../../l10n/gen/app_localizations.dart';
import '../../../l10n/gen/app_localizations_en.dart';
import '../../../l10n/gen/app_localizations_es.dart';
import 'notification_template_content.dart';
import 'personalized_notification_models.dart';
import 'personalized_notification_ports.dart';

class NotificationTemplateCatalogValidationError extends StateError {
  NotificationTemplateCatalogValidationError(super.message);
}

class NotificationTemplateRenderException extends StateError {
  NotificationTemplateRenderException(super.message);
}

class NotificationAppLocalizationsProvider {
  const NotificationAppLocalizationsProvider();

  static const String fallbackLocale = 'es';
  static const List<String> supportedLocaleCodes = <String>['es', 'en'];

  AppLocalizations resolve(String localeCode) {
    final normalized = localeCode.trim().toLowerCase();
    if (normalized.startsWith('en')) {
      return AppLocalizationsEn();
    }
    if (normalized.startsWith('es')) {
      return AppLocalizationsEs();
    }
    return AppLocalizationsEs();
  }

  String canonicalize(String localeCode) {
    final normalized = localeCode.trim().toLowerCase();
    if (normalized.startsWith('en')) return 'en';
    if (normalized.startsWith('es')) return 'es';
    return fallbackLocale;
  }
}

class NotificationLocalizedCopyResolver {
  NotificationLocalizedCopyResolver({
    this.localizationsProvider = const NotificationAppLocalizationsProvider(),
    Map<String, NotificationTemplateCopyDefinition>? templateDefinitions,
  }) : _templateDefinitions = templateDefinitions ?? defaultTemplateDefinitions;

  final NotificationAppLocalizationsProvider localizationsProvider;
  final Map<String, NotificationTemplateCopyDefinition> _templateDefinitions;

  static final Map<String, NotificationTemplateCopyDefinition>
      defaultTemplateDefinitions = _defaultTemplateDefinitions;

  bool supportsTemplateKey(String templateKey) =>
      _templateDefinitions.containsKey(templateKey);

  Set<NotificationTemplateVariable> referencedVariablesFor(String templateKey) {
    final definition = _templateDefinitions[templateKey];
    if (definition == null) {
      throw NotificationTemplateRenderException(
        'Unknown notification templateKey: $templateKey',
      );
    }
    return definition.referencedVariables;
  }

  RenderedNotificationContent renderForLocale({
    required NotificationTemplateDescriptor template,
    required NotificationRenderContext context,
    required String localeCode,
  }) {
    final locale = localizationsProvider.canonicalize(localeCode);
    return render(
      template: template,
      context: context,
      localizations: localizationsProvider.resolve(localeCode),
      localeOverride: locale,
    );
  }

  RenderedNotificationContent render({
    required NotificationTemplateDescriptor template,
    required NotificationRenderContext context,
    required AppLocalizations localizations,
    String? localeOverride,
  }) {
    final definition = _templateDefinitions[template.templateKey];
    if (definition == null) {
      throw NotificationTemplateRenderException(
        'Unknown notification templateKey: ${template.templateKey}',
      );
    }

    final missingVariables =
        context.missingRequired(template.requiredVariables);
    if (missingVariables.isNotEmpty) {
      throw NotificationTemplateRenderException(
        'Missing required variables for ${template.templateId}: '
        '${missingVariables.map((value) => value.wireName).join(', ')}',
      );
    }

    final result = definition.render(localizations, context);
    _ensureResolvedText(template.templateId, 'title', result.title);
    _ensureResolvedText(template.templateId, 'body', result.body);

    return RenderedNotificationContent(
      templateId: template.templateId,
      templateKey: template.templateKey,
      locale: localeOverride ??
          localizationsProvider.canonicalize(localizations.localeName),
      category: template.category,
      title: result.title,
      body: result.body,
      resolvedVariables: result.resolvedVariables,
    );
  }

  void _ensureResolvedText(
    String templateId,
    String field,
    String value,
  ) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw NotificationTemplateRenderException(
        'Empty $field for $templateId',
      );
    }
    if (_placeholderPattern.hasMatch(normalized)) {
      throw NotificationTemplateRenderException(
        'Unresolved placeholder in $field for $templateId: $normalized',
      );
    }
  }
}

class NotificationTemplateCatalogValidator {
  NotificationTemplateCatalogValidator({
    required this.copyResolver,
    this.localizationsProvider = const NotificationAppLocalizationsProvider(),
  });

  final NotificationLocalizedCopyResolver copyResolver;
  final NotificationAppLocalizationsProvider localizationsProvider;

  void validate(Iterable<NotificationTemplateDescriptor> templates) {
    final allTemplates = templates.toList(growable: false);
    final ids = <String>{};

    for (final template in allTemplates) {
      if (!ids.add(template.templateId)) {
        throw NotificationTemplateCatalogValidationError(
          'Duplicate templateId detected: ${template.templateId}',
        );
      }
      if (template.templateId.trim().isEmpty ||
          template.templateKey.trim().isEmpty ||
          template.localeNamespace.trim().isEmpty) {
        throw NotificationTemplateCatalogValidationError(
          'Template identity fields cannot be empty: ${template.templateId}',
        );
      }
      if (template.compatibleKinds.isEmpty) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} must declare compatible kinds.',
        );
      }
      final expectedFamily = template.compatibleKinds.first.family;
      if (template.compatibleKinds
          .any((kind) => kind.family != expectedFamily)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} mixes incompatible families.',
        );
      }
      if (template.weight <= 0) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} must have positive weight.',
        );
      }
      if (template.eligibility.minProgressRatio != null &&
          (template.eligibility.minProgressRatio! < 0 ||
              template.eligibility.minProgressRatio! > 1)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} has invalid minProgressRatio.',
        );
      }
      if (template.eligibility.maxProgressRatio != null &&
          (template.eligibility.maxProgressRatio! < 0 ||
              template.eligibility.maxProgressRatio! > 1)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} has invalid maxProgressRatio.',
        );
      }
      if (template.eligibility.minProgressRatio != null &&
          template.eligibility.maxProgressRatio != null &&
          template.eligibility.minProgressRatio! >
              template.eligibility.maxProgressRatio!) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} has inverted progress ratio limits.',
        );
      }
      if (template.cooldown.isNegative) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} cannot have negative cooldown.',
        );
      }
      if (template.maxUsesPer7d <= 0) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} must have maxUsesPer7d > 0.',
        );
      }
      if (template.variantTags.any((tag) => tag.trim().isEmpty)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} contains an empty variant tag.',
        );
      }

      final declared = template.declaredVariables.toSet();
      if (declared.length != template.declaredVariables.length) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} contains duplicate declared variables.',
        );
      }
      final required = template.requiredVariables.toSet();
      if (required.length != template.requiredVariables.length) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} contains duplicate required variables.',
        );
      }
      if (!required.every(declared.contains)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires undeclared variables.',
        );
      }
      if (!copyResolver.supportsTemplateKey(template.templateKey)) {
        throw NotificationTemplateCatalogValidationError(
          'No localized copy resolver found for ${template.templateKey}.',
        );
      }

      final referenced =
          copyResolver.referencedVariablesFor(template.templateKey).toSet();
      if (!referenced.every(declared.contains)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} uses variables not declared in metadata.',
        );
      }
      if (!required.every(referenced.contains)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires variables not used by copy.',
        );
      }
      if (template.eligibility.requiresDisplayName &&
          !declared.contains(NotificationTemplateVariable.displayName)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires displayName but does not declare it.',
        );
      }
      if ((template.eligibility.requiresStreak ||
              template.eligibility.minStreak != null) &&
          !declared.contains(NotificationTemplateVariable.streak)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires streak but does not declare it.',
        );
      }
      if ((template.eligibility.minPendingCount != null ||
              template.eligibility.maxPendingCount != null) &&
          !declared.contains(NotificationTemplateVariable.pendingCount)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires pendingCount but does not declare it.',
        );
      }
      if (template.eligibility.minCompletedCount != null &&
          !declared.contains(NotificationTemplateVariable.completedCount)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires completedCount but does not declare it.',
        );
      }
      if (template.eligibility.minTotalCount != null &&
          !declared.contains(NotificationTemplateVariable.totalCount)) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} requires totalCount but does not declare it.',
        );
      }

      final sampleContext = _sampleContextFor(template);
      for (final locale
          in NotificationAppLocalizationsProvider.supportedLocaleCodes) {
        copyResolver.renderForLocale(
          template: template,
          context: sampleContext,
          localeCode: locale,
        );
      }
    }
  }

  NotificationRenderContext _sampleContextFor(
    NotificationTemplateDescriptor template,
  ) {
    final declared = template.declaredVariables.toSet();
    return NotificationRenderContext(
      displayName: declared.contains(NotificationTemplateVariable.displayName)
          ? 'Alex'
          : null,
      streak: declared.contains(NotificationTemplateVariable.streak) ? 7 : null,
      progress: declared.contains(NotificationTemplateVariable.progress)
          ? '3/5'
          : null,
      pendingCount: declared.contains(NotificationTemplateVariable.pendingCount)
          ? 2
          : null,
      completedCount: declared.contains(
        NotificationTemplateVariable.completedCount,
      )
          ? 4
          : null,
      totalCount:
          declared.contains(NotificationTemplateVariable.totalCount) ? 5 : null,
      habitName: declared.contains(NotificationTemplateVariable.habitName)
          ? 'Respirar'
          : null,
      weekday: declared.contains(NotificationTemplateVariable.weekday)
          ? 'viernes'
          : null,
      timeOfDay: declared.contains(NotificationTemplateVariable.timeOfDay)
          ? '20:30'
          : null,
    );
  }
}

class InMemoryNotificationTemplateCatalog
    implements NotificationTemplateCatalog {
  InMemoryNotificationTemplateCatalog({
    required Iterable<NotificationTemplateDescriptor> templates,
    NotificationTemplateCatalogValidator? validator,
  }) : _templates =
            List<NotificationTemplateDescriptor>.unmodifiable(templates) {
    validator?.validate(_templates);
  }

  final List<NotificationTemplateDescriptor> _templates;

  @override
  Future<NotificationTemplateDescriptor?> getById(String templateId) async {
    for (final template in _templates) {
      if (template.templateId == templateId) {
        return template;
      }
    }
    return null;
  }

  @override
  Future<List<NotificationTemplateDescriptor>> listAll() async => _templates;

  @override
  Future<List<NotificationTemplateDescriptor>> listByCategory(
    NotificationTemplateCategory category,
  ) async {
    return _templates
        .where((template) => template.category == category)
        .toList(growable: false);
  }

  @override
  Future<List<NotificationTemplateDescriptor>> listByKind(
    NotificationKind kind,
  ) async {
    return _templates
        .where((template) => template.supports(kind))
        .toList(growable: false);
  }
}

class NotificationRenderedTemplateCopy {
  const NotificationRenderedTemplateCopy({
    required this.title,
    required this.body,
    this.resolvedVariables = const <NotificationTemplateVariable, String>{},
  });

  final String title;
  final String body;
  final Map<NotificationTemplateVariable, String> resolvedVariables;
}

class NotificationTemplateCopyDefinition {
  const NotificationTemplateCopyDefinition({
    required this.referencedVariables,
    required this.render,
  });

  final Set<NotificationTemplateVariable> referencedVariables;
  final NotificationRenderedTemplateCopy Function(
    AppLocalizations localizations,
    NotificationRenderContext context,
  ) render;
}

final RegExp _placeholderPattern = RegExp(r'\{[A-Za-z0-9_]+\}');

final Map<String, NotificationTemplateCopyDefinition>
    _defaultTemplateDefinitions = <String, NotificationTemplateCopyDefinition>{
  'generalMorningGentle01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnGeneralMorningGentle01Title,
      body: l10n.pnGeneralMorningGentle01Body,
    ),
  ),
  'generalMorningGentle02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
    },
    render: (l10n, context) {
      final displayName = context.stringValue(
        NotificationTemplateVariable.displayName,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralMorningGentle02Title,
        body: displayName == null
            ? l10n.pnGeneralMorningGentle02Body
            : l10n.pnGeneralMorningGentle02BodyWithName(displayName),
        resolvedVariables: displayName == null
            ? const <NotificationTemplateVariable, String>{}
            : <NotificationTemplateVariable, String>{
                NotificationTemplateVariable.displayName: displayName,
              },
      );
    },
  ),
  'generalMorningFocus01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.weekday,
    },
    render: (l10n, context) {
      final weekday =
          context.stringValue(NotificationTemplateVariable.weekday) ?? 'today';
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralMorningFocus01Title,
        body: l10n.pnGeneralMorningFocus01Body(weekday),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.weekday: weekday,
        },
      );
    },
  ),
  'generalMotivationGentle01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnGeneralMotivationGentle01Title,
      body: l10n.pnGeneralMotivationGentle01Body,
    ),
  ),
  'generalMotivationGentle02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
    },
    render: (l10n, context) {
      final displayName = context.stringValue(
        NotificationTemplateVariable.displayName,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralMotivationGentle02Title,
        body: displayName == null
            ? l10n.pnGeneralMotivationGentle02Body
            : l10n.pnGeneralMotivationGentle02BodyWithName(displayName),
        resolvedVariables: displayName == null
            ? const <NotificationTemplateVariable, String>{}
            : <NotificationTemplateVariable, String>{
                NotificationTemplateVariable.displayName: displayName,
              },
      );
    },
  ),
  'generalPendingProgress01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.pendingCount,
    },
    render: (l10n, context) {
      final pendingCount = _requireInt(
        context,
        NotificationTemplateVariable.pendingCount,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralPendingProgress01Title,
        body: l10n.pnGeneralPendingProgress01Body(pendingCount),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.pendingCount: pendingCount.toString(),
        },
      );
    },
  ),
  'generalPendingProgress02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.pendingCount,
      NotificationTemplateVariable.totalCount,
    },
    render: (l10n, context) {
      final pendingCount = _requireInt(
        context,
        NotificationTemplateVariable.pendingCount,
      );
      final totalCount = _requireInt(
        context,
        NotificationTemplateVariable.totalCount,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralPendingProgress02Title,
        body: l10n.pnGeneralPendingProgress02Body(pendingCount, totalCount),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.pendingCount: pendingCount.toString(),
          NotificationTemplateVariable.totalCount: totalCount.toString(),
        },
      );
    },
  ),
  'generalPendingProgress03': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.progress,
    },
    render: (l10n, context) {
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralPendingProgress03Title,
        body: l10n.pnGeneralPendingProgress03Body(progress),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.progress: progress,
        },
      );
    },
  ),
  'generalStrongProgress01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.progress,
    },
    render: (l10n, context) {
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralStrongProgress01Title,
        body: l10n.pnGeneralStrongProgress01Body(progress),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.progress: progress,
        },
      );
    },
  ),
  'generalStrongProgress02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.completedCount,
      NotificationTemplateVariable.totalCount,
    },
    render: (l10n, context) {
      final completedCount = _requireInt(
        context,
        NotificationTemplateVariable.completedCount,
      );
      final totalCount = _requireInt(
        context,
        NotificationTemplateVariable.totalCount,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralStrongProgress02Title,
        body: l10n.pnGeneralStrongProgress02Body(completedCount, totalCount),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.completedCount:
              completedCount.toString(),
          NotificationTemplateVariable.totalCount: totalCount.toString(),
        },
      );
    },
  ),
  'generalCompletedDay01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.completedCount,
    },
    render: (l10n, context) {
      final completedCount = _requireInt(
        context,
        NotificationTemplateVariable.completedCount,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralCompletedDay01Title,
        body: l10n.pnGeneralCompletedDay01Body(completedCount),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.completedCount:
              completedCount.toString(),
        },
      );
    },
  ),
  'generalCompletedDay02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.progress,
      NotificationTemplateVariable.timeOfDay,
    },
    render: (l10n, context) {
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      final timeOfDay = _requireString(
        context,
        NotificationTemplateVariable.timeOfDay,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralCompletedDay02Title,
        body: l10n.pnGeneralCompletedDay02Body(progress, timeOfDay),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.progress: progress,
          NotificationTemplateVariable.timeOfDay: timeOfDay,
        },
      );
    },
  ),
  'generalStreakEncouragement01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.streak,
    },
    render: (l10n, context) {
      final streak = _requireInt(context, NotificationTemplateVariable.streak);
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralStreakEncouragement01Title,
        body: l10n.pnGeneralStreakEncouragement01Body(streak),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.streak: streak.toString(),
        },
      );
    },
  ),
  'generalStreakEncouragement02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
      NotificationTemplateVariable.streak,
    },
    render: (l10n, context) {
      final displayName = _requireString(
        context,
        NotificationTemplateVariable.displayName,
      );
      final streak = _requireInt(context, NotificationTemplateVariable.streak);
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralStreakEncouragement02Title,
        body: l10n.pnGeneralStreakEncouragement02Body(displayName, streak),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.displayName: displayName,
          NotificationTemplateVariable.streak: streak.toString(),
        },
      );
    },
  ),
  'generalComebackGentle01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnGeneralComebackGentle01Title,
      body: l10n.pnGeneralComebackGentle01Body,
    ),
  ),
  'generalComebackGentle02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
    },
    render: (l10n, context) {
      final displayName = context.stringValue(
        NotificationTemplateVariable.displayName,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralComebackGentle02Title,
        body: displayName == null
            ? l10n.pnGeneralComebackGentle02Body
            : l10n.pnGeneralComebackGentle02BodyWithName(displayName),
        resolvedVariables: displayName == null
            ? const <NotificationTemplateVariable, String>{}
            : <NotificationTemplateVariable, String>{
                NotificationTemplateVariable.displayName: displayName,
              },
      );
    },
  ),
  'generalReflectionPrompt01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnGeneralReflectionPrompt01Title,
      body: l10n.pnGeneralReflectionPrompt01Body,
    ),
  ),
  'generalReflectionPrompt02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
    },
    render: (l10n, context) {
      final displayName = context.stringValue(
        NotificationTemplateVariable.displayName,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralReflectionPrompt02Title,
        body: displayName == null
            ? l10n.pnGeneralReflectionPrompt02Body
            : l10n.pnGeneralReflectionPrompt02BodyWithName(displayName),
        resolvedVariables: displayName == null
            ? const <NotificationTemplateVariable, String>{}
            : <NotificationTemplateVariable, String>{
                NotificationTemplateVariable.displayName: displayName,
              },
      );
    },
  ),
  'generalConsistencyGentle01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.streak,
    },
    render: (l10n, context) {
      final streak = _requireInt(context, NotificationTemplateVariable.streak);
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralConsistencyGentle01Title,
        body: l10n.pnGeneralConsistencyGentle01Body(streak),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.streak: streak.toString(),
        },
      );
    },
  ),
  'generalConsistencyGentle02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.progress,
    },
    render: (l10n, context) {
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralConsistencyGentle02Title,
        body: l10n.pnGeneralConsistencyGentle02Body(progress),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.progress: progress,
        },
      );
    },
  ),
  'generalEncouragementNeutral01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnGeneralEncouragementNeutral01Title,
      body: l10n.pnGeneralEncouragementNeutral01Body,
    ),
  ),
  'generalEncouragementNeutral02': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
    },
    render: (l10n, context) {
      final displayName = context.stringValue(
        NotificationTemplateVariable.displayName,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralEncouragementNeutral02Title,
        body: displayName == null
            ? l10n.pnGeneralEncouragementNeutral02Body
            : l10n.pnGeneralEncouragementNeutral02BodyWithName(displayName),
        resolvedVariables: displayName == null
            ? const <NotificationTemplateVariable, String>{}
            : <NotificationTemplateVariable, String>{
                NotificationTemplateVariable.displayName: displayName,
              },
      );
    },
  ),
  'generalProgressHabit01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.habitName,
      NotificationTemplateVariable.progress,
    },
    render: (l10n, context) {
      final habitName = _requireString(
        context,
        NotificationTemplateVariable.habitName,
      );
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralProgressHabit01Title,
        body: l10n.pnGeneralProgressHabit01Body(habitName, progress),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.habitName: habitName,
          NotificationTemplateVariable.progress: progress,
        },
      );
    },
  ),
  'generalEncouragementWeekday01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.weekday,
      NotificationTemplateVariable.timeOfDay,
    },
    render: (l10n, context) {
      final weekday = _requireString(
        context,
        NotificationTemplateVariable.weekday,
      );
      final timeOfDay = _requireString(
        context,
        NotificationTemplateVariable.timeOfDay,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralEncouragementWeekday01Title,
        body: l10n.pnGeneralEncouragementWeekday01Body(weekday, timeOfDay),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.weekday: weekday,
          NotificationTemplateVariable.timeOfDay: timeOfDay,
        },
      );
    },
  ),
  'generalReflectionProgress01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.completedCount,
      NotificationTemplateVariable.totalCount,
    },
    render: (l10n, context) {
      final completedCount = _requireInt(
        context,
        NotificationTemplateVariable.completedCount,
      );
      final totalCount = _requireInt(
        context,
        NotificationTemplateVariable.totalCount,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralReflectionProgress01Title,
        body: l10n.pnGeneralReflectionProgress01Body(
          completedCount,
          totalCount,
        ),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.completedCount:
              completedCount.toString(),
          NotificationTemplateVariable.totalCount: totalCount.toString(),
        },
      );
    },
  ),
  'generalConsistencyName01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{
      NotificationTemplateVariable.displayName,
      NotificationTemplateVariable.progress,
    },
    render: (l10n, context) {
      final displayName = _requireString(
        context,
        NotificationTemplateVariable.displayName,
      );
      final progress = _requireString(
        context,
        NotificationTemplateVariable.progress,
      );
      return NotificationRenderedTemplateCopy(
        title: l10n.pnGeneralConsistencyName01Title,
        body: l10n.pnGeneralConsistencyName01Body(displayName, progress),
        resolvedVariables: <NotificationTemplateVariable, String>{
          NotificationTemplateVariable.displayName: displayName,
          NotificationTemplateVariable.progress: progress,
        },
      );
    },
  ),
};

String _requireString(
  NotificationRenderContext context,
  NotificationTemplateVariable variable,
) {
  final value = context.stringValue(variable);
  if (value == null) {
    throw NotificationTemplateRenderException(
      'Missing string variable: ${variable.wireName}',
    );
  }
  return value;
}

int _requireInt(
  NotificationRenderContext context,
  NotificationTemplateVariable variable,
) {
  final value = context.intValue(variable);
  if (value == null) {
    throw NotificationTemplateRenderException(
      'Missing int variable: ${variable.wireName}',
    );
  }
  return value;
}
