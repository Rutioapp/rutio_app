import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService._();
  static final SessionService instance = SessionService._();

  static const String _kUserKey = 'local_user_v1'; // {email, pass}

  Future<bool> signUp({required String email, required String pass}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);
    if (raw != null) {
      final existing = jsonDecode(raw);
      final existingEmail = (existing['email'] ?? '').toString().toLowerCase();
      if (existingEmail == email.toLowerCase()) return false;
      // 1 usuario por dispositivo:
      return false;
    }
    await prefs.setString(_kUserKey, jsonEncode({'email': email, 'pass': pass}));
    return true;
  }

  Future<bool> login({required String email, required String pass}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUserKey);
    if (raw == null) return false;

    final data = jsonDecode(raw);
    final savedEmail = (data['email'] ?? '').toString().toLowerCase();
    final savedPass = (data['pass'] ?? '').toString();

    return email.toLowerCase() == savedEmail && pass == savedPass;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);
  }
}
