import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';

void main() {
  group('HabitCardSwipeMotionConfig', () {
    const config = HabitCardSwipeMotionConfig();

    test('applies direct offset inside normal limits', () {
      expect(
        config.applyDragDelta(
          currentOffset: 10,
          delta: 30,
          canSwipeRightComplete: true,
        ),
        40,
      );
      expect(
        config.applyDragDelta(
          currentOffset: -30,
          delta: -50,
          canSwipeRightComplete: true,
        ),
        -80,
      );
    });

    test('applies resistance only after the limits', () {
      expect(
        config.applyDragDelta(
          currentOffset: 80,
          delta: 4,
          canSwipeRightComplete: true,
        ),
        84,
      );
      expect(
        config.applyDragDelta(
          currentOffset: 84,
          delta: 20,
          canSwipeRightComplete: true,
        ),
        greaterThan(84),
      );
      expect(
        config.applyDragDelta(
          currentOffset: -234,
          delta: -20,
          canSwipeRightComplete: true,
        ),
        lessThan(-234),
      );
    });

    test('resolves targets with current thresholds', () {
      expect(
        config.resolveSettleTarget(
          offset: 54,
          velocityX: 0,
          startedFromOpenTray: false,
          canSwipeRightComplete: true,
          hasRightCompleteCallback: true,
        ),
        HabitCardSwipeSettleTarget.rightCommit,
      );
      expect(
        config.resolveSettleTarget(
          offset: -72,
          velocityX: 0,
          startedFromOpenTray: false,
          canSwipeRightComplete: true,
          hasRightCompleteCallback: true,
        ),
        HabitCardSwipeSettleTarget.leftOpen,
      );
      expect(
        config.resolveSettleTarget(
          offset: -12,
          velocityX: 0,
          startedFromOpenTray: false,
          canSwipeRightComplete: true,
          hasRightCompleteCallback: true,
        ),
        HabitCardSwipeSettleTarget.closed,
      );
    });

    test('normalizes progress', () {
      expect(config.progressForOffset(42, 84), 0.5);
      expect(config.progressForOffset(-4, 84), 0);
      expect(config.progressForOffset(120, 84), 1);
    });

    test('defines the expected visual states', () {
      expect(HabitCardSwipeVisualState.values, [
        HabitCardSwipeVisualState.idle,
        HabitCardSwipeVisualState.dragging,
        HabitCardSwipeVisualState.settlingClosed,
        HabitCardSwipeVisualState.settlingLeftOpen,
        HabitCardSwipeVisualState.committingRight,
        HabitCardSwipeVisualState.actionInFlight,
      ]);
    });
  });

  testWidgets('renders the three left actions in the current order',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(isOpen: true),
      ),
    );

    expect(find.text('Saltar'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(_centerX(tester, 'Saltar') < _centerX(tester, 'Editar'), isTrue);
    expect(_centerX(tester, 'Editar') < _centerX(tester, 'Eliminar'), isTrue);
  });

  testWidgets('each left action executes its callback once per tap',
      (tester) async {
    var skipCalls = 0;
    var editCalls = 0;
    var deleteCalls = 0;

    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onSkip: () async => skipCalls += 1,
          onEdit: () => editCalls += 1,
          onDelete: () async => deleteCalls += 1,
        ),
      ),
    );

    await tester.tap(find.text('Saltar'));
    await tester.pump();
    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.tap(find.text('Eliminar'));
    await tester.pump();

    expect(skipCalls, 1);
    expect(editCalls, 1);
    expect(deleteCalls, 1);
  });

  testWidgets('opening requests the correct card id', (tester) async {
    final requestedIds = <String>[];

    await tester.pumpWidget(
      _testApp(
        _shell(
          cardId: 'habit-42',
          onRequestOpen: requestedIds.add,
        ),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(-90, 0));
    await tester.pump();

    expect(requestedIds, isNotEmpty);
    expect(requestedIds.toSet(), {'habit-42'});
  });

  testWidgets('closing requests clearing the open card', (tester) async {
    var closeCalls = 0;

    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onRequestClose: () => closeCalls += 1,
        ),
      ),
    );

    await tester.tapAt(const Offset(40, 50));
    await tester.pump();

    expect(closeCalls, 1);
  });

  testWidgets('an open card shows the current action rail', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(isOpen: true),
      ),
    );

    expect(find.byIcon(CupertinoIcons.forward_end_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.delete), findsOneWidget);
  });

  testWidgets('right swipe keeps the current completion callback',
      (tester) async {
    var completeCalls = 0;

    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(160, 0));
    await tester.pump();

    expect(completeCalls, 1);
  });

  testWidgets('horizontal drag moves the card proportionally to the gesture',
      (tester) async {
    await tester.pumpWidget(
      _testApp(_shell(onSwipeRightComplete: () async {})),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(40, 0.1));

    await gesture.up();
  });

  testWidgets('left then right in one gesture keeps offset continuity',
      (tester) async {
    await tester.pumpWidget(
      _testApp(_shell(onSwipeRightComplete: () async {})),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(-80, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(-80, 0.1));

    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(40, 0.1));

    await gesture.up();
  });

  testWidgets('right then left in one gesture keeps offset continuity',
      (tester) async {
    await tester.pumpWidget(
      _testApp(_shell(onSwipeRightComplete: () async {})),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(60, 0.1));

    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(-30, 0.1));

    await gesture.up();
  });

  testWidgets('short drag settles back to closed', (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    await tester.drag(find.byKey(_childKey), const Offset(-30, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), isNot(0));

    await tester.pumpAndSettle();
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
  });

  testWidgets('sufficient left drag opens the action rail', (tester) async {
    final openedIds = <String>[];
    await tester.pumpWidget(
      _testApp(
        _shell(
          onRequestOpen: openedIds.add,
        ),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(-90, 0));
    await tester.pumpAndSettle();

    expect(openedIds, isNotEmpty);
    expect(_cardOffsetX(tester), closeTo(-234, 0.1));
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('completion callback is not executed during drag update',
      (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(completeCalls, 0);

    await gesture.up();
    await tester.pump();
    expect(completeCalls, 1);
  });

  testWidgets('new drag during settling starts from current visual offset',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    await tester.drag(find.byKey(_childKey), const Offset(-90, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final settlingOffset = _cardOffsetX(tester);
    expect(settlingOffset, lessThan(-90));
    expect(settlingOffset, greaterThan(-234));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(settlingOffset + 20, 1.0));

    await gesture.up();
  });

  testWidgets('left actions remain fixed under the moving card',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell(isOpen: true)));

    final before = tester.getCenter(find.text('Saltar')).dx;
    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    final after = tester.getCenter(find.text('Saltar')).dx;

    expect(after, closeTo(before, 0.1));

    await gesture.up();
  });

  testWidgets('two quick async action taps execute once while pending',
      (tester) async {
    var skipCalls = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onSkip: () {
            skipCalls += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Saltar'));
    await tester.pump();
    await tester.tap(find.text('Saltar'), warnIfMissed: false);
    await tester.pump();

    expect(skipCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('two quick right commits execute once while pending',
      (tester) async {
    var completeCalls = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () {
            completeCalls += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(90, 0));
    await tester.pump();
    await tester.drag(find.byKey(_childKey), const Offset(90, 0));
    await tester.pump();

    expect(completeCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('guard is released after the async action future completes',
      (tester) async {
    var skipCalls = 0;
    var completer = Completer<void>();

    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onSkip: () {
            skipCalls += 1;
            return completer.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(skipCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    completer = Completer<void>();
    await tester.tap(find.text('Saltar'));
    await tester.pump();
    expect(skipCalls, 2);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('keeps the HabitCardWidget content as a single child',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(
          child: const SizedBox(
            key: _habitCardLikeChildKey,
            width: 360,
            height: 96,
            child: Text('Habit child'),
          ),
        ),
      ),
    );

    expect(find.byKey(_habitCardLikeChildKey), findsOneWidget);
    expect(find.text('Habit child'), findsOneWidget);
  });

  testWidgets('preserves action labels and icon semantics', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          skipLabel: 'Skip',
          editLabel: 'Edit',
          deleteLabel: 'Delete',
        ),
      ),
    );

    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.forward_end_fill), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.pencil), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.delete), findsOneWidget);
  });
}

const _childKey = Key('habit-card-swipe-shell-child');
const _habitCardLikeChildKey = Key('habit-card-like-child');

Widget _testApp(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
}

HabitCardSwipeShell _shell({
  String cardId = 'habit-1',
  bool isOpen = false,
  bool compact = false,
  bool canSwipeRightComplete = true,
  String skipLabel = 'Saltar',
  String editLabel = 'Editar',
  String deleteLabel = 'Eliminar',
  void Function(String cardId)? onRequestCloseOtherCards,
  void Function(String cardId)? onRequestOpen,
  VoidCallback? onRequestClose,
  Future<void> Function()? onSwipeRightComplete,
  Future<void> Function()? onSkip,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
  Widget? child,
}) {
  return HabitCardSwipeShell(
    cardId: cardId,
    isOpen: isOpen,
    compact: compact,
    canSwipeRightComplete: canSwipeRightComplete,
    skipLabel: skipLabel,
    editLabel: editLabel,
    deleteLabel: deleteLabel,
    onRequestCloseOtherCards: onRequestCloseOtherCards ?? (_) {},
    onRequestOpen: onRequestOpen ?? (_) {},
    onRequestClose: onRequestClose ?? () {},
    onSwipeRightComplete: onSwipeRightComplete,
    onSkip: onSkip ?? () async {},
    onEdit: onEdit,
    onDelete: onDelete ?? () async {},
    child: child ??
        Container(
          key: _childKey,
          width: 360,
          height: 96,
          color: Colors.white,
          alignment: Alignment.center,
          child: const Text('Habit child'),
        ),
  );
}

double _centerX(WidgetTester tester, String label) {
  return tester.getCenter(find.text(label)).dx;
}

double _cardOffsetX(WidgetTester tester) {
  final transformFinder = find.ancestor(
    of: find.byKey(_childKey),
    matching: find.byType(Transform),
  );
  final transform = tester.widget<Transform>(transformFinder.first);
  return transform.transform.getTranslation().x;
}
