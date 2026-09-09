enum AuthCallbackFailureType {
  malformedCallback,
  unsupportedCallback,
  expiredOrInvalidCallback,
  callbackAccountMismatch,
  callbackProcessingFailed,
}

class AuthCallbackFailure implements Exception {
  const AuthCallbackFailure(this.type, {this.cause});

  final AuthCallbackFailureType type;
  final Object? cause;

  @override
  String toString() => 'AuthCallbackFailure.${type.name}';
}
