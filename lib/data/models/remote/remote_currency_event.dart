import 'package:flutter/foundation.dart';

@immutable
class RemoteCurrencyEvent {
  const RemoteCurrencyEvent({
    this.id,
    required this.userId,
    required this.amount,
    this.currency = 'ambar',
    required this.source,
    this.sourceId,
    this.description,
    this.createdAt,
    this.raw = const <String, dynamic>{},
  });

  final String? id;
  final String userId;
  final int amount;
  final String currency;
  final String source;
  final String? sourceId;
  final String? description;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory RemoteCurrencyEvent.fromMap(Map<String, dynamic> map) {
    return RemoteCurrencyEvent(
      id: _nullableTrim(map['id']),
      userId: (map['user_id'] ?? map['userId'] ?? '').toString().trim(),
      amount: _safeInt(map['amount'], fallback: 0),
      currency: _normalizeCurrency(map['currency']),
      source: _nullableTrim(map['source']) ?? 'system',
      sourceId: _nullableTrim(map['source_id']),
      description: _nullableTrim(map['description']),
      createdAt: _nullableDateTime(map['created_at']),
      raw: Map<String, dynamic>.from(map),
    );
  }

  Map<String, dynamic> toInsertMap() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'amount': amount,
      'currency': _normalizeCurrency(currency),
      'source': source,
      'source_id': sourceId,
      'description': description,
    };

    final normalizedId = _nullableTrim(id);
    if (normalizedId != null) {
      payload['id'] = normalizedId;
    }

    payload.removeWhere((_, value) => value == null);
    return payload;
  }

  static String _normalizeCurrency(dynamic value) {
    final normalized = (value ?? '').toString().trim().toLowerCase();
    if (normalized == 'ambar') return 'ambar';
    return 'ambar';
  }

  static String? _nullableTrim(dynamic value) {
    final normalized = (value ?? '').toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static int _safeInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString().trim()) ?? fallback;
  }

  static DateTime? _nullableDateTime(dynamic value) {
    if (value == null) return null;
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) return null;
    return DateTime.tryParse(normalized);
  }
}
