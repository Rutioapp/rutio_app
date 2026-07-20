import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_cosmetics_snapshot.dart';
import '../../domain/models/shop_cosmetics_state.dart';

abstract class CloudCosmeticsCache {
  Future<CloudCosmeticsCacheEntry?> read(String userId);
  Future<CloudCosmeticsCacheEntry> save(CloudCosmeticsSnapshot snapshot);
  Future<void> clearForUser(String userId);
  Future<void> clearAll();
}

@immutable
class CloudCosmeticsCacheEntry {
  const CloudCosmeticsCacheEntry({
    required this.snapshot,
    required this.cachedAt,
  });

  final CloudCosmeticsSnapshot snapshot;
  final DateTime cachedAt;

  factory CloudCosmeticsCacheEntry.fromSnapshot(
    CloudCosmeticsSnapshot snapshot, {
    DateTime? cachedAt,
  }) {
    return CloudCosmeticsCacheEntry(
      snapshot: snapshot,
      cachedAt: (cachedAt ?? DateTime.now()).toUtc(),
    );
  }

  factory CloudCosmeticsCacheEntry.fromJson(Map<String, dynamic> json) {
    final snapshotJson = json['snapshot'];
    final snapshotMap = snapshotJson is Map
        ? Map<String, dynamic>.from(snapshotJson.cast<String, dynamic>())
        : null;
    final cachedAt = DateTime.tryParse((json['cachedAt'] ?? '').toString());
    if (snapshotMap == null || cachedAt == null) {
      throw const FormatException('Invalid cloud cosmetics cache entry.');
    }
    return CloudCosmeticsCacheEntry(
      snapshot: CloudCosmeticsSnapshot.fromJson(snapshotMap),
      cachedAt: cachedAt.toUtc(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'snapshot': snapshot.toJson(),
      'cachedAt': cachedAt.toIso8601String(),
    };
  }

  ShopCosmeticsState toState({
    Iterable<String> ownedBundleIds = const <String>[],
  }) {
    return snapshot.toState(ownedBundleIds: ownedBundleIds);
  }
}

class SharedPreferencesCloudCosmeticsCache implements CloudCosmeticsCache {
  SharedPreferencesCloudCosmeticsCache({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String _storagePrefix = 'rutio_cloud_cosmetics_v1_';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<CloudCosmeticsCacheEntry?> read(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    final key = _storageKey(userId);
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CloudCosmeticsCacheEntry.fromJson(
        Map<String, dynamic>.from(decoded.cast<String, dynamic>()),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CloudCosmeticsCacheEntry> save(CloudCosmeticsSnapshot snapshot) async {
    final prefs = await _sharedPreferencesProvider();
    final entry = CloudCosmeticsCacheEntry.fromSnapshot(snapshot);
    await prefs.setString(_storageKey(snapshot.userId), _encode(entry));
    return entry;
  }

  @override
  Future<void> clearForUser(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(userId));
  }

  @override
  Future<void> clearAll() async {
    final prefs = await _sharedPreferencesProvider();
    for (final key in prefs.getKeys()) {
      if (key.startsWith(_storagePrefix)) {
        await prefs.remove(key);
      }
    }
  }

  String _encode(CloudCosmeticsCacheEntry entry) {
    return jsonEncode(entry.toJson());
  }

  String _storageKey(String userId) => '$_storagePrefix$userId';
}
