class RutioRuntimeProfile {
  const RutioRuntimeProfile._({
    required this.profileName,
    required this.resetDemoRequested,
    required this.screenshotModeEnabled,
    required this.demoNowDate,
  });

  static const String profileEnvKey = 'RUTIO_PROFILE';
  static const String resetDemoEnvKey = 'RUTIO_RESET_DEMO';
  static const String screenshotModeEnvKey = 'RUTIO_SCREENSHOT_MODE';
  static const String demoNowEnvKey = 'RUTIO_DEMO_NOW';
  static const String demoProfileName = 'demo';

  final String profileName;
  final bool resetDemoRequested;
  final bool screenshotModeEnabled;
  final DateTime? demoNowDate;

  bool get isDemoProfile => profileName == demoProfileName;
  bool get shouldResetDemoProfile => isDemoProfile && resetDemoRequested;

  static final RutioRuntimeProfile current = parse(
    profileValue: const String.fromEnvironment(profileEnvKey),
    resetDemoValue: const String.fromEnvironment(resetDemoEnvKey),
    screenshotModeValue: const String.fromEnvironment(screenshotModeEnvKey),
    demoNowValue: const String.fromEnvironment(demoNowEnvKey),
  );

  static bool get isDemo => current.isDemoProfile;
  static bool get shouldResetDemo => current.shouldResetDemoProfile;
  static bool get isScreenshotMode => current.screenshotModeEnabled;
  static DateTime? get demoNow => current.demoNowDate;

  static RutioRuntimeProfile parse({
    String? profileValue,
    String? resetDemoValue,
    String? screenshotModeValue,
    String? demoNowValue,
  }) {
    final normalizedProfile = (profileValue ?? '').trim().toLowerCase();
    final normalizedReset = (resetDemoValue ?? '').trim().toLowerCase();
    final normalizedScreenshotMode =
        (screenshotModeValue ?? '').trim().toLowerCase();
    final parsedDemoNow = _parseDateOnly(demoNowValue);

    return RutioRuntimeProfile._(
      profileName: normalizedProfile.isEmpty ? 'default' : normalizedProfile,
      resetDemoRequested: _isTrue(normalizedReset),
      screenshotModeEnabled: _isTrue(normalizedScreenshotMode),
      demoNowDate: parsedDemoNow,
    );
  }

  static bool _isTrue(String value) {
    switch (value) {
      case '1':
      case 'true':
      case 'yes':
      case 'on':
        return true;
      default:
        return false;
    }
  }

  static DateTime? _parseDateOnly(String? rawValue) {
    final normalized = (rawValue ?? '').trim();
    if (normalized.isEmpty) return null;

    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(normalized);
    if (match == null) return null;

    final year = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final day = int.tryParse(match.group(3)!);
    if (year == null || month == null || day == null) return null;

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }
}
