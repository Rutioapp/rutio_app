import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/diagnostics/onboarding_runtime_trace.dart';
import '../../../data/repositories/auth_repository.dart';
import '../domain/auth_callback_failure.dart';
import 'auth_callback_coordinator.dart';

enum PasswordRecoveryPhase {
  idle,
  requestingReset,
  resetEmailSent,
  awaitingCallback,
  recoverySessionReady,
  updatingPassword,
  passwordUpdated,
  failure,
}

enum PasswordRecoveryFailureType {
  network,
  rateLimit,
  invalidEmail,
  recoveryLinkInvalid,
  updatePasswordFailed,
  unexpected,
}

class PasswordRecoveryFailure {
  const PasswordRecoveryFailure(this.type);
  final PasswordRecoveryFailureType type;
}

class PasswordRecoveryController extends ChangeNotifier {
  PasswordRecoveryController(this._repository,
      {this.onCallbackResult, SharedPreferences? preferences})
      : _preferences = preferences {
    _subscription = _repository.authStateChanges.listen(_onAuthState);
    unawaited(_restoreMarker());
  }

  static const int passwordMinimumLength = 6;
  static const _markerKey = 'password_recovery_in_progress_v1';

  final AuthRepository _repository;
  final SharedPreferences? _preferences;
  final void Function(Object result)? onCallbackResult;
  StreamSubscription<AuthState>? _subscription;
  PasswordRecoveryPhase _phase = PasswordRecoveryPhase.idle;
  PasswordRecoveryFailure? _failure;
  bool _disposed = false;
  DateTime? _lastRequestAt;

  PasswordRecoveryPhase get phase => _phase;
  PasswordRecoveryFailure? get failure => _failure;
  bool get isLoading =>
      _phase == PasswordRecoveryPhase.requestingReset ||
      _phase == PasswordRecoveryPhase.updatingPassword;
  bool get hasActiveRecovery =>
      _phase == PasswordRecoveryPhase.recoverySessionReady ||
      _phase == PasswordRecoveryPhase.updatingPassword ||
      _phase == PasswordRecoveryPhase.passwordUpdated;
  bool get isAwaitingCallback =>
      _phase == PasswordRecoveryPhase.awaitingCallback;
  bool get isRecoveryPending =>
      _phase != PasswordRecoveryPhase.idle ||
      (_preferences?.getBool(_markerKey) ?? false);
  bool get isInvalidLink =>
      _failure?.type == PasswordRecoveryFailureType.recoveryLinkInvalid;
  bool get canRequestAgain =>
      _lastRequestAt == null ||
      DateTime.now().difference(_lastRequestAt!) >= const Duration(seconds: 60);

  static bool isValidPassword(String password) =>
      password.length >= passwordMinimumLength;

  Future<bool> requestReset(String email) async {
    final normalized = email.trim();
    if (!_isValidEmail(normalized)) {
      _fail(const PasswordRecoveryFailure(
          PasswordRecoveryFailureType.invalidEmail));
      return false;
    }
    if (!canRequestAgain) return false;
    _lastRequestAt = DateTime.now();
    _set(PasswordRecoveryPhase.requestingReset);
    _log('request_started', result: 'pending');
    try {
      await _repository.resetPasswordForEmail(email: normalized);
      _set(PasswordRecoveryPhase.resetEmailSent);
      await _persist(true);
      _log('request_succeeded', result: 'accepted');
      return true;
    } on AuthException catch (error) {
      _fail(_mapFailure(error));
      return false;
    } catch (_) {
      _fail(const PasswordRecoveryFailure(PasswordRecoveryFailureType.network));
      return false;
    }
  }

  Future<bool> updatePassword(String password, String confirmation) async {
    if (!hasActiveRecovery) return false;
    if (!isValidPassword(password) || password != confirmation) {
      _fail(const PasswordRecoveryFailure(
          PasswordRecoveryFailureType.updatePasswordFailed));
      return false;
    }
    _set(PasswordRecoveryPhase.updatingPassword);
    _log('password_update_started', result: 'pending');
    try {
      await _repository.updatePassword(password: password);
      _set(PasswordRecoveryPhase.passwordUpdated);
      await _persist(false);
      _log('password_update_succeeded', result: 'success');
      return true;
    } on AuthException catch (error) {
      _fail(_mapFailure(error, update: true));
      return false;
    } catch (_) {
      _fail(const PasswordRecoveryFailure(
          PasswordRecoveryFailureType.updatePasswordFailed));
      return false;
    }
  }

  void handleCallbackResult(Object result) {
    if (result is AuthCallbackResult &&
        result.intent?.type.name == 'passwordRecovery' &&
        result.kind == AuthCallbackResultKind.completed) {
      _log('callback_received', result: 'accepted');
    }
    if (result is AuthCallbackResult &&
        result.failure?.type ==
            AuthCallbackFailureType.expiredOrInvalidCallback) {
      _failure = const PasswordRecoveryFailure(
        PasswordRecoveryFailureType.recoveryLinkInvalid,
      );
      _set(PasswordRecoveryPhase.failure);
      _log('callback_received', result: 'invalid');
    }
    onCallbackResult?.call(result);
  }

  Future<void> cancelRecovery({Future<void> Function()? signOut}) async {
    await _persist(false);
    _set(PasswordRecoveryPhase.idle);
    _log('cancelled', result: 'success');
    if (signOut != null) await signOut();
  }

  Future<void> clear() async {
    await _persist(false);
    _set(PasswordRecoveryPhase.idle);
    _log('recovery_cleared', result: 'success');
  }

  void _onAuthState(AuthState state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      _set(PasswordRecoveryPhase.recoverySessionReady);
      unawaited(_persist(true));
      _log('recovery_session_ready',
          hasSession: state.session != null, result: 'success');
    } else if (state.event == AuthChangeEvent.signedOut) {
      unawaited(clear());
    } else if (state.event == AuthChangeEvent.initialSession &&
        state.session != null &&
        _phase == PasswordRecoveryPhase.idle) {
      unawaited(_restoreMarker());
    }
  }

  Future<void> _restoreMarker() async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    if (_disposed ||
        prefs.getBool(_markerKey) != true ||
        _repository.currentUser == null) {
      return;
    }
    _set(PasswordRecoveryPhase.recoverySessionReady);
    _log('recovery_session_ready', hasSession: true, result: 'restored');
  }

  Future<void> _persist(bool value) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    await prefs.setBool(_markerKey, value);
  }

  void _set(PasswordRecoveryPhase phase) {
    if (_disposed) return;
    _phase = phase;
    if (phase != PasswordRecoveryPhase.failure) _failure = null;
    notifyListeners();
  }

  void _fail(PasswordRecoveryFailure failure) {
    _failure = failure;
    _set(PasswordRecoveryPhase.failure);
    _log('request_failed', result: failure.type.name);
  }

  PasswordRecoveryFailure _mapFailure(AuthException error,
      {bool update = false}) {
    final text = error.message.toLowerCase();
    if (text.contains('rate') || error.statusCode == '429') {
      return const PasswordRecoveryFailure(
          PasswordRecoveryFailureType.rateLimit);
    }
    if (text.contains('invalid') || text.contains('email')) {
      return PasswordRecoveryFailure(update
          ? PasswordRecoveryFailureType.updatePasswordFailed
          : PasswordRecoveryFailureType.invalidEmail);
    }
    if (text.contains('expired') ||
        text.contains('otp') ||
        text.contains('link')) {
      return const PasswordRecoveryFailure(
          PasswordRecoveryFailureType.recoveryLinkInvalid);
    }
    return PasswordRecoveryFailure(update
        ? PasswordRecoveryFailureType.updatePasswordFailed
        : PasswordRecoveryFailureType.network);
  }

  bool _isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);

  void _log(String event, {bool? hasSession, required String result}) {
    OnboardingRuntimeTrace.log('PASSWORD_RECOVERY',
        'event=$event hasSession=${hasSession ?? _repository.currentUser != null} result=$result');
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
