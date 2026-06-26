import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/widgets/emoji_picker/habit_emoji_catalog.dart';
import 'package:rutio/widgets/emoji_picker/habit_emoji_search.dart';

void main() {
  group('resolveEmojiPickerOptions', () {
    test('finds useful emojis by spanish keyword', () {
      final results = resolveEmojiPickerOptions(
        query: 'leer',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(results.map((option) => option.emoji), contains('📚'));
    });

    test('is case insensitive and accent tolerant', () {
      final upper = resolveEmojiPickerOptions(
        query: 'CAFÉ',
        selectedCategory: HabitEmojiCategories.foodDrink,
      );
      final plain = resolveEmojiPickerOptions(
        query: 'cafe',
        selectedCategory: HabitEmojiCategories.foodDrink,
      );

      expect(upper.first.emoji, '☕');
      expect(plain.first.emoji, '☕');
    });

    test('returns category options for empty query', () {
      final results = resolveEmojiPickerOptions(
        query: '   ',
        selectedCategory: HabitEmojiCategories.workStudy,
      );

      expect(results, isNotEmpty);
      expect(results.every((option) => option.category == HabitEmojiCategories.workStudy), isTrue);
    });

    test('returns empty list when there are no matches', () {
      final results = resolveEmojiPickerOptions(
        query: 'ornitorrinco',
        selectedCategory: HabitEmojiCategories.creativity,
      );

      expect(results, isEmpty);
    });

    test('uses recent selections when recent category is active', () {
      final results = resolveEmojiPickerOptions(
        query: '',
        selectedCategory: HabitEmojiCategories.recent,
        recentEmojis: const <String>['🧘', '💧'],
      );

      expect(results.map((option) => option.emoji).toList(), <String>['🧘', '💧']);
    });

    test('searching from recent category falls back to full matches', () {
      final results = resolveEmojiPickerOptions(
        query: 'meditar',
        selectedCategory: HabitEmojiCategories.recent,
        recentEmojis: const <String>['💧'],
      );

      expect(results.map((option) => option.emoji), contains('🧘'));
    });
  });
}
