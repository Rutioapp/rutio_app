import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserStateStorage {
  static const _key = 'user_state_v1';

  Future<Map<String, dynamic>?> read() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Future<void> write(Map<String, dynamic> userStateJson) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(userStateJson));
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
