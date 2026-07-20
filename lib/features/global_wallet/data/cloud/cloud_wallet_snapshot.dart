import 'package:flutter/foundation.dart';

@immutable
class CloudWalletSnapshot {
  const CloudWalletSnapshot({
    required this.userId,
    required this.coins,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.fetchedAt,
  });

  final String userId;
  final int coins;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime fetchedAt;

  factory CloudWalletSnapshot.fromMap(
    Map<String, dynamic> map, {
    required String expectedUserId,
    required DateTime fetchedAt,
  }) {
    final userId = _nullableTrim(map['user_id'] ?? map['userId']);
    final coins = _safeInt(map['coins']);
    final version = _safeInt(map['version']);
    final createdAt = _nullableDateTime(map['created_at'] ?? map['createdAt']);
    final updatedAt = _nullableDateTime(map['updated_at'] ?? map['updatedAt']);

    if (userId == null ||
        userId.isEmpty ||
        coins == null ||
        coins < 0 ||
        version == null ||
        version < 0 ||
        createdAt == null ||
        updatedAt == null) {
      throw const FormatException('Invalid cloud wallet row.');
    }

    if (userId.trim() != expectedUserId.trim()) {
      throw const FormatException('Cloud wallet user scope mismatch.');
    }

    return CloudWalletSnapshot(
      userId: userId,
      coins: coins,
      version: version,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
      fetchedAt: fetchedAt.toUtc(),
    );
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
