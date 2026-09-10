import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rutio/data/repositories/auth_repository.dart';
import 'package:rutio/features/auth/infrastructure/google_auth_adapter.dart';

void main() {
  test('repository delegates Google exchange to the single auth adapter', () async {
    var calls = 0;
    final adapter = _FakeGoogleAdapter(() async {
      calls++;
      return AuthResponse();
    });
    final repository = AuthRepository(
      googleAuthAdapter: adapter,
      authStateChangesProvider: () => const Stream<AuthState>.empty(),
      currentUserProvider: () => null,
    );

    final response = await repository.signInWithGoogle();

    expect(response.session, isNull);
    expect(calls, 1);
  });

  test('Google adapter errors remain typed for cancellation', () async {
    final adapter = _FakeGoogleAdapter(() async {
      throw const GoogleAuthException(GoogleAuthErrorCode.cancelled);
    });
    final repository = AuthRepository(
      googleAuthAdapter: adapter,
      authStateChangesProvider: () => const Stream<AuthState>.empty(),
      currentUserProvider: () => null,
    );

    expect(
      repository.signInWithGoogle,
      throwsA(
        isA<GoogleAuthException>().having(
          (error) => error.code,
          'code',
          GoogleAuthErrorCode.cancelled,
        ),
      ),
    );
  });
}

class _FakeGoogleAdapter implements GoogleAuthAdapter {
  _FakeGoogleAdapter(this._signIn);
  final Future<AuthResponse> Function() _signIn;

  @override
  Future<AuthResponse> signIn() => _signIn();

  @override
  Future<void> signOut() async {}
}
