class PhraseCatalogLocaleResolver {
  const PhraseCatalogLocaleResolver();

  static String normalize(String locale) {
    final raw = locale.trim().replaceAll('_', '-');
    if (raw.isEmpty) return 'es-ES';
    final parts = raw.split('-').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'es-ES';
    final language = parts.first.toLowerCase();
    final normalized = <String>[language];
    for (var index = 1; index < parts.length; index++) {
      final part = parts[index];
      if (part.length == 4) {
        normalized.add(
          '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        );
      } else if (part.length == 2 || part.length == 3) {
        normalized.add(part.toUpperCase());
      } else {
        normalized.add(part.toLowerCase());
      }
    }
    return normalized.join('-');
  }

  static String preferredAppMarket(String locale) {
    final normalized = normalize(locale);
    final language = baseLanguage(normalized);
    if (language == 'es') return 'es-ES';
    if (language == 'en') return 'en-US';
    return normalized;
  }

  static String baseLanguage(String locale) =>
      normalize(locale).split('-').first;

  /// Ordered exact/effective candidates. No candidate is repeated.
  static List<String> candidates(String locale) {
    final normalized = normalize(locale);
    final preferred = preferredAppMarket(normalized);
    final base = baseLanguage(normalized);
    final values = <String>[];
    final ordered = normalized == base
        ? <String>[preferred, base]
        : <String>[normalized, preferred, base];
    for (final value in ordered) {
      if (!values.contains(value)) values.add(value);
    }
    return List<String>.unmodifiable(values);
  }

  /// The identity used by daily selection and history isolation.
  static String selectionLocale(String locale) => preferredAppMarket(locale);
}
