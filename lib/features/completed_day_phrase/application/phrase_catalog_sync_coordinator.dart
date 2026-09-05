import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../data/phrase_catalog_repository.dart';

class PhraseCatalogSyncCoordinator extends WidgetsBindingObserver {
  PhraseCatalogSyncCoordinator({
    required PhraseCatalogRepository repository,
    required String? Function() currentUserIdProvider,
    required String Function() localeProvider,
    required ({String? userId, int epoch})? Function() scopeProvider,
    DateTime Function()? nowProvider,
    Duration minRefreshInterval = const Duration(seconds: 30),
  })  : _repository = repository,
        _currentUserIdProvider = currentUserIdProvider,
        _localeProvider = localeProvider,
        _scopeProvider = scopeProvider,
        _nowProvider = nowProvider ?? DateTime.now,
        _minRefreshInterval = minRefreshInterval {
    WidgetsBinding.instance.addObserver(this);
  }

  final PhraseCatalogRepository _repository;
  final String? Function() _currentUserIdProvider;
  final String Function() _localeProvider;
  final ({String? userId, int epoch})? Function() _scopeProvider;
  final DateTime Function() _nowProvider;
  final Duration _minRefreshInterval;

  Future<void>? _inFlight;
  DateTime? _lastAttemptAt;
  bool _disposed = false;

  Future<void> syncAfterBootstrap({
    required String userId,
    required String scopeUserId,
    required int scopeEpoch,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty ||
        !_isCurrentScope(normalizedUserId, scopeUserId, scopeEpoch)) {
      return;
    }
    await _sync(
      expectedUserId: normalizedUserId,
      expectedScopeUserId: scopeUserId,
      expectedScopeEpoch: scopeEpoch,
      force: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _disposed) return;
    final userId = _normalize(_currentUserIdProvider());
    final scope = _scopeProvider();
    if (userId == null || scope?.userId == null) return;
    final scopeUserId = _normalize(scope!.userId);
    if (scopeUserId == null) return;
    unawaited(_sync(
      expectedUserId: userId,
      expectedScopeUserId: scopeUserId,
      expectedScopeEpoch: scope.epoch,
      force: false,
    ));
  }

  Future<void> _sync({
    required String expectedUserId,
    required String expectedScopeUserId,
    required int expectedScopeEpoch,
    required bool force,
  }) {
    final active = _inFlight;
    if (active != null) return active;
    final now = _nowProvider();
    if (!force &&
        _lastAttemptAt != null &&
        now.difference(_lastAttemptAt!) < _minRefreshInterval) {
      return Future<void>.value();
    }
    _lastAttemptAt = now;
    late final Future<void> operation;
    operation = _runSync(
      expectedUserId: expectedUserId,
      expectedScopeUserId: expectedScopeUserId,
      expectedScopeEpoch: expectedScopeEpoch,
    ).whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    _inFlight = operation;
    return operation;
  }

  Future<void> _runSync({
    required String expectedUserId,
    required String expectedScopeUserId,
    required int expectedScopeEpoch,
  }) async {
    if (!_isCurrentScope(
        expectedUserId, expectedScopeUserId, expectedScopeEpoch)) {
      return;
    }
    try {
      await _repository.sync(_localeProvider());
      if (!_isCurrentScope(
        expectedUserId,
        expectedScopeUserId,
        expectedScopeEpoch,
      )) {
        _log('sync_discarded scope_changed');
      }
    } catch (error) {
      // The local repository remains the source of truth when remote sync fails.
      _log('sync_failed type=${error.runtimeType}');
    }
  }

  bool _isCurrentScope(String userId, String scopeUserId, int scopeEpoch) {
    final currentUserId = _normalize(_currentUserIdProvider());
    final currentScope = _scopeProvider();
    return !_disposed &&
        currentUserId == userId &&
        _normalize(currentScope?.userId) == scopeUserId &&
        currentScope?.epoch == scopeEpoch;
  }

  String? _normalize(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[COMPLETED_DAY_PHRASE] $message');
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
  }
}
