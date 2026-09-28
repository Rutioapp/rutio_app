import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/widgets/loading/rutio_loading_screen.dart';
import 'package:rutio/widgets/shared_widgets.dart';

Widget _host(Widget child) {
  return MaterialApp(home: child);
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Offset _sunTranslation(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(find.byType(Transform));
  expect(transforms.length, greaterThanOrEqualTo(2));
  final matrix = transforms.first.transform;
  return Offset(matrix.storage[12], matrix.storage[13]);
}

void main() {
  testWidgets('slow work reaches waiting without a generic spinner',
      (tester) async {
    await tester.pumpWidget(_host(const RutioLoadingScreen()));
    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.text('Preparando mi Rutio'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Todo listo'), findsNothing);
  });

  testWidgets('keeps the onboarding sun visible throughout the journey',
      (tester) async {
    Finder sunPainter() => find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is SunPainter,
        );

    await tester.pumpWidget(_host(const RutioLoadingScreen()));
    await tester.pump();
    expect(sunPainter(), findsOneWidget);
    expect(find.byType(RutioSun), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    expect(sunPainter(), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1800));
    expect(sunPainter(), findsOneWidget);
  });

  testWidgets('first visible sun frame starts at the exact left endpoint',
      (tester) async {
    await tester.pumpWidget(_host(const RutioLoadingScreen()));
    expect(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is SunPainter,
      ),
      findsNothing,
    );
    await tester.pump();

    final size = tester.getSize(find.byType(Scaffold));
    final sunSize = math.min(size.shortestSide * 0.29, 126.0);
    final expected = rutioLoadingSunPosition(
          size,
          0,
          sunSize: sunSize,
        ) -
        Offset(sunSize / 2, sunSize / 2);

    expect(_sunTranslation(tester).dx, closeTo(expected.dx, 0.001));
    expect(_sunTranslation(tester).dy, closeTo(expected.dy, 0.001));
  });

  testWidgets('rebuilding the parent does not restart the journey',
      (tester) async {
    await tester.pumpWidget(_host(const RutioLoadingScreen()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    final beforeRebuild = _sunTranslation(tester);

    await tester.pumpWidget(_host(const RutioLoadingScreen()));
    final afterRebuild = _sunTranslation(tester);
    final size = tester.getSize(find.byType(Scaffold));
    final sunSize = math.min(size.shortestSide * 0.29, 126.0);
    final start = rutioLoadingSunPosition(
          size,
          0,
          sunSize: sunSize,
        ) -
        Offset(sunSize / 2, sunSize / 2);

    expect(beforeRebuild.dx, greaterThan(start.dx));
    expect(afterRebuild.dx, greaterThan(start.dx));
    expect(afterRebuild.dx, greaterThanOrEqualTo(beforeRebuild.dx));
  });

  testWidgets('completed work finishes the journey and shows Todo listo',
      (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(RutioLoadingScreen(
      isOperationComplete: true,
      initialProgress: 0.88,
      minimumVisibleDuration: Duration.zero,
      onCompleted: () => completions++,
    )));

    await _pumpUntilFound(tester, find.text('Todo listo'));
    expect(find.text('Todo listo'), findsOneWidget);
    expect(completions, 0);

    await tester.pump(const Duration(milliseconds: 800));
    expect(completions, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(completions, 1);
  });

  testWidgets('error stops completion and keeps retry in the external flow',
      (tester) async {
    var completions = 0;
    var retries = 0;
    await tester.pumpWidget(_host(RutioLoadingScreen(
      isOperationComplete: true,
      errorMessage: 'No se pudo preparar Rutio',
      onRetry: () => retries++,
      onCompleted: () => completions++,
    )));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('No se pudo preparar Rutio'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(completions, 0);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('dispose cancels the completion callback', (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(RutioLoadingScreen(
      isOperationComplete: true,
      initialProgress: 0.88,
      minimumVisibleDuration: Duration.zero,
      onCompleted: () => completions++,
    )));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpWidget(_host(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 2));

    expect(completions, 0);
  });

  testWidgets('fast bootstrap respects the visual minimum before completing',
      (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(RutioLoadingScreen(
      isOperationComplete: true,
      initialProgress: 0.88,
      onCompleted: () => completions++,
    )));

    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('Preparando mi Rutio'), findsOneWidget);
    expect(find.text('Todo listo'), findsNothing);
    expect(completions, 0);

    await _pumpUntilFound(tester, find.text('Todo listo'));
    expect(find.text('Todo listo'), findsOneWidget);
    expect(completions, 0);
  });

  testWidgets('waiting to completing keeps the same journey endpoint',
      (tester) async {
    var completions = 0;
    await tester.pumpWidget(_host(RutioLoadingScreen(
      initialProgress: 0.88,
      onCompleted: () => completions++,
    )));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(_host(RutioLoadingScreen(
      initialProgress: 0.88,
      isOperationComplete: true,
      minimumVisibleDuration: Duration.zero,
      onCompleted: () => completions++,
    )));
    await _pumpUntilFound(tester, find.text('Todo listo'));

    expect(find.text('Todo listo'), findsOneWidget);
    expect(completions, 0);
  });

  test('loading sun follows a continuous 0 to 180 degree semi-ellipse', () {
    const size = Size(400, 800);
    const sunSize = 100.0;
    final start = rutioLoadingSunPosition(size, 0, sunSize: sunSize);
    final middle = rutioLoadingSunPosition(size, 0.5, sunSize: sunSize);
    final end = rutioLoadingSunPosition(size, 1, sunSize: sunSize);
    final fractional = rutioLoadingSunPosition(size, 0.123, sunSize: sunSize);

    expect(start.dx, closeTo(62, 0.001));
    expect(start.dy, closeTo(544, 0.001));
    expect(middle.dx, closeTo(200, 0.001));
    expect(middle.dy, closeTo(320, 0.001));
    expect(end.dx, closeTo(338, 0.001));
    expect(end.dy, closeTo(start.dy, 0.001));
    expect(start.dx, lessThan(middle.dx));
    expect(middle.dx, lessThan(end.dx));
    expect(middle.dy, lessThan(start.dy));
    expect(fractional.dx, isNot(closeTo(start.dx, 0.001)));
    expect(fractional.dy, isNot(closeTo(start.dy, 0.001)));
  });

  test('sun bounds remain inside the horizontal canvas at both endpoints', () {
    const size = Size(400, 800);
    const sunSize = 100.0;
    final start = rutioLoadingSunPosition(size, 0, sunSize: sunSize);
    final end = rutioLoadingSunPosition(size, 1, sunSize: sunSize);

    expect(start.dx - sunSize / 2, greaterThanOrEqualTo(12));
    expect(end.dx + sunSize / 2, lessThanOrEqualTo(size.width - 12));
  });

  test('sun horizontal position is strictly monotonic across the journey', () {
    const size = Size(400, 800);
    const sunSize = 100.0;
    const progressValues = [
      0.0,
      0.1,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.8,
      0.9,
      1.0,
    ];
    final positions = progressValues
        .map((progress) =>
            rutioLoadingSunPosition(size, progress, sunSize: sunSize))
        .toList();

    for (var index = 0; index < positions.length - 1; index++) {
      expect(positions[index + 1].dx, greaterThan(positions[index].dx));
    }
    expect(positions.first.dy, closeTo(positions.last.dy, 0.001));
    expect(positions[5].dy, lessThan(positions.first.dy));
  });
}
