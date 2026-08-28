abstract class NotificationClock {
  const NotificationClock();

  DateTime now();

  String timezoneId();

  DateTime localNow() => now().toLocal();

  DateTime localDate() {
    final current = localNow();
    return DateTime(current.year, current.month, current.day);
  }
}

class SystemNotificationClock extends NotificationClock {
  const SystemNotificationClock({
    DateTime Function()? nowProvider,
    String Function()? timezoneIdProvider,
  })  : _nowProvider = nowProvider ?? DateTime.now,
        _timezoneIdProvider = timezoneIdProvider ?? _defaultTimezoneId;

  final DateTime Function() _nowProvider;
  final String Function() _timezoneIdProvider;

  @override
  DateTime now() => _nowProvider();

  @override
  String timezoneId() => _timezoneIdProvider();

  static String _defaultTimezoneId() {
    final name = DateTime.now().timeZoneName.trim();
    return name.isEmpty ? 'unknown' : name;
  }
}

class FakeNotificationClock extends NotificationClock {
  FakeNotificationClock({
    required DateTime currentTime,
    String timezoneId = 'Europe/Madrid',
  })  : _currentTime = currentTime,
        _timezoneId = timezoneId;

  DateTime _currentTime;
  String _timezoneId;

  @override
  DateTime now() => _currentTime;

  @override
  String timezoneId() => _timezoneId;

  void setNow(DateTime value) {
    _currentTime = value;
  }

  void advance(Duration delta) {
    _currentTime = _currentTime.add(delta);
  }

  void setTimezoneId(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, 'value', 'timezoneId cannot be empty.');
    }
    _timezoneId = normalized;
  }
}
