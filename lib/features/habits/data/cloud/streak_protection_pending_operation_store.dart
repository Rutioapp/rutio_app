import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class PendingStreakShieldOperation {
  const PendingStreakShieldOperation({
    required this.userId,
    required this.requestId,
    required this.operationId,
    required this.remoteHabitId,
    required this.protectedOccurrenceDate,
    required this.utilityId,
    required this.createdAtMillis,
  });

  final String userId;
  final String requestId;
  final String operationId;
  final String remoteHabitId;
  final String protectedOccurrenceDate;
  final String utilityId;
  final int createdAtMillis;

  factory PendingStreakShieldOperation.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final operationId = _trim(json['operationId'] ?? json['operation_id']);
    final remoteHabitId =
        _trim(json['remoteHabitId'] ?? json['remote_habit_id']);
    final protectedOccurrenceDate = _trim(
      json['protectedOccurrenceDate'] ?? json['protected_occurrence_date'],
    );
    final utilityId = _trim(json['utilityId'] ?? json['utility_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    if (userId == null ||
        requestId == null ||
        operationId == null ||
        remoteHabitId == null ||
        protectedOccurrenceDate == null ||
        utilityId == null ||
        createdAtMillis == null) {
      throw const FormatException('Invalid pending streak shield operation.');
    }
    return PendingStreakShieldOperation(
      userId: userId,
      requestId: requestId,
      operationId: operationId,
      remoteHabitId: remoteHabitId,
      protectedOccurrenceDate: protectedOccurrenceDate,
      utilityId: utilityId,
      createdAtMillis: createdAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'operationId': operationId,
      'remoteHabitId': remoteHabitId,
      'protectedOccurrenceDate': protectedOccurrenceDate,
      'utilityId': utilityId,
      'createdAtMillis': createdAtMillis,
    };
  }
}

@immutable
class PendingStreakRecoverOperation {
  const PendingStreakRecoverOperation({
    required this.userId,
    required this.requestId,
    required this.operationId,
    required this.breakId,
    required this.utilityId,
    required this.createdAtMillis,
  });

  final String userId;
  final String requestId;
  final String operationId;
  final String breakId;
  final String utilityId;
  final int createdAtMillis;

  factory PendingStreakRecoverOperation.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final operationId = _trim(json['operationId'] ?? json['operation_id']);
    final breakId = _trim(json['breakId'] ?? json['break_id']);
    final utilityId = _trim(json['utilityId'] ?? json['utility_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    if (userId == null ||
        requestId == null ||
        operationId == null ||
        breakId == null ||
        utilityId == null ||
        createdAtMillis == null) {
      throw const FormatException('Invalid pending streak recover operation.');
    }
    return PendingStreakRecoverOperation(
      userId: userId,
      requestId: requestId,
      operationId: operationId,
      breakId: breakId,
      utilityId: utilityId,
      createdAtMillis: createdAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'operationId': operationId,
      'breakId': breakId,
      'utilityId': utilityId,
      'createdAtMillis': createdAtMillis,
    };
  }
}

abstract class StreakProtectionPendingOperationStore {
  Future<PendingStreakShieldOperation?> loadShieldOperation(
    String userId,
    String operationId,
  );

  Future<void> saveShieldOperation(PendingStreakShieldOperation operation);

  Future<void> clearShieldOperation(String userId, String operationId);

  Future<PendingStreakRecoverOperation?> loadRecoverOperation(
    String userId,
    String operationId,
  );

  Future<void> saveRecoverOperation(PendingStreakRecoverOperation operation);

  Future<void> clearRecoverOperation(String userId, String operationId);
}

class SharedPreferencesStreakProtectionPendingOperationStore
    implements StreakProtectionPendingOperationStore {
  SharedPreferencesStreakProtectionPendingOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance;

  static const String _shieldPrefix = 'rutio_streak_shield_pending_v1';
  static const String _recoverPrefix = 'rutio_streak_recover_pending_v1';

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;

  @override
  Future<PendingStreakShieldOperation?> loadShieldOperation(
    String userId,
    String operationId,
  ) async {
    final operations = await _loadShieldOperations(userId);
    for (final operation in operations) {
      if (operation.operationId == operationId.trim()) return operation;
    }
    return null;
  }

  @override
  Future<void> saveShieldOperation(
      PendingStreakShieldOperation operation) async {
    final operations = await _loadShieldOperations(operation.userId);
    operations
        .removeWhere((entry) => entry.operationId == operation.operationId);
    operations.add(operation);
    await _saveList(
      _shieldKey(operation.userId),
      operations.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearShieldOperation(String userId, String operationId) async {
    final operations = await _loadShieldOperations(userId);
    operations.removeWhere((entry) => entry.operationId == operationId.trim());
    await _saveList(
      _shieldKey(userId),
      operations.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  @override
  Future<PendingStreakRecoverOperation?> loadRecoverOperation(
    String userId,
    String operationId,
  ) async {
    final operations = await _loadRecoverOperations(userId);
    for (final operation in operations) {
      if (operation.operationId == operationId.trim()) return operation;
    }
    return null;
  }

  @override
  Future<void> saveRecoverOperation(
    PendingStreakRecoverOperation operation,
  ) async {
    final operations = await _loadRecoverOperations(operation.userId);
    operations
        .removeWhere((entry) => entry.operationId == operation.operationId);
    operations.add(operation);
    await _saveList(
      _recoverKey(operation.userId),
      operations.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearRecoverOperation(String userId, String operationId) async {
    final operations = await _loadRecoverOperations(userId);
    operations.removeWhere((entry) => entry.operationId == operationId.trim());
    await _saveList(
      _recoverKey(userId),
      operations.map((entry) => entry.toJson()).toList(growable: false),
    );
  }

  Future<List<PendingStreakShieldOperation>> _loadShieldOperations(
    String userId,
  ) async {
    final raw = await _loadList(_shieldKey(userId));
    final operations = <PendingStreakShieldOperation>[];
    for (final value in raw) {
      if (value is! Map) continue;
      try {
        operations.add(
          PendingStreakShieldOperation.fromJson(
            Map<String, dynamic>.from(value.cast<String, dynamic>()),
          ),
        );
      } catch (_) {}
    }
    return operations;
  }

  Future<List<PendingStreakRecoverOperation>> _loadRecoverOperations(
    String userId,
  ) async {
    final raw = await _loadList(_recoverKey(userId));
    final operations = <PendingStreakRecoverOperation>[];
    for (final value in raw) {
      if (value is! Map) continue;
      try {
        operations.add(
          PendingStreakRecoverOperation.fromJson(
            Map<String, dynamic>.from(value.cast<String, dynamic>()),
          ),
        );
      } catch (_) {}
    }
    return operations;
  }

  Future<List<dynamic>> _loadList(String key) async {
    final prefs = await _sharedPreferencesProvider();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return const <dynamic>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    } catch (_) {}
    return const <dynamic>[];
  }

  Future<void> _saveList(String key, List<dynamic> value) async {
    final prefs = await _sharedPreferencesProvider();
    await prefs.setString(key, jsonEncode(value));
  }

  String _shieldKey(String userId) => '${_shieldPrefix}_${userId.trim()}';
  String _recoverKey(String userId) => '${_recoverPrefix}_${userId.trim()}';
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
