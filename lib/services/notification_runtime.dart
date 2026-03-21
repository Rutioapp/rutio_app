import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    _scheduleSync(recordAppOpen: true);
  }

  @override
  Widget build(BuildContext context) => widget.child;

  void _bootstrapIfPossible() {
    final store = _store;
    if (store == null ||
        store.isLoading ||
        store.state == null ||
        _bootstrapped) {
      return;
    }

    _bootstrapped = true;
    _previousState = _cloneState(store.state!);
    _scheduleSync(recordAppOpen: true);
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
      final queuedPreviousState = _queuedPreviousState;
      final queuedRecordOpen = _queuedRecordOpen;
      _queuedPreviousState = null;
      _queuedRecordOpen = false;

      try {
        await NotificationService.instance.syncPhaseOne(
          store: store,
          previousState: queuedPreviousState,
          recordAppOpen: queuedRecordOpen,
        );
      } catch (error) {
        logNotification('Notification sync error: $error');
      }
    });
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
