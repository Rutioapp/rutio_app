import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/auth/sign_in_screen.dart';

void main() {
  test('pending onboarding login returns to the onboarding flow', () {
    expect(
      signInShouldReturnToOnboarding(
        const <String, Object>{'returnToOnboarding': true},
      ),
      isTrue,
    );
  });

  test('ordinary login keeps the normal bootstrap navigation', () {
    expect(signInShouldReturnToOnboarding(null), isFalse);
    expect(
      signInShouldReturnToOnboarding(
        const <String, Object>{'returnToOnboarding': false},
      ),
      isFalse,
    );
  });
}
