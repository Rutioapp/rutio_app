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

      expect(
        results.map((option) => option.emoji),
        anyElement(isIn(<String>['📖', '📚'])),
      );
    });

    test('is case insensitive and accent tolerant', () {
      final upper = resolveEmojiPickerOptions(
        query: 'CAFÉ',
        selectedCategory: HabitEmojiCategories.food,
      );
      final plain = resolveEmojiPickerOptions(
        query: 'cafe',
        selectedCategory: HabitEmojiCategories.food,
      );

      expect(upper.first.emoji, '☕');
      expect(plain.first.emoji, '☕');
    });

    test('returns category options for empty query', () {
      final results = resolveEmojiPickerOptions(
        query: '   ',
        selectedCategory: HabitEmojiCategories.work,
      );

      expect(results, isNotEmpty);
      expect(
        results.every((option) => option.category == HabitEmojiCategories.work),
        isTrue,
      );
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

    test('cafe and café find coffee emoji', () {
      final accent = resolveEmojiPickerOptions(
        query: 'café',
        selectedCategory: HabitEmojiCategories.food,
      );
      final plain = resolveEmojiPickerOptions(
        query: 'cafe',
        selectedCategory: HabitEmojiCategories.food,
      );

      expect(accent.map((option) => option.emoji), contains('☕'));
      expect(plain.map((option) => option.emoji), contains('☕'));
    });

    test('musica finds music emoji', () {
      final results = resolveEmojiPickerOptions(
        query: 'música',
        selectedCategory: HabitEmojiCategories.creativity,
      );

      expect(
        results.map((option) => option.emoji),
        anyElement(isIn(<String>['🎵', '🎧'])),
      );
    });

    test('dinero and ahorrar find finance emoji', () {
      final money = resolveEmojiPickerOptions(
        query: 'dinero',
        selectedCategory: HabitEmojiCategories.finance,
      );
      final save = resolveEmojiPickerOptions(
        query: 'ahorrar',
        selectedCategory: HabitEmojiCategories.finance,
      );

      expect(money.map((option) => option.emoji), contains('💰'));
      expect(save.map((option) => option.emoji), contains('💰'));
    });

    test('limpiar finds broom emoji', () {
      final results = resolveEmojiPickerOptions(
        query: 'limpiar',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(results.map((option) => option.emoji), contains('🧹'));
    });

    test('gym and workout find weightlifting emoji', () {
      final gym = resolveEmojiPickerOptions(
        query: 'gym',
        selectedCategory: HabitEmojiCategories.sport,
      );
      final workout = resolveEmojiPickerOptions(
        query: 'workout',
        selectedCategory: HabitEmojiCategories.sport,
      );

      expect(gym.map((option) => option.emoji), contains('🏋️'));
      expect(workout.map((option) => option.emoji), contains('🏋️'));
    });

    test('journal and diario find journaling emoji', () {
      final journal = resolveEmojiPickerOptions(
        query: 'journal',
        selectedCategory: HabitEmojiCategories.creativity,
      );
      final diario = resolveEmojiPickerOptions(
        query: 'diario',
        selectedCategory: HabitEmojiCategories.creativity,
      );

      expect(
        journal.map((option) => option.emoji),
        anyElement(isIn(<String>['📝', '📓'])),
      );
      expect(
        diario.map((option) => option.emoji),
        anyElement(isIn(<String>['📝', '📓'])),
      );
    });

    test('agua devuelve gota', () {
      final results = resolveEmojiPickerOptions(
        query: 'agua',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(results.map((option) => option.emoji), contains('💧'));
    });

    test('correr devuelve corredor', () {
      final results = resolveEmojiPickerOptions(
        query: 'correr',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(results.map((option) => option.emoji), contains('🏃'));
    });

    test('meditar devuelve meditacion', () {
      final results = resolveEmojiPickerOptions(
        query: 'meditar',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(results.map((option) => option.emoji), contains('🧘'));
    });

    test('dormir devuelve descanso', () {
      final results = resolveEmojiPickerOptions(
        query: 'dormir',
        selectedCategory: HabitEmojiCategories.frequent,
      );

      expect(
        results.map((option) => option.emoji),
        anyElement(isIn(<String>['😴', '🛏️'])),
      );
    });

    test('naturaleza devuelve opciones utiles', () {
      final results = resolveEmojiPickerOptions(
        query: 'naturaleza',
        selectedCategory: HabitEmojiCategories.nature,
      );

      expect(
        results.map((option) => option.emoji),
        anyElement(isIn(<String>['🌿', '🌳'])),
      );
    });

    test('familia devuelve grupo familiar', () {
      final results = resolveEmojiPickerOptions(
        query: 'familia',
        selectedCategory: HabitEmojiCategories.social,
      );

      expect(results.map((option) => option.emoji), contains('👨‍👩‍👧‍👦'));
    });

    test('xyzxyz devuelve vacio', () {
      final results = resolveEmojiPickerOptions(
        query: 'xyzxyz',
        selectedCategory: HabitEmojiCategories.others,
      );

      expect(results, isEmpty);
    });
  });
}
