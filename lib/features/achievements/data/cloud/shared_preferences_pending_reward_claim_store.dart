import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/pending_reward_claim.dart';
import '../../domain/pending_reward_claim_store.dart';

class SharedPreferencesPendingRewardClaimStore
    implements PendingRewardClaimStore {
  SharedPreferencesPendingRewardClaimStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storagePrefix =
      'rutio_pending_reward_claim_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<List<PendingRewardClaim>> loadPendingClaims(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingRewardClaim>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <PendingRewardClaim>[];

      final claims = <PendingRewardClaim>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          claims.add(
            PendingRewardClaim.fromJson(
              Map<String, dynamic>.from(value.cast<String, dynamic>()),
            ),
          );
        } catch (_) {}
      }

      claims.sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
      return claims;
    } catch (_) {
      return const <PendingRewardClaim>[];
    }
  }

  @override
  Future<void> savePendingClaims(
    String userId,
    List<PendingRewardClaim> claims,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(
      claims.map((claim) => claim.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey(userId), encoded);
  }

  @override
  Future<void> clearPendingClaims(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(userId));
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
