import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef PendingOperationsSync = Future<int> Function();
typedef CurrentUserIdProvider = String? Function();
typedef BackendAvailabilityCheck = Future<bool> Function();

/// Re-triggers the existing pending-operation reconciliation at connectivity
/// and app-resume boundaries. It does not own, rewrite, or acknowledge queue
/// entries; the economic coordinator remains the source of truth for that.
class PendingOperationsReconnectCoordinator with WidgetsBindingObserver {
  PendingOperationsReconnectCoordinator({
    required PendingOperationsSync syncPendingOperations,
    required CurrentUserIdProvider currentUserIdProvider,
    required BackendAvailabilityCheck backendAvailabilityCheck,
    Stream<List<ConnectivityResult>> Function()? connectivityStreamProvider,
    Duration retryCooldown = const Duration(seconds: 30),
    Duration availabilityTimeout = const Duration(seconds: 8),
  })  : _syncPendingOperations = syncPendingOperations,
        _currentUserIdProvider = currentUserIdProvider,
        _backendAvailabilityCheck = backendAvailabilityCheck,
        _connectivityStreamProvider = connectivityStreamProvider ??
            (() => Connectivity().onConnectivityChanged),
        _retryCooldown = retryCooldown,
        _availabilityTimeout = availabilityTimeout;

  final PendingOperationsSync _syncPendingOperations;
  final CurrentUserIdProvider _currentUserIdProvider;
  final BackendAvailabilityCheck _backendAvailabilityCheck;
  final Stream<List<ConnectivityResult>> Function() _connectivityStreamProvider;
  final Duration _retryCooldown;
  final Duration _availabilityTimeout;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Future<int>? _inFlight;
  DateTime? _cooldownUntil;
  bool _started = false;
  bool _disposed = false;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription =
        _connectivityStreamProvider().listen(_onConnectivityChanged);
  }

  Future<int> syncNow({String reason = 'manual'}) {
    if (_disposed) return Future<int>.value(0);
    final existing = _inFlight;
    if (existing != null) return existing;

    final userId = _normalizedUserId(_currentUserIdProvider());
    if (userId == null) return Future<int>.value(0);

    final cooldownUntil = _cooldownUntil;
    if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil)) {
      return Future<int>.value(0);
    }

    late final Future<int> attempt;
    attempt = _runAttempt(userId: userId, reason: reason).whenComplete(() {
      if (identical(_inFlight, attempt)) _inFlight = null;
    });
    _inFlight = attempt;
    return attempt;
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_isOffline(results)) return;
    unawaited(syncNow(reason: 'connectivity_restored'));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(syncNow(reason: 'app_resumed'));
    }
  }

  Future<int> _runAttempt(
      {required String userId, required String reason}) async {
    try {
      final backendAvailable = await _backendAvailabilityCheck()
          .timeout(_availabilityTimeout, onTimeout: () => false);
      if (!backendAvailable ||
          _normalizedUserId(_currentUserIdProvider()) != userId) {
        _cooldownUntil = DateTime.now().add(_retryCooldown);
        return 0;
      }
      final resolved = await _syncPendingOperations();
      if (_normalizedUserId(_currentUserIdProvider()) != userId) {
        return 0;
      }
      // The existing best-effort sync intentionally does not expose whether
      // a transient RPC failed. Cool down every completed attempt so a noisy
      // connectivity stream cannot spin requests while the backend is down.
      _cooldownUntil = DateTime.now().add(_retryCooldown);
      if (kDebugMode) {
        debugPrint(
          '[pending_sync] trigger=$reason user=$userId resolved=$resolved',
        );
      }
      return resolved;
    } catch (error) {
      _cooldownUntil = DateTime.now().add(_retryCooldown);
      if (kDebugMode) {
        debugPrint('[pending_sync] trigger=$reason unavailable: $error');
      }
      return 0;
    }
  }

  static bool _isOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        (results.length == 1 && results.first == ConnectivityResult.none);
  }

  static String? _normalizedUserId(String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }
}
