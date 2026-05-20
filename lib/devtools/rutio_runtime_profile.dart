class RutioRuntimeProfile {
  const RutioRuntimeProfile._({
    required this.profileName,
    required this.resetDemoRequested,
  });

  static const String profileEnvKey = 'RUTIO_PROFILE';
  static const String resetDemoEnvKey = 'RUTIO_RESET_DEMO';
  static const String demoProfileName = 'demo';

  final String profileName;
  final bool resetDemoRequested;

  bool get isDemoProfile => profileName == demoProfileName;
  bool get shouldResetDemoProfile => isDemoProfile && resetDemoRequested;

  static final RutioRuntimeProfile current = parse(
    profileValue: const String.fromEnvironment(profileEnvKey),
    resetDemoValue: const String.fromEnvironment(resetDemoEnvKey),
  );

  static bool get isDemo => current.isDemoProfile;

  static bool get shouldResetDemo => current.shouldResetDemoProfile;

  static RutioRuntimeProfile parse({
    String? profileValue,
    String? resetDemoValue,
  }) {
    final normalizedProfile = (profileValue ?? '').trim().toLowerCase();
    final normalizedReset = (resetDemoValue ?? '').trim().toLowerCase();

    return RutioRuntimeProfile._(
      profileName: normalizedProfile.isEmpty ? 'default' : normalizedProfile,
      resetDemoRequested: _isTrue(normalizedReset),
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
}
