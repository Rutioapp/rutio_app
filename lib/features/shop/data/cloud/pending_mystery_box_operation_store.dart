import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class PendingMysteryBoxOpening {
  const PendingMysteryBoxOpening({
    required this.userId,
    required this.requestId,
    required this.createdAtMillis,
    required this.lastAttemptAtMillis,
    required this.attemptCount,
  });

  final String userId;
  final String requestId;
  final int createdAtMillis;
  final int lastAttemptAtMillis;
  final int attemptCount;

  PendingMysteryBoxOpening copyWith({
    String? userId,
    String? requestId,
    int? createdAtMillis,
    int? lastAttemptAtMillis,
    int? attemptCount,
  }) {
    return PendingMysteryBoxOpening(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  factory PendingMysteryBoxOpening.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final lastAttemptAtMillis =
        _int(json['lastAttemptAtMillis'] ?? json['last_attempt_at_millis']);
    final attemptCount = _int(json['attemptCount'] ?? json['attempt_count']);

    if (userId == null ||
        requestId == null ||
        createdAtMillis == null ||
        lastAttemptAtMillis == null ||
        attemptCount == null) {
      throw const FormatException('Invalid pending mystery box operation.');
    }

    return PendingMysteryBoxOpening(
      userId: userId,
      requestId: requestId,
      createdAtMillis: createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis,
      attemptCount: attemptCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'createdAtMillis': createdAtMillis,
      'lastAttemptAtMillis': lastAttemptAtMillis,
      'attemptCount': attemptCount,
    };
  }
}

abstract interface class PendingMysteryBoxOperationStore {
  Future<List<PendingMysteryBoxOpening>> loadPendingOperations(String userId);

  Future<void> savePendingOperations(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  );

  Future<void> clearPendingOperations(String userId);
}

class SharedPreferencesPendingMysteryBoxOperationStore
    implements PendingMysteryBoxOperationStore {
  SharedPreferencesPendingMysteryBoxOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String storagePrefix = 'rutio_mystery_box_pending_opening_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<List<PendingMysteryBoxOpening>> loadPendingOperations(
    String userId,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(_storageKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return const <PendingMysteryBoxOpening>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PendingMysteryBoxOpening>[];
      }

      final pending = <PendingMysteryBoxOpening>[];
      for (final value in decoded) {
        if (value is! Map) continue;
        try {
          pending.add(
            PendingMysteryBoxOpening.fromJson(
              Map<String, dynamic>.from(value.cast<String, dynamic>()),
            ),
          );
        } catch (_) {}
      }

      pending.sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.requestId.compareTo(b.requestId);
      });
      return pending;
    } catch (_) {
      return const <PendingMysteryBoxOpening>[];
    }
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  ) async {
    final prefs = await _sharedPreferencesProvider();
    final encoded = jsonEncode(
      operations.map((operation) => operation.toJson()).toList(growable: false),
    );
    await prefs.setString(_storageKey(userId), encoded);
  }

  @override
  Future<void> clearPendingOperations(String userId) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.remove(_storageKey(userId));
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}
