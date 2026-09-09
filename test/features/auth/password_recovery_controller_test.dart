import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/features/auth/application/password_recovery_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('request uses the repository once and returns generic sent state',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final events = StreamController<AuthState>.broadcast();
    var calls = 0;
    final repository = AuthRepository(
      authStateChangesProvider: () => events.stream,
      currentUserProvider: () => null,
      resetPasswordForEmailProvider: ({required email}) async => calls++,
    );
    final controller = PasswordRecoveryController(repository);

    expect(await controller.requestReset('person@example.com'), isTrue);
    expect(calls, 1);
    expect(controller.phase, PasswordRecoveryPhase.resetEmailSent);

    controller.dispose();
    await events.close();
  });

  test('uses the same password minimum as signup', () {
    expect(PasswordRecoveryController.isValidPassword('12345'), isFalse);
    expect(PasswordRecoveryController.isValidPassword('123456'), isTrue);
  });
}
