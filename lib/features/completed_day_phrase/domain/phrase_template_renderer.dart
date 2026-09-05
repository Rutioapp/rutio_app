import 'motivational_phrase.dart';

class PhraseTemplateRenderException implements Exception {
  const PhraseTemplateRenderException(this.message);

  final String message;

  @override
  String toString() => 'PhraseTemplateRenderException: $message';
}

class PhraseTemplateRenderer {
  const PhraseTemplateRenderer();

  static const Set<String> allowedTokens = <String>{
    'name',
    'streak_label',
    'progress',
  };

  static final RegExp _tokenPattern = RegExp(r'\{([^{}]+)\}');

  Set<String> tokensIn(String template) {
    return _tokenPattern
        .allMatches(template)
        .map((match) => match.group(1)!.trim())
        .toSet();
  }

  Set<String> unknownTokens(String template) {
    return tokensIn(template).difference(allowedTokens);
  }

  bool canRender(MotivationalPhrase phrase, PhraseContext context) {
    if (unknownTokens(phrase.template).isNotEmpty) return false;
    final tokens = tokensIn(phrase.template);
    if (!tokens.containsAll(phrase.requiredTokens.toSet())) return false;
    if (tokens.contains('name') && context.normalizedName == null) return false;
    if (tokens.contains('streak_label') &&
        (context.streakLabel == null || context.streakLabel!.trim().isEmpty)) {
      return false;
    }
    if (tokens.contains('progress') && context.progressLabel.trim().isEmpty) {
      return false;
    }
    return true;
  }

  String render(MotivationalPhrase phrase, PhraseContext context) {
    final unknown = unknownTokens(phrase.template);
    if (unknown.isNotEmpty) {
      throw PhraseTemplateRenderException(
        'Unknown token(s): ${unknown.join(', ')}.',
      );
    }
    if (!canRender(phrase, context)) {
      throw const PhraseTemplateRenderException(
        'Phrase has tokens that cannot be resolved by the supplied context.',
      );
    }

    final values = <String, String>{
      'name': context.normalizedName ?? '',
      'streak_label': context.streakLabel?.trim() ?? '',
      'progress': context.progressLabel.trim(),
    };
    return phrase.template.replaceAllMapped(_tokenPattern, (match) {
      final token = match.group(1)!.trim();
      return values[token]!;
    });
  }
}
