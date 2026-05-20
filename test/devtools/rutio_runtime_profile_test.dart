import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/devtools/rutio_runtime_profile.dart';

void main() {
  group('RutioRuntimeProfile', () {
    test('default is non-demo when no values are provided', () {
      final profile = RutioRuntimeProfile.parse();

      expect(profile.isDemoProfile, isFalse);
      expect(profile.shouldResetDemoProfile, isFalse);
    });

    test('RUTIO_PROFILE=demo activates demo mode', () {
      final profile = RutioRuntimeProfile.parse(profileValue: 'demo');

      expect(profile.isDemoProfile, isTrue);
      expect(profile.shouldResetDemoProfile, isFalse);
    });

    test('RUTIO_RESET_DEMO=true is parsed correctly', () {
      final profile = RutioRuntimeProfile.parse(
        profileValue: 'demo',
        resetDemoValue: 'true',
      );

      expect(profile.isDemoProfile, isTrue);
      expect(profile.shouldResetDemoProfile, isTrue);
    });
  });
}
