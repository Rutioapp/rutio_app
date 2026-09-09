import '../domain/auth_callback_failure.dart';
import '../domain/auth_callback_intent.dart';
import 'auth_callback_classifier.dart';

abstract interface class AuthCallbackSessionPort {
  Future<AuthCallbackSessionResult> processCallback(AuthCallbackIntent intent);
}

class AuthCallbackSessionResult {
  const AuthCallbackSessionResult({this.userId, this.hasSession = false});
  final String? userId;
  final bool hasSession;
}

abstract interface class OnboardingAuthOwnership {
  String? get activeOnboardingOperationId;
  void acquireOnboardingAuthOwnership(String operationId);
  void releaseOnboardingAuthOwnership(String operationId);
}

abstract interface class OnboardingAuthCallbackConsumer {
  Future<void> onCallbackSession(String userId);
}

enum AuthCallbackResultKind {
  completed,
  queued,
  duplicateIgnored,
  unsupported,
  malformed,
  failed
}

class AuthCallbackResult {
  const AuthCallbackResult(this.kind, {this.failure, this.intent});
  final AuthCallbackResultKind kind;
  final AuthCallbackFailure? failure;
  final AuthCallbackIntent? intent;
}

/// Single application entry point for cold-start and in-app callbacks.
class AuthCallbackCoordinator {
  AuthCallbackCoordinator({
    AuthCallbackClassifier? classifier,
    required AuthCallbackSessionPort sessionPort,
    OnboardingAuthOwnership? ownership,
    OnboardingAuthCallbackConsumer? onboardingConsumer,
    String? Function()? expectedUserIdProvider,
    DateTime Function()? now,
    Duration deduplicationWindow = const Duration(minutes: 2),
  })  : _classifier = classifier ?? const AuthCallbackClassifier(),
        _sessionPort = sessionPort,
        _ownership = ownership,
        _onboardingConsumer = onboardingConsumer,
        _expectedUserIdProvider = expectedUserIdProvider,
        _now = now ?? DateTime.now,
        _deduplicationWindow = deduplicationWindow;

  final AuthCallbackClassifier _classifier;
  final AuthCallbackSessionPort _sessionPort;
  final OnboardingAuthOwnership? _ownership;
  final OnboardingAuthCallbackConsumer? _onboardingConsumer;
  final String? Function()? _expectedUserIdProvider;
  final DateTime Function() _now;
  final Duration _deduplicationWindow;
  final Map<String, DateTime> _seen = <String, DateTime>{};
  final Map<String, Future<AuthCallbackResult>> _inFlight =
      <String, Future<AuthCallbackResult>>{};
  AuthCallbackIntent? _pendingColdStart;

  AuthCallbackIntent? get pendingColdStart => _pendingColdStart;

  Future<AuthCallbackResult> receive(Uri uri, {required bool isColdStart}) {
    final classification =
        _classifier.classify(uri, isColdStart: isColdStart, receivedAt: _now());
    if (classification is AuthCallbackMalformed) {
      return Future.value(const AuthCallbackResult(
          AuthCallbackResultKind.malformed,
          failure:
              AuthCallbackFailure(AuthCallbackFailureType.malformedCallback)));
    }
    if (classification is AuthCallbackUnsupported) {
      return Future.value(const AuthCallbackResult(
          AuthCallbackResultKind.unsupported,
          failure: AuthCallbackFailure(
              AuthCallbackFailureType.unsupportedCallback)));
    }
    final intent = classification is AuthCallbackEmailConfirmation
        ? classification.intent
        : (classification as AuthCallbackPasswordRecovery).intent;
    if (isColdStart) _pendingColdStart = intent;
    final key =
        '${intent.type.name}|${intent.scheme}|${intent.host}|${intent.path}';
    final now = _now().toUtc();
    _seen.removeWhere(
        (_, timestamp) => now.difference(timestamp) > _deduplicationWindow);
    if (_seen.containsKey(key)) {
      return Future.value(AuthCallbackResult(
          AuthCallbackResultKind.duplicateIgnored,
          intent: intent));
    }
    _seen[key] = now;
    final existing = _inFlight[key];
    if (existing != null) return existing;
    late final Future<AuthCallbackResult> future;
    future = _process(key, intent).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  Future<AuthCallbackResult> _process(
      String key, AuthCallbackIntent intent) async {
    try {
      final session = await _sessionPort.processCallback(intent);
      final userId = session.userId?.trim();
      final expectedUserId = _expectedUserIdProvider?.call()?.trim();
      if (session.hasSession &&
          expectedUserId != null &&
          expectedUserId.isNotEmpty &&
          userId != expectedUserId) {
        return AuthCallbackResult(
          AuthCallbackResultKind.failed,
          intent: intent,
          failure: const AuthCallbackFailure(
            AuthCallbackFailureType.callbackAccountMismatch,
          ),
        );
      }
      final operationId = _ownership?.activeOnboardingOperationId;
      if (session.hasSession &&
          userId != null &&
          userId.isNotEmpty &&
          operationId != null) {
        _ownership!.acquireOnboardingAuthOwnership(operationId);
        await _onboardingConsumer?.onCallbackSession(userId);
      }
      if (identical(_pendingColdStart, intent)) _pendingColdStart = null;
      return AuthCallbackResult(AuthCallbackResultKind.completed,
          intent: intent);
    } catch (error) {
      return AuthCallbackResult(AuthCallbackResultKind.failed,
          intent: intent,
          failure: AuthCallbackFailure(
              AuthCallbackFailureType.callbackProcessingFailed,
              cause: error));
    }
  }
}
