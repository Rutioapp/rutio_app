import 'phrase_template_renderer.dart';
import 'motivational_phrase.dart';

class PhraseCatalogValidationException implements Exception {
  const PhraseCatalogValidationException(this.message);

  final String message;

  @override
  String toString() => 'PhraseCatalogValidationException: $message';
}

class PhraseCatalogValidator {
  const PhraseCatalogValidator({
    this.renderer = const PhraseTemplateRenderer(),
  });

  final PhraseTemplateRenderer renderer;

  void validateCatalog(PhraseCatalog catalog) {
    if (catalog.schemaVersion != 1) {
      throw PhraseCatalogValidationException(
        'Unsupported catalog schema version ${catalog.schemaVersion}.',
      );
    }
    if (catalog.catalogVersion.trim().isEmpty) {
      throw const PhraseCatalogValidationException(
        'Catalog version must not be empty.',
      );
    }
    if (catalog.locale.trim().isEmpty) {
      throw const PhraseCatalogValidationException(
        'Catalog locale must not be empty.',
      );
    }
    validatePhrases(catalog.phrases);
  }

  void validatePhrases(Iterable<MotivationalPhrase> phrases) {
    final seenIds = <String>{};
    for (final phrase in phrases) {
      if (phrase.id.trim().isEmpty) {
        throw const PhraseCatalogValidationException('Phrase ID is empty.');
      }
      if (!seenIds.add(phrase.id)) {
        throw PhraseCatalogValidationException(
          'Duplicate phrase ID "${phrase.id}".',
        );
      }
      if (phrase.weight <= 0 || !phrase.weight.isFinite) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" must have a positive finite weight.',
        );
      }
      if (phrase.template.trim().isEmpty || phrase.template.length > 500) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" has invalid content length.',
        );
      }
      final unknown = renderer.unknownTokens(phrase.template);
      if (unknown.isNotEmpty) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" has unknown token(s): ${unknown.join(', ')}.',
        );
      }
      final actualTokens = renderer.tokensIn(phrase.template);
      final requiredTokens = phrase.requiredTokens.toSet();
      if (requiredTokens.length != phrase.requiredTokens.length ||
          !requiredTokens.containsAll(actualTokens) ||
          !actualTokens.containsAll(requiredTokens)) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" has incoherent requiredTokens.',
        );
      }
      if ((phrase.sourceType == PhraseSourceType.quote ||
              phrase.sourceType == PhraseSourceType.proverb) &&
          (phrase.author == null || phrase.author!.trim().isEmpty)) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" requires an author.',
        );
      }
      if (phrase.contentVersion <= 0) {
        throw PhraseCatalogValidationException(
          'Phrase "${phrase.id}" must have a positive contentVersion.',
        );
      }
    }
  }
}
