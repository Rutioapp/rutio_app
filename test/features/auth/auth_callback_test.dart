import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/auth/application/auth_callback_classifier.dart';
import 'package:rutio/features/auth/application/auth_callback_coordinator.dart';
import 'package:rutio/features/auth/domain/auth_callback_failure.dart';
import 'package:rutio/features/auth/domain/auth_callback_type.dart';

void main() {
  const callback = 'https://rutioapp.com/auth/callback';

  test('classifies confirmation without retaining secrets', () {
    final result = const AuthCallbackClassifier().classify(Uri.parse(
      '$callback?type=signup&code=secret-code#access_token=secret-token',
    ));
    expect(result, isA<AuthCallbackEmailConfirmation>());
    final intent = (result as AuthCallbackEmailConfirmation).intent;
    expect(intent.type, AuthCallbackType.emailConfirmation);
    expect(intent.safeParameters, {'type': 'confirmation'});
    expect(intent.toString(), isNot(contains('secret')));
  });

  test('classifies recovery and rejects unsupported hosts', () {
    final result = const AuthCallbackClassifier().classify(
      Uri.parse('$callback?type=recovery&token_hash=secret'),
    );
    expect(result, isA<AuthCallbackPasswordRecovery>());
    expect(
      const AuthCallbackClassifier().classify(
        Uri.parse('https://evil.example/auth/callback?type=recovery'),
      ),
      isA<AuthCallbackUnsupported>(),
    );
  });

  test('coordinator converges cold/open and deduplicates', () async {
    final calls = <bool>[];
    final coordinator = AuthCallbackCoordinator(
      sessionPort: _SessionPort(calls),
    );
    final cold = await coordinator.receive(
      Uri.parse('$callback?type=signup'),
      isColdStart: true,
    );
    final duplicate = await coordinator.receive(
      Uri.parse('$callback?type=signup'),
      isColdStart: false,
    );
    expect(cold.kind, AuthCallbackResultKind.completed);
    expect(duplicate.kind, AuthCallbackResultKind.duplicateIgnored);
    expect(calls, [true]);
    expect(coordinator.pendingColdStart, isNull);
  });

  test('malformed and unsupported are typed', () async {
    final coordinator = AuthCallbackCoordinator(sessionPort: _SessionPort([]));
    expect(
      (await coordinator.receive(Uri(), isColdStart: false)).failure?.type,
      AuthCallbackFailureType.malformedCallback,
    );
    expect(
      (await coordinator.receive(Uri.parse('https://example.com/'),
              isColdStart: false))
          .failure
          ?.type,
      AuthCallbackFailureType.unsupportedCallback,
    );
  });
}

class _SessionPort implements AuthCallbackSessionPort {
  _SessionPort(this.calls);
  final List<bool> calls;

  @override
  Future<AuthCallbackSessionResult> processCallback(intent) async {
    calls.add(intent.isColdStart);
    return const AuthCallbackSessionResult(userId: 'user-a', hasSession: true);
  }
}
