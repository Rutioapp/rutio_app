import 'dart:math' as math;

import 'motivational_phrase.dart';
import 'phrase_template_renderer.dart';

abstract interface class PhraseRandomSource {
  double nextDouble();
}

class MathPhraseRandomSource implements PhraseRandomSource {
  MathPhraseRandomSource([math.Random? random])
      : _random = random ?? math.Random();

  final math.Random _random;

  @override
  double nextDouble() => _random.nextDouble();
}

class PhraseSelectionResult {
  const PhraseSelectionResult({
    required this.phrase,
    required this.text,
    required this.history,
    required this.relaxedHistoryCount,
  });

  final MotivationalPhrase phrase;
  final String text;
  final PhraseHistory history;
  final int relaxedHistoryCount;
}

class PhraseSelectionEngine {
  PhraseSelectionEngine({
    PhraseTemplateRenderer? renderer,
    PhraseRandomSource? randomSource,
  })  : _renderer = renderer ?? PhraseTemplateRenderer(),
        _randomSource = randomSource ?? MathPhraseRandomSource();

  final PhraseTemplateRenderer _renderer;
  final PhraseRandomSource _randomSource;

  PhraseSelectionResult? select({
    required Iterable<MotivationalPhrase> phrases,
    required PhraseContext context,
    required PhraseHistory history,
  }) {
    final eligible = phrases
        .where((phrase) => phrase.enabled)
        .where((phrase) => _renderer.canRender(phrase, context))
        .toList(growable: false);
    if (eligible.isEmpty) return null;

    final historyIds = history.phraseIds.toSet();
    var candidates = eligible
        .where((phrase) => !historyIds.contains(phrase.id))
        .toList(growable: false);
    var relaxedHistoryCount = 0;
    final oldestFirst = history.phraseIds;
    while (candidates.isEmpty && relaxedHistoryCount < oldestFirst.length) {
      final relaxed = oldestFirst[relaxedHistoryCount];
      relaxedHistoryCount += 1;
      candidates = eligible
          .where((phrase) =>
              !historyIds.contains(phrase.id) || phrase.id == relaxed)
          .toList(growable: false);
    }
    if (candidates.isEmpty) return null;

    final byCategory = <PhraseCategory, List<MotivationalPhrase>>{};
    for (final phrase in candidates) {
      (byCategory[phrase.category] ??= <MotivationalPhrase>[]).add(phrase);
    }

    final category = _pickWeightedCategory(byCategory, context);
    final selected = _pickWeighted(
      byCategory[category]!,
      weightOf: (phrase) => phrase.weight,
    );
    return PhraseSelectionResult(
      phrase: selected,
      text: _renderer.render(selected, context),
      history: history.append(selected.id),
      relaxedHistoryCount: relaxedHistoryCount,
    );
  }

  PhraseCategory _pickWeightedCategory(
    Map<PhraseCategory, List<MotivationalPhrase>> candidates,
    PhraseContext context,
  ) {
    final weights = <PhraseCategory, double>{};
    final hasNameAndStreak =
        context.normalizedName != null && context.streak > 0;
    if (candidates.containsKey(PhraseCategory.motivation)) {
      weights[PhraseCategory.motivation] = hasNameAndStreak ? 42 : 50;
    }
    if (candidates.containsKey(PhraseCategory.consistency)) {
      weights[PhraseCategory.consistency] = 33;
    }
    if (candidates.containsKey(PhraseCategory.personal)) {
      weights[PhraseCategory.personal] = hasNameAndStreak ? 25 : 17;
    }
    return _pickWeightedFromMap(weights);
  }

  T _pickWeighted<T>(
    List<T> candidates, {
    double Function(T candidate)? weightOf,
  }) {
    final weights = <T, double>{
      for (final candidate in candidates)
        candidate: weightOf?.call(candidate) ?? 1,
    };
    return _pickWeightedFromMap(weights);
  }

  T _pickWeightedFromMap<T>(Map<T, double> weights) {
    final total = weights.values.fold<double>(0, (sum, value) => sum + value);
    if (total <= 0) throw StateError('Cannot select from empty weighted set.');
    final target = _normalizedRandom() * total;
    var cumulative = 0.0;
    for (final entry in weights.entries) {
      cumulative += entry.value;
      if (target < cumulative) return entry.key;
    }
    return weights.keys.last;
  }

  double _normalizedRandom() {
    final value = _randomSource.nextDouble();
    if (!value.isFinite || value <= 0) return 0;
    if (value >= 1) return 0.999999999;
    return value;
  }
}
