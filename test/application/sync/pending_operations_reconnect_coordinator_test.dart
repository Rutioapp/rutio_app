import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:rutio/application/sync/pending_operations_reconnect_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reconnect checks backend and syncs pending operations', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    var backendChecks = 0;
    var syncCalls = 0;
    final coordinator = PendingOperationsReconnectCoordinator(
      connectivityStreamProvider: () => connectivity.stream,
      currentUserIdProvider: () => 'user-1',
      backendAvailabilityCheck: () async {
        backendChecks += 1;
        return true;
      },
      syncPendingOperations: () async {
        syncCalls += 1;
        return 1;
      },
    )..start();
    addTearDown(() async {
      await coordinator.dispose();
      await connectivity.close();
    });

    connectivity.add(const [ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(backendChecks, 1);
    expect(syncCalls, 1);
  });

  test('concurrent reconnect events share one sync attempt', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    final backend = Completer<bool>();
    var syncCalls = 0;
    final coordinator = PendingOperationsReconnectCoordinator(
      connectivityStreamProvider: () => connectivity.stream,
      currentUserIdProvider: () => 'user-1',
      backendAvailabilityCheck: () => backend.future,
      syncPendingOperations: () async {
        syncCalls += 1;
        return 1;
      },
    )..start();
    addTearDown(() async {
      await coordinator.dispose();
      await connectivity.close();
    });

    connectivity.add(const [ConnectivityResult.wifi]);
    connectivity.add(const [ConnectivityResult.mobile]);
    await Future<void>.delayed(Duration.zero);
    backend.complete(true);
    await Future<void>.delayed(Duration.zero);

    expect(syncCalls, 1);
  });

  test('backend outage is cooled down and retried on foreground', () async {
    final connectivity = StreamController<List<ConnectivityResult>>();
    var available = false;
    var checks = 0;
    var syncCalls = 0;
    final coordinator = PendingOperationsReconnectCoordinator(
      connectivityStreamProvider: () => connectivity.stream,
      currentUserIdProvider: () => 'user-1',
      retryCooldown: const Duration(milliseconds: 10),
      backendAvailabilityCheck: () async {
        checks += 1;
        return available;
      },
      syncPendingOperations: () async {
        syncCalls += 1;
        return 1;
      },
    )..start();
    addTearDown(() async {
      await coordinator.dispose();
      await connectivity.close();
    });

    connectivity.add(const [ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    connectivity.add(const [ConnectivityResult.wifi]);
    await Future<void>.delayed(Duration.zero);
    expect(checks, 1);
    expect(syncCalls, 0);

    available = true;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(checks, 2);
    expect(syncCalls, 1);
  });
}
