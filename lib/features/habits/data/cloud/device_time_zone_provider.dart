import 'package:flutter_timezone/flutter_timezone.dart';

abstract class DeviceTimeZoneProvider {
  Future<String?> getLocalIanaTimeZone();
}

class FlutterDeviceTimeZoneProvider implements DeviceTimeZoneProvider {
  const FlutterDeviceTimeZoneProvider();

  @override
  Future<String?> getLocalIanaTimeZone() async {
    final timeZone = await FlutterTimezone.getLocalTimezone();
    final identifier = timeZone.trim();
    return identifier.isEmpty ? null : identifier;
  }
}
