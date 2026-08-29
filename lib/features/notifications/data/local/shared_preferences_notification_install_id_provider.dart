import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/personalized_notification_ports.dart';
import 'notification_local_storage_scope.dart';

class SharedPreferencesNotificationInstallIdProvider
    implements NotificationInstallIdProvider {
  SharedPreferencesNotificationInstallIdProvider({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    Random? random,
  })  : _sharedPreferencesProvider =
            sharedPreferencesProvider ?? SharedPreferences.getInstance,
        _randomSource = random;

  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final Random? _randomSource;
  late final Random _random = _randomSource ?? Random.secure();

  @override
  Future<String> getOrCreateInstallId() async {
    final prefs = await _sharedPreferencesProvider();
    final existing =
        prefs.getString(NotificationLocalStorageScope.installIdKey);
    if (existing != null && _isValidUuid(existing)) {
      return existing;
    }

    final generated = _generateUuidV4();
    await prefs.setString(
        NotificationLocalStorageScope.installIdKey, generated);
    return generated;
  }

  String _generateUuidV4() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hexByte(int value) => value.toRadixString(16).padLeft(2, '0');

    final hex = bytes.map(hexByte).join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  bool _isValidUuid(String value) {
    final normalized = value.trim();
    return RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    ).hasMatch(normalized);
  }
}
