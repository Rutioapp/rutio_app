import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  @visibleForTesting
  static const String userKey = 'local_user_v1';

  Future<bool> signUp({required String email, required String pass}) async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanLegacyCredentialIfPresent(prefs);
    final raw = prefs.getString(userKey);
    if (raw != null) {
      final existing = _decodeMap(raw);
      final existingEmail = (existing['email'] ?? '').toString().toLowerCase();
      if (existingEmail == email.toLowerCase()) return false;
      // 1 usuario por dispositivo:
      return false;
    }
    await prefs.setString(userKey, jsonEncode({'email': email.trim()}));
    return true;
  }

  Future<bool> login({required String email, required String pass}) async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanLegacyCredentialIfPresent(prefs);
    return false;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  Future<void> cleanLegacyCredential() async {
    final prefs = await SharedPreferences.getInstance();
    await _cleanLegacyCredentialIfPresent(prefs);
  }

  Future<void> _cleanLegacyCredentialIfPresent(SharedPreferences prefs) async {
    final raw = prefs.getString(userKey);
    if (raw == null) return;

    final data = _decodeMap(raw);
    if (data.isEmpty) {
      await prefs.remove(userKey);
      return;
    }

    final containsLegacySecret = data.containsKey('pass') ||
        data.containsKey('password') ||
        data.containsKey('token');
    if (!containsLegacySecret) return;

    final email = (data['email'] ?? '').toString().trim();
    if (email.isEmpty) {
      await prefs.remove(userKey);
      return;
    }
    await prefs.setString(userKey, jsonEncode({'email': email}));
    if (kDebugMode) {
      debugPrint('[session_service] cleaned legacy local_user_v1 credential');
    }
  }

  Map<String, dynamic> _decodeMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
    } catch (_) {
      return <String, dynamic>{};
    }
    return <String, dynamic>{};
  }
}
