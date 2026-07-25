import 'package:flutter/foundation.dart';

typedef NowProvider = DateTime Function();

class RutioCalendarClock {
  const RutioCalendarClock._();

  static const String environmentKey = 'RUTIO_DEV_NOW';

  static NowProvider resolve() {
    if (kReleaseMode) {
      return DateTime.now;
    }

    return resolveFromValue(
      rawValue: const String.fromEnvironment(environmentKey),
      releaseMode: false,
    );
  }

  @visibleForTesting
  static NowProvider resolveFromValue({
    required String? rawValue,
    required bool releaseMode,
    void Function(String message)? debugLogger,
  }) {
    if (releaseMode) {
      return DateTime.now;
    }

    final normalized = (rawValue ?? '').trim();
    if (normalized.isEmpty) {
      return DateTime.now;
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) {
      if (kDebugMode) {
        (debugLogger ?? debugPrint)(
          '[calendar-clock] invalid RUTIO_DEV_NOW="$normalized" fallback=system',
        );
      }
      return DateTime.now;
    }

    if (kDebugMode) {
      (debugLogger ?? debugPrint)(
        '[calendar-clock] simulated now=${parsed.toIso8601String()}',
      );
    }

    return () => parsed;
  }
}
