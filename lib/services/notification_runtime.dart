import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/notifications/application/personalized_notification_orchestrator.dart';
import '../stores/user_state_store.dart';
import 'notification_service.dart';
import 'notification_types.dart';

class NotificationRuntime extends StatefulWidget {
  const NotificationRuntime({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<NotificationRuntime> createState() => _NotificationRuntimeState();
}

class _NotificationRuntimeState extends State<NotificationRuntime>
    with WidgetsBindingObserver {
  UserStateStore? _store;
  Timer? _syncDebounce;
  JsonMap? _previousState;
  JsonMap? _queuedPreviousState;
  bool _queuedRecordOpen = false;
  bool _bootstrapped = false;

  void _startupLog(String message) {
    if (kDebugMode) debugPrint(message);
  }

  @override
  void initState() {
    super.initState();
    _startupLog('[STARTUP] 20 NotificationRuntime.initState()');
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startupLog('[STARTUP] 21 NotificationRuntime.didChangeDependencies()');
    final store = context.read<UserStateStore>();
    if (identical(_store, store)) {
      _bootstrapIfPossible();
      return;
    }

    _store?.removeListener(_handleStoreChanged);
    _store = store;
    _store?.addListener(_handleStoreChanged);
    _bootstrapIfPossible();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncDebounce?.cancel();
    _store?.removeListener(_handleStoreChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_bootstrapped) return;
    _startupLog('[STARTUP] 22 NotificationRuntime lifecycle resumed');
    _scheduleSync(recordAppOpen: true);
    _schedulePersonalizedSync();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _bootstrapIfPossible() {
    final store = _store;
    if (store == null ||
        store.isLoading ||
        store.state == null ||
        _bootstrapped) {
      _startupLog(
        '[STARTUP] 23 NotificationRuntime bootstrap skipped '
        '(storeReady=${store != null && !store.isLoading && store.state != null}, '
        'bootstrapped=$_bootstrapped)',
      );
      return;
    }

    _startupLog('[STARTUP] 24 NotificationRuntime bootstrap start');
    _bootstrapped = true;
    _previousState = _cloneState(store.state!);
    _scheduleSync(recordAppOpen: true);
    _startupLog(
      '[STARTUP] 25 NotificationRuntime bootstrap scheduled phase-one sync',
    );
  }

  void _handleStoreChanged() {
    final store = _store;
    if (store == null || store.isLoading || store.state == null) return;

    if (!_bootstrapped) {
      _bootstrapIfPossible();
      return;
    }

    final previousState = _previousState;
    _previousState = _cloneState(store.state!);
    _scheduleSync(previousState: previousState);
  }

  void _scheduleSync({
    JsonMap? previousState,
    bool recordAppOpen = false,
  }) {
    final store = _store;
    if (store == null || store.state == null) return;

    _queuedPreviousState ??= previousState;
    _queuedRecordOpen = _queuedRecordOpen || recordAppOpen;

    _syncDebounce?.cancel();
    _syncDebounce = Timer(const Duration(milliseconds: 250), () async {
      _startupLog('[STARTUP] 26 NotificationRuntime phase-one sync fired');
      final queuedPreviousState = _queuedPreviousState;
      final queuedRecordOpen = _queuedRecordOpen;
      _queuedPreviousState = null;
      _queuedRecordOpen = false;

      try {
        _startupLog('[STARTUP] 27 before NotificationService.syncPhaseOne()');
        await NotificationService.instance.syncPhaseOne(
          store: store,
          previousState: queuedPreviousState,
          recordAppOpen: queuedRecordOpen,
        );
        _startupLog('[STARTUP] 28 after NotificationService.syncPhaseOne()');
      } catch (error) {
        logNotification('Notification sync error: $error');
      }
    });
  }

  void _schedulePersonalizedSync() {
    final store = _store;
    if (store == null || store.state == null) return;

    unawaited(
      () async {
        try {
          _startupLog(
            '[STARTUP] 29 before PersonalizedNotificationOrchestrator.reconcileForForeground()',
          );
          await context
              .read<PersonalizedNotificationOrchestrator>()
              .reconcileForForeground();
          _startupLog(
            '[STARTUP] 30 after PersonalizedNotificationOrchestrator.reconcileForForeground()',
          );
        } catch (error) {
          logNotification(
            'Personalized notification foreground sync error: $error',
          );
        }
      }(),
    );
  }

  JsonMap _cloneState(Map<String, dynamic> state) {
    final encoded = jsonEncode(state);
    final decoded = jsonDecode(encoded);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }
}
