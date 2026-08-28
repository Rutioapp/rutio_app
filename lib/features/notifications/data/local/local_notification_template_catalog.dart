import '../../../../core/assets/app_assets.dart';
import '../../../../data/local/asset_json_loader.dart';
import '../../domain/notification_message_catalog.dart';
import '../../domain/notification_template_content.dart';
import '../../domain/personalized_notification_models.dart';
import '../../domain/personalized_notification_ports.dart';

class LocalNotificationTemplateCatalog implements NotificationTemplateCatalog {
  LocalNotificationTemplateCatalog({
    required AssetJsonLoader assetJsonLoader,
    NotificationTemplateCatalogValidator? validator,
  })  : _assetJsonLoader = assetJsonLoader,
        _validator = validator ??
            NotificationTemplateCatalogValidator(
              copyResolver: NotificationLocalizedCopyResolver(),
            );

  final AssetJsonLoader _assetJsonLoader;
  final NotificationTemplateCatalogValidator _validator;

  List<NotificationTemplateDescriptor>? _cachedTemplates;

  @override
  Future<NotificationTemplateDescriptor?> getById(String templateId) async {
    final templates = await listAll();
    for (final template in templates) {
      if (template.templateId == templateId) {
        return template;
      }
    }
    return null;
  }

  @override
  Future<List<NotificationTemplateDescriptor>> listAll() async {
    if (_cachedTemplates != null) {
      return _cachedTemplates!;
    }

    final decoded = await _assetJsonLoader
        .loadJsonMap(AppAssets.notificationTemplateCatalog);
    final rawTemplates = decoded['templates'];
    if (rawTemplates is! List<Object?>) {
      throw NotificationTemplateCatalogValidationError(
        'Notification template catalog must contain a templates array.',
      );
    }

    final templates = rawTemplates
        .map((rawTemplate) => _decodeTemplate(rawTemplate))
        .toList(growable: false);
    _validator.validate(templates);
    _cachedTemplates = List<NotificationTemplateDescriptor>.unmodifiable(
      templates,
    );
    return _cachedTemplates!;
  }

  @override
  Future<List<NotificationTemplateDescriptor>> listByCategory(
    NotificationTemplateCategory category,
  ) async {
    final templates = await listAll();
    return templates
        .where((template) => template.category == category)
        .toList(growable: false);
  }

  @override
  Future<List<NotificationTemplateDescriptor>> listByKind(
    NotificationKind kind,
  ) async {
    final templates = await listAll();
    return templates
        .where((template) => template.supports(kind))
        .toList(growable: false);
  }

  NotificationTemplateDescriptor _decodeTemplate(Object? rawTemplate) {
    if (rawTemplate is! Map<String, Object?>) {
      throw NotificationTemplateCatalogValidationError(
        'Invalid template entry in notification catalog.',
      );
    }

    final templateId = _readString(rawTemplate, 'templateId');
    final templateKey = _readString(rawTemplate, 'templateKey');
    final localeNamespace = _readString(rawTemplate, 'localeNamespace');
    final category = notificationTemplateCategoryFromWireName(
      _readString(rawTemplate, 'category'),
    );
    final variantTags = _readStringList(rawTemplate, 'variantTags');
    final declaredVariables =
        _readVariableList(rawTemplate, 'declaredVariables');
    final requiredVariables =
        _readVariableList(rawTemplate, 'requiredVariables');
    final weight = _readInt(rawTemplate, 'weight');
    final cooldownHours = _readInt(rawTemplate, 'cooldownHours');
    final maxUsesPer7d = _readInt(rawTemplate, 'maxUsesPer7d');
    final compatibleKinds = _readKindList(rawTemplate, 'compatibleKinds');

    return NotificationTemplateDescriptor(
      templateId: templateId,
      templateKey: templateKey,
      localeNamespace: localeNamespace,
      category: category,
      variantTags: variantTags,
      declaredVariables: declaredVariables,
      requiredVariables: requiredVariables,
      weight: weight,
      cooldown: Duration(hours: cooldownHours),
      maxUsesPer7d: maxUsesPer7d,
      compatibleKinds: compatibleKinds,
    );
  }
}

String _readString(Map<String, Object?> raw, String key) {
  final value = raw[key];
  if (value is! String || value.trim().isEmpty) {
    throw NotificationTemplateCatalogValidationError(
      'Missing or invalid string field "$key".',
    );
  }
  return value.trim();
}

int _readInt(Map<String, Object?> raw, String key) {
  final value = raw[key];
  if (value is int) {
    return value;
  }
  throw NotificationTemplateCatalogValidationError(
    'Missing or invalid int field "$key".',
  );
}

List<String> _readStringList(Map<String, Object?> raw, String key) {
  final value = raw[key];
  if (value == null) return const <String>[];
  if (value is! List<Object?>) {
    throw NotificationTemplateCatalogValidationError(
      'Missing or invalid list field "$key".',
    );
  }
  return value.map((item) => _asString(item, key)).toList(growable: false);
}

List<NotificationTemplateVariable> _readVariableList(
  Map<String, Object?> raw,
  String key,
) {
  final values = _readStringList(raw, key);
  return values
      .map(notificationTemplateVariableFromWireName)
      .toList(growable: false);
}

List<NotificationKind> _readKindList(
  Map<String, Object?> raw,
  String key,
) {
  final values = _readStringList(raw, key);
  return values.map(notificationKindFromWireName).toList(growable: false);
}

String _asString(Object? value, String key) {
  if (value is! String || value.trim().isEmpty) {
    throw NotificationTemplateCatalogValidationError(
      'Invalid string entry in "$key".',
    );
  }
  return value.trim();
}
