import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('main manifest disables Android app-data backup explicitly', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, isNot(contains('android:dataExtractionRules=')));
    expect(manifest, isNot(contains('android:fullBackupContent=')));
  });

  test('debug and profile manifests do not override backup policy', () {
    for (final path in <String>[
      'android/app/src/debug/AndroidManifest.xml',
      'android/app/src/profile/AndroidManifest.xml',
    ]) {
      final manifest = File(path).readAsStringSync();
      expect(manifest, isNot(contains('android:allowBackup=')));
      expect(manifest, isNot(contains('android:dataExtractionRules=')));
      expect(manifest, isNot(contains('android:fullBackupContent=')));
    }
  });
}
