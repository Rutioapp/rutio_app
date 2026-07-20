import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_wallet_snapshot.dart';

@immutable
class WalletCacheEntry {
  const WalletCacheEntry({
    required this.userId,
    required this.coins,
    required this.version,
    required this.updatedAt,
    required this.cachedAt,
  });

  final String userId;
  final int coins;
  final int version;
  final DateTime updatedAt;
  final DateTime cachedAt;

  factory WalletCacheEntry.fromSnapshot(
    CloudWalletSnapshot snapshot, {
    DateTime? cachedAt,
  }) {
    return WalletCacheEntry(
      userId: snapshot.userId,
      coins: snapshot.coins,
      version: snapshot.version,
      updatedAt: snapshot.updatedAt.toUtc(),
      cachedAt: (cachedAt ?? snapshot.fetchedAt).toUtc(),
    );
  }

  factory WalletCacheEntry.fromJson(Map<String, dynamic> json) {
    final userId = _nullableTrim(json['userId'] ?? json['user_id']);
    final coins = _safeInt(json['coins']);
    final version = _safeInt(json['version']);
    final updatedAt =
        _nullableDateTime(json['updatedAt'] ?? json['updated_at']);
    final cachedAt = _nullableDateTime(json['cachedAt'] ?? json['cached_at']);

    if (userId == null ||
        userId.isEmpty ||
        coins == null ||
        version == null ||
        updatedAt == null ||
        cachedAt == null) {
      throw const FormatException('Invalid wallet cache entry.');
    }

    return WalletCacheEntry(
      userId: userId,
      coins: coins,
      version: version,
      updatedAt: updatedAt.toUtc(),
      cachedAt: cachedAt.toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'coins': coins,
      'version': version,
      'updatedAt': updatedAt.toIso8601String(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  CloudWalletSnapshot toSnapshot() {
    return CloudWalletSnapshot(
      userId: userId,
      coins: coins,
      version: version,
      createdAt: updatedAt,
      updatedAt: updatedAt,
      fetchedAt: cachedAt,
    );
  }

  bool isNewerThan(WalletCacheEntry other) {
    if (version != other.version) return version > other.version;
    final updatedComparison = updatedAt.compareTo(other.updatedAt);
    if (updatedComparison != 0) return updatedComparison > 0;
    return cachedAt.isAfter(other.cachedAt);
  }

  static String? _nullableTrim(Object? value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int? _safeInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim());
  }

  static DateTime? _nullableDateTime(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final normalized = value.toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}

abstract class WalletCache {
  Future<WalletCacheEntry?> read(String userId);

  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot);

  Future<void> clearForUser(String userId);
}

class SharedPreferencesWalletCache implements WalletCache {
  SharedPreferencesWalletCache({
    Future<SharedPreferences> Function()? preferencesFactory,
    this.keyPrefix = 'global_cloud_wallet_cache_v1_',
  }) : _preferencesFactory =
            preferencesFactory ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesFactory;
  final String keyPrefix;
  Future<SharedPreferences>? _preferencesFuture;

  @override
  Future<WalletCacheEntry?> read(String userId) async {
    final prefs = await _preferences();
    final payload = prefs.getString(_keyFor(userId));
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;
      return WalletCacheEntry.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      await prefs.remove(_keyFor(userId));
      return null;
    }
  }

  @override
  Future<WalletCacheEntry?> save(CloudWalletSnapshot snapshot) async {
    final prefs = await _preferences();
    final current = await read(snapshot.userId);
    final next = WalletCacheEntry.fromSnapshot(
      snapshot,
      cachedAt: DateTime.now().toUtc(),
    );

    if (current != null && !next.isNewerThan(current)) {
      return current;
    }

    await prefs.setString(_keyFor(snapshot.userId), jsonEncode(next.toJson()));
    return next;
  }

  @override
  Future<void> clearForUser(String userId) async {
    final prefs = await _preferences();
    await prefs.remove(_keyFor(userId));
  }

  Future<SharedPreferences> _preferences() async {
    return _preferencesFuture ??= _preferencesFactory();
  }

  String _keyFor(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return '${keyPrefix}guest';
    }
    final safe = normalized.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return '$keyPrefix$safe';
  }
}
