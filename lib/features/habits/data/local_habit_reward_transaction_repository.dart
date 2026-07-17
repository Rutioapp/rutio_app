import 'dart:convert';

import 'package:rutio/features/habits/domain/habit_reward_transaction_repository.dart';
import 'package:rutio/features/habits/domain/models/habit_reward_transaction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalHabitRewardTransactionRepository
    implements HabitRewardTransactionRepository {
  LocalHabitRewardTransactionRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String storageKey = 'rutio_habit_reward_transactions_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  @override
  Future<HabitRewardTransaction?> findByCompletion({
    required String userScope,
    required String habitId,
    required String localDateKey,
  }) async {
    final transactions = await loadTransactions(userScope);
    final normalizedHabitId = habitId.trim();
    final normalizedDateKey = localDateKey.trim();
    for (final tx in transactions) {
      if (tx.habitId == normalizedHabitId &&
          tx.localDateKey == normalizedDateKey) {
        return tx;
      }
    }
    return null;
  }

  @override
  Future<List<HabitRewardTransaction>> loadTransactions(
      String userScope) async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(_storageKeyForScope(userScope));
      if (raw == null || raw.trim().isEmpty) {
        return const <HabitRewardTransaction>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <HabitRewardTransaction>[];

      final parsed = decoded
          .whereType<Map>()
          .map(
            (entry) => HabitRewardTransaction.fromJson(
              entry.cast<String, dynamic>(),
            ),
          )
          .where(_isValidTransaction)
          .toList(growable: false);
      return _dedupeAndSort(parsed);
    } catch (_) {
      return const <HabitRewardTransaction>[];
    }
  }

  @override
  Future<void> saveTransaction(
    String userScope,
    HabitRewardTransaction transaction,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final existing = await loadTransactions(userScope);
    final next = <HabitRewardTransaction>[
      ...existing.where(
        (current) =>
            current.habitId != transaction.habitId ||
            current.localDateKey != transaction.localDateKey,
      ),
      transaction,
    ];
    final sanitized = _dedupeAndSort(
      next.where(_isValidTransaction).toList(growable: false),
    );
    await prefs.setString(
      _storageKeyForScope(userScope),
      jsonEncode(sanitized.map((tx) => tx.toJson()).toList()),
    );
  }

  String? _resolvedScope(String? scope) {
    final resolved = (scope ?? _scopeResolver?.call() ?? '').trim();
    return resolved.isEmpty ? null : resolved;
  }

  String _storageKeyForScope(String? scope) {
    final resolved = _resolvedScope(scope);
    if (resolved == null) return storageKey;
    return '${storageKey}_${_safeKeyFragment(resolved)}';
  }

  String _safeKeyFragment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  bool _isValidTransaction(HabitRewardTransaction tx) {
    if (tx.id.trim().isEmpty) return false;
    if (tx.habitId.trim().isEmpty) return false;
    if (tx.localDateKey.trim().isEmpty) return false;
    if (tx.baseXp < 0 || tx.bonusXp < 0) return false;
    if (tx.baseCoins < 0 || tx.bonusCoins < 0) return false;
    if (tx.createdAtMillis < 0) return false;
    final sanitizedEffects = tx.appliedEffectIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (sanitizedEffects.length != tx.appliedEffectIds.length) {
      return false;
    }
    return true;
  }

  List<HabitRewardTransaction> _dedupeAndSort(
    List<HabitRewardTransaction> transactions,
  ) {
    final byCompletionKey = <String, HabitRewardTransaction>{};
    final ordered = List<HabitRewardTransaction>.from(transactions)
      ..sort((a, b) {
        final byCreated = b.createdAtMillis.compareTo(a.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return b.id.compareTo(a.id);
      });

    for (final tx in ordered) {
      byCompletionKey.putIfAbsent(tx.completionKey, () => tx);
    }

    return byCompletionKey.values.toList(growable: false)
      ..sort((a, b) => a.createdAtMillis.compareTo(b.createdAtMillis));
  }
}
