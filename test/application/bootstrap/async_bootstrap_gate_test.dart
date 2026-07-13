import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/application/bootstrap/async_bootstrap_gate.dart';

Widget _app(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  testWidgets('shows splash while bootstrap is initializing and hides Home',
      (tester) async {
    final completer = Completer<String>();

    await tester.pumpWidget(
      _app(
        AsyncBootstrapGate<String>(
          initializer: (_) => completer.future,
          minimumInitializationDuration: Duration.zero,
          initializingBuilder: (_) => const Text('Splash'),
          readyBuilder: (_, value) => Text('Home $value'),
          failedBuilder: (_, error, stackTrace) => const Text('Failed'),
        ),
      ),
    );

    expect(find.text('Splash'), findsOneWidget);
    expect(find.textContaining('Home'), findsNothing);

    completer.complete('Ready');
    await tester.pump();
    await tester.pump();

    expect(find.text('Splash'), findsNothing);
    expect(find.text('Home Ready'), findsOneWidget);
  });

  testWidgets('keeps splash visible until minimum duration completes',
      (tester) async {
    final completer = Completer<String>();

    await tester.pumpWidget(
      _app(
        AsyncBootstrapGate<String>(
          initializer: (_) => completer.future,
          minimumInitializationDuration: const Duration(milliseconds: 500),
          initializingBuilder: (_) => const Text('Splash'),
          readyBuilder: (_, value) => Text('Home $value'),
          failedBuilder: (_, error, stackTrace) => const Text('Failed'),
        ),
      ),
    );

    completer.complete('Ready');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Splash'), findsOneWidget);
    expect(find.textContaining('Home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Splash'), findsNothing);
    expect(find.text('Home Ready'), findsOneWidget);
  });

  testWidgets(
      'minimum duration does not add extra wait when bootstrap is slower',
      (tester) async {
    final completer = Completer<String>();

    await tester.pumpWidget(
      _app(
        AsyncBootstrapGate<String>(
          initializer: (_) => completer.future,
          minimumInitializationDuration: const Duration(milliseconds: 200),
          initializingBuilder: (_) => const Text('Splash'),
          readyBuilder: (_, value) => Text('Home $value'),
          failedBuilder: (_, error, stackTrace) => const Text('Failed'),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 350));
    completer.complete('Ready');
    await tester.pumpAndSettle();

    expect(find.text('Splash'), findsNothing);
    expect(find.text('Home Ready'), findsOneWidget);
  });

  testWidgets('renders failed builder when bootstrap throws', (tester) async {
    await tester.pumpWidget(
      _app(
        AsyncBootstrapGate<String>(
          initializer: (_) async => throw StateError('boom'),
          minimumInitializationDuration: Duration.zero,
          initializingBuilder: (_) => const Text('Splash'),
          readyBuilder: (_, value) => Text('Home $value'),
          failedBuilder: (_, error, stackTrace) => const Text('Failed'),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Splash'), findsNothing);
    expect(find.text('Failed'), findsOneWidget);
    expect(find.textContaining('Home'), findsNothing);
  });
}
