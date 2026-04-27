import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStateStorage {
  static const String legacyKey = 'user_state_v1';
  static const String _scopedKeyPrefix = 'user_state_v1_';
  static const String _legacyClaimedByKey = 'user_state_v1_legacy_claimed_by';

  Future<Map<String, dynamic>?> read({String? userId}) async {
    final sp = await SharedPreferences.getInstance();
    final key = _storageKeyFor(userId: userId);
    final data = _decodeMap(sp.getString(key));
    if (data != null && _isDebugLoggingEnabled) {
      final activeHabitsCount = _activeHabitsCount(data);
      final historyDayCount = _historyDayCount(data);
      _debug(
        'read key="$key" loaded=true activeHabits=$activeHabitsCount historyDays=$historyDayCount',
      );
    } else if (_isDebugLoggingEnabled) {
      _debug('read key="$key" loaded=false');
    }
    return data;
  }

  Future<Map<String, dynamic>?> readLegacy() async {
    final sp = await SharedPreferences.getInstance();
    return _decodeMap(sp.getString(legacyKey));
  }

  Future<void> write(
    Map<String, dynamic> userStateJson, {
    String? userId,
  }) async {
    final sp = await SharedPreferences.getInstance();
    final key = _storageKeyFor(userId: userId);
    await sp.setString(key, jsonEncode(userStateJson));
    if (_isDebugLoggingEnabled) {
      final activeHabitsCount = _activeHabitsCount(userStateJson);
      final historyDayCount = _historyDayCount(userStateJson);
      _debug(
        'write key="$key" activeHabits=$activeHabitsCount historyDays=$historyDayCount',
      );
    }
  }

  Future<void> clear({String? userId}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_storageKeyFor(userId: userId));
  }

  Future<bool> migrateLegacyToScopedIfEligible({
    required String userId,
  }) async {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return false;

    final sp = await SharedPreferences.getInstance();
    final scopedKey = _storageKeyFor(userId: normalizedUserId);
    final scopedRaw = sp.getString(scopedKey);
    if (scopedRaw != null) return false;

    final legacyRaw = sp.getString(legacyKey);
    if (legacyRaw == null) return false;

    final claimedBy = _normalizeUserId(sp.getString(_legacyClaimedByKey));
    if (claimedBy != null) return false;

    final copied = await sp.setString(scopedKey, legacyRaw);
    if (!copied) return false;

    await sp.setString(_legacyClaimedByKey, normalizedUserId);
    if (_isDebugLoggingEnabled) {
      _debug(
        'migrated legacy key into scoped key="$scopedKey" for userId=$normalizedUserId',
      );
    }
    return true;
  }

  Future<String?> legacyClaimedByUserId() async {
    final sp = await SharedPreferences.getInstance();
    return _normalizeUserId(sp.getString(_legacyClaimedByKey));
  }

  String scopedStorageKeyForUser(String userId) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) {
      throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
    }
    return _storageKeyFor(userId: normalizedUserId);
  }

  String _storageKeyFor({String? userId}) {
    final normalizedUserId = _normalizeUserId(userId);
    if (normalizedUserId == null) return legacyKey;
    return '$_scopedKeyPrefix${_safeKeyFragment(normalizedUserId)}';
  }

  String? _normalizeUserId(String? value) {
    final normalized = (value ?? '').trim();
    return normalized.isEmpty ? null : normalized;
  }

  String _safeKeyFragment(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  bool get _isDebugLoggingEnabled {
    var enabled = false;
    assert(() {
      enabled = true;
      return true;
    }());
    return enabled;
  }

  int _activeHabitsCount(Map<String, dynamic> root) {
    final userState = root['userState'];
    if (userState is! Map) return 0;
    final activeHabits = userState['activeHabits'];
    if (activeHabits is! List) return 0;
    return activeHabits.length;
  }

  int _historyDayCount(Map<String, dynamic> root) {
    final userState = root['userState'];
    if (userState is! Map) return 0;
    final history = userState['history'];
    if (history is! Map) return 0;
    final completions = history['habitCompletions'];
    if (completions is! Map) return 0;
    return completions.length;
  }

  void _debug(String message) {
    if (!_isDebugLoggingEnabled) return;
    debugPrint('[user_state_storage] $message');
  }
}
