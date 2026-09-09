enum PasswordRecoveryState {
  passwordRecoveryRequested,
  awaitingPasswordRecoveryCallback,
  passwordRecoverySessionReady,
  updatingPassword,
  passwordUpdated,
  failure,
}

/// AUTH-4D owns this flow. AUTH-4A only defines its stable state vocabulary.
class PasswordRecoverySnapshot {
  const PasswordRecoverySnapshot(this.state, {this.failure});

  final PasswordRecoveryState state;
  final Object? failure;
}
