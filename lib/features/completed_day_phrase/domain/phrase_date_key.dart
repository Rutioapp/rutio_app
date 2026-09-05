class PhraseDateKey {
  const PhraseDateKey._();

  static String format(DateTime localDate) {
    final year = localDate.year.toString().padLeft(4, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final day = localDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static DateTime parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) throw const FormatException('Invalid local date key.');
    final date = DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (format(date) != value) {
      throw const FormatException('Invalid local date key.');
    }
    return date;
  }
}

class PhraseLocale {
  const PhraseLocale._();

  static String canonicalize(String locale) {
    final normalized = locale.trim().toLowerCase().replaceAll('_', '-');
    if (normalized == 'en' || normalized.startsWith('en-')) return 'en';
    return 'es';
  }
}
