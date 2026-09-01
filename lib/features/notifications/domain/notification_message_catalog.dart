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
      if (template.eligibility.maxStreak != null &&
          template.eligibility.maxStreak! < 0) {
        throw NotificationTemplateCatalogValidationError(
          'Template ${template.templateId} has invalid maxStreak.',
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
  'journalNudgeMilestone7Insight01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone7Insight01Title,
      body: l10n.pnJournalNudgeMilestone7Insight01Body,
    ),
  ),
  'journalNudgeMilestone7Change01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone7Change01Title,
      body: l10n.pnJournalNudgeMilestone7Change01Body,
    ),
  ),
  'journalNudgeMilestone7Ease01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone7Ease01Title,
      body: l10n.pnJournalNudgeMilestone7Ease01Body,
    ),
  ),
  'journalNudgeMilestone7Return01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone7Return01Title,
      body: l10n.pnJournalNudgeMilestone7Return01Body,
    ),
  ),
  'journalNudgeMilestone7Memory01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone7Memory01Title,
      body: l10n.pnJournalNudgeMilestone7Memory01Body,
    ),
  ),
  'journalNudgeMilestone14Insight01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone14Insight01Title,
      body: l10n.pnJournalNudgeMilestone14Insight01Body,
    ),
  ),
  'journalNudgeMilestone14Change01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone14Change01Title,
      body: l10n.pnJournalNudgeMilestone14Change01Body,
    ),
  ),
  'journalNudgeMilestone14Ease01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone14Ease01Title,
      body: l10n.pnJournalNudgeMilestone14Ease01Body,
    ),
  ),
  'journalNudgeMilestone14Return01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone14Return01Title,
      body: l10n.pnJournalNudgeMilestone14Return01Body,
    ),
  ),
  'journalNudgeMilestone14Memory01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone14Memory01Title,
      body: l10n.pnJournalNudgeMilestone14Memory01Body,
    ),
  ),
  'journalNudgeMilestone30Insight01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone30Insight01Title,
      body: l10n.pnJournalNudgeMilestone30Insight01Body,
    ),
  ),
  'journalNudgeMilestone30Change01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone30Change01Title,
      body: l10n.pnJournalNudgeMilestone30Change01Body,
    ),
  ),
  'journalNudgeMilestone30Ease01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone30Ease01Title,
      body: l10n.pnJournalNudgeMilestone30Ease01Body,
    ),
  ),
  'journalNudgeMilestone30Return01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone30Return01Title,
      body: l10n.pnJournalNudgeMilestone30Return01Body,
    ),
  ),
  'journalNudgeMilestone30Memory01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeMilestone30Memory01Title,
      body: l10n.pnJournalNudgeMilestone30Memory01Body,
    ),
  ),
  'journalNudgePerfectDayInsight01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayInsight01Title,
      body: l10n.pnJournalNudgePerfectDayInsight01Body,
    ),
  ),
  'journalNudgePerfectDayDifference01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayDifference01Title,
      body: l10n.pnJournalNudgePerfectDayDifference01Body,
    ),
  ),
  'journalNudgePerfectDayDecision01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayDecision01Title,
      body: l10n.pnJournalNudgePerfectDayDecision01Body,
    ),
  ),
  'journalNudgePerfectDayEnergy01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayEnergy01Title,
      body: l10n.pnJournalNudgePerfectDayEnergy01Body,
    ),
  ),
  'journalNudgePerfectDayEase01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayEase01Title,
      body: l10n.pnJournalNudgePerfectDayEase01Body,
    ),
  ),
  'journalNudgePerfectDayTomorrow01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayTomorrow01Title,
      body: l10n.pnJournalNudgePerfectDayTomorrow01Body,
    ),
  ),
  'journalNudgePerfectDayMoment01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayMoment01Title,
      body: l10n.pnJournalNudgePerfectDayMoment01Body,
    ),
  ),
  'journalNudgePerfectDayLearning01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayLearning01Title,
      body: l10n.pnJournalNudgePerfectDayLearning01Body,
    ),
  ),
  'journalNudgePerfectDayFeeling01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayFeeling01Title,
      body: l10n.pnJournalNudgePerfectDayFeeling01Body,
    ),
  ),
  'journalNudgePerfectDayMarker01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayMarker01Title,
      body: l10n.pnJournalNudgePerfectDayMarker01Body,
    ),
  ),
  'journalNudgePerfectDayMeaning01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayMeaning01Title,
      body: l10n.pnJournalNudgePerfectDayMeaning01Body,
    ),
  ),
  'journalNudgePerfectDayNote01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgePerfectDayNote01Title,
      body: l10n.pnJournalNudgePerfectDayNote01Body,
    ),
  ),
  'journalNudgeEndOfDayReflection01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayReflection01Title,
      body: l10n.pnJournalNudgeEndOfDayReflection01Body,
    ),
  ),
  'journalNudgeEndOfDayEnergy01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayEnergy01Title,
      body: l10n.pnJournalNudgeEndOfDayEnergy01Body,
    ),
  ),
  'journalNudgeEndOfDayDrain01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayDrain01Title,
      body: l10n.pnJournalNudgeEndOfDayDrain01Body,
    ),
  ),
  'journalNudgeEndOfDayMemory01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayMemory01Title,
      body: l10n.pnJournalNudgeEndOfDayMemory01Body,
    ),
  ),
  'journalNudgeEndOfDayDifference01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayDifference01Title,
      body: l10n.pnJournalNudgeEndOfDayDifference01Body,
    ),
  ),
  'journalNudgeEndOfDayLearning01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayLearning01Title,
      body: l10n.pnJournalNudgeEndOfDayLearning01Body,
    ),
  ),
  'journalNudgeEndOfDayDescribe01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayDescribe01Title,
      body: l10n.pnJournalNudgeEndOfDayDescribe01Body,
    ),
  ),
  'journalNudgeEndOfDayKeep01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayKeep01Title,
      body: l10n.pnJournalNudgeEndOfDayKeep01Body,
    ),
  ),
  'journalNudgeEndOfDaySurprise01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDaySurprise01Title,
      body: l10n.pnJournalNudgeEndOfDaySurprise01Body,
    ),
  ),
  'journalNudgeEndOfDayRelease01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayRelease01Title,
      body: l10n.pnJournalNudgeEndOfDayRelease01Body,
    ),
  ),
  'journalNudgeEndOfDayNotice01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayNotice01Title,
      body: l10n.pnJournalNudgeEndOfDayNotice01Body,
    ),
  ),
  'journalNudgeEndOfDayQuestion01': NotificationTemplateCopyDefinition(
    referencedVariables: const <NotificationTemplateVariable>{},
    render: (l10n, context) => NotificationRenderedTemplateCopy(
      title: l10n.pnJournalNudgeEndOfDayQuestion01Title,
      body: l10n.pnJournalNudgeEndOfDayQuestion01Body,
    ),
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
