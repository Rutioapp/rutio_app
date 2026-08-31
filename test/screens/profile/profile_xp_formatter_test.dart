import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/profile/utils/profile_xp.dart';

void main() {
  test('formatCompactXp keeps small values untouched', () {
    expect(formatCompactXp(950, localeName: 'en'), '950');
  });

  test('formatCompactXp trims integer suffix values', () {
    expect(formatCompactXp(1000, localeName: 'en'), '1k');
  });

  test('formatCompactXp keeps one decimal at thousand scale', () {
    expect(formatCompactXp(1500, localeName: 'en'), '1.5k');
  });

  test('formatCompactXp respects locale decimal separators', () {
    expect(formatCompactXp(1500, localeName: 'es'), '1,5k');
  });

  test('formatCompactXp scales to tens of thousands and millions', () {
    expect(formatCompactXp(12400, localeName: 'en'), '12.4k');
    expect(formatCompactXp(1200000, localeName: 'en'), '1.2M');
  });
}
