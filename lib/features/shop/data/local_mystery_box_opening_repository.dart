import 'dart:convert';

import 'package:rutio/features/shop/data/shop_catalog.dart';
import 'package:rutio/features/shop/domain/mystery_box_opening_repository.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_reward_result.dart';
import 'package:rutio/features/shop/domain/models/shop_item_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalMysteryBoxOpeningRepository
    implements MysteryBoxOpeningRepository {
  LocalMysteryBoxOpeningRepository({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    String? Function()? scopeResolver,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _scopeResolver = scopeResolver;

  static const String storageKey = 'rutio_mystery_box_openings_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final String? Function()? _scopeResolver;

  @override
  Future<List<MysteryBoxOpeningTransaction>> loadTransactions(
    String userScope,
  ) async {
    try {
      final prefs = await _sharedPreferencesProvider();
      final raw = prefs.getString(_storageKeyForScope(userScope));
      if (raw == null || raw.trim().isEmpty) {
        return const <MysteryBoxOpeningTransaction>[];
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MysteryBoxOpeningTransaction>[];

      final parsed = decoded
          .whereType<Map>()
          .map((entry) =>
              MysteryBoxOpeningTransaction.fromJson(entry.cast<String, dynamic>()))
          .map(_sanitizeTransaction)
          .whereType<MysteryBoxOpeningTransaction>()
          .toList(growable: false);
      return _dedupeAndSort(parsed);
    } catch (_) {
      return const <MysteryBoxOpeningTransaction>[];
    }
  }

  @override
  Future<void> saveTransactions(
    String userScope,
    List<MysteryBoxOpeningTransaction> transactions,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final sanitized = _dedupeAndSort(
      transactions
          .map(_sanitizeTransaction)
          .whereType<MysteryBoxOpeningTransaction>()
          .toList(growable: false),
    );
    await prefs.setString(
      _storageKeyForScope(userScope),
      jsonEncode(sanitized.map((transaction) => transaction.toJson()).toList()),
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

  MysteryBoxOpeningTransaction? _sanitizeTransaction(
    MysteryBoxOpeningTransaction transaction,
  ) {
    final id = transaction.id.trim();
    final userScope = transaction.userScope.trim();
    final utilityId = transaction.mysteryBoxUtilityId.trim();
    if (id.isEmpty || userScope.isEmpty || utilityId.isEmpty) return null;
    if (transaction.createdAtMillis < 0) return null;
    if (!_isKnownMysteryBoxUtility(utilityId)) return null;

    final reward = transaction.reward;
    if (reward.rewardId.trim().isEmpty) return null;
    if (reward.coins < 0 || reward.xp < 0) return null;

    final sanitizedUtilityRewards = <String, int>{};
    for (final entry in reward.utilityRewards.entries) {
      final utilityRewardId = entry.key.trim();
      final quantity = entry.value;
      if (utilityRewardId.isEmpty || quantity <= 0) return null;
      if (ShopCatalog.getItemById(utilityRewardId) == null) return null;
      final catalogItem = ShopCatalog.getItemById(utilityRewardId);
      if (catalogItem == null || catalogItem.category != ShopItemCategory.utility) {
        return null;
      }
      sanitizedUtilityRewards[utilityRewardId] = quantity;
    }

    return transaction.copyWith(
      id: id,
      userScope: userScope,
      mysteryBoxUtilityId: utilityId,
      reward: MysteryBoxRewardResult(
        rewardId: reward.rewardId.trim(),
        coins: reward.coins,
        xp: reward.xp,
        utilityRewards: sanitizedUtilityRewards,
      ),
    );
  }

  bool _isKnownMysteryBoxUtility(String utilityId) {
    final catalogItem = ShopCatalog.getItemById(utilityId);
    return catalogItem != null && catalogItem.type == ShopItemType.mysteryBox;
  }

  List<MysteryBoxOpeningTransaction> _dedupeAndSort(
    List<MysteryBoxOpeningTransaction> transactions,
  ) {
    final byId = <String, MysteryBoxOpeningTransaction>{};
    final ordered = List<MysteryBoxOpeningTransaction>.from(transactions)
      ..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.id.compareTo(b.id);
      });

    for (final transaction in ordered) {
      final existing = byId[transaction.id];
      if (existing == null || _statusRank(transaction.status) >= _statusRank(existing.status)) {
        byId[transaction.id] = transaction;
      }
    }

    final deduped = byId.values.toList(growable: false)
      ..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.id.compareTo(b.id);
      });
    return deduped;
  }

  int _statusRank(MysteryBoxOpeningStatus status) {
    switch (status) {
      case MysteryBoxOpeningStatus.resolved:
        return 0;
      case MysteryBoxOpeningStatus.granted:
        return 1;
      case MysteryBoxOpeningStatus.presented:
        return 2;
    }
  }
}
