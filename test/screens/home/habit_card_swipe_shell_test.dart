import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_status_feedback.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';

void main() {
  group('HabitCardSwipeMotionConfig', () {
    const config = HabitCardSwipeMotionConfig();

    test('applies direct offset inside normal limits', () {
      expect(
        config.applyDragDelta(
          currentOffset: 10,
          delta: 30,
          cardWidth: 360,
          canSwipeRightComplete: true,
        ),
        40,
      );
      expect(
        config.applyDragDelta(
          currentOffset: -30,
          delta: -50,
          cardWidth: 360,
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
          cardWidth: 360,
          canSwipeRightComplete: true,
        ),
        84,
      );
      expect(
        config.applyDragDelta(
          currentOffset: 216,
          delta: 20,
          cardWidth: 360,
          canSwipeRightComplete: true,
        ),
        greaterThan(216),
      );
      expect(
        config.applyDragDelta(
          currentOffset: -234,
          delta: -20,
          cardWidth: 360,
          canSwipeRightComplete: true,
        ),
        lessThan(-234),
      );
    });

    test('clamps positive offset to zero when right completion is disabled',
        () {
      expect(
        config.applyDragDelta(
          currentOffset: 0,
          delta: 120,
          cardWidth: 360,
          canSwipeRightComplete: false,
        ),
        0,
      );
      expect(
        config.applyDragDelta(
          currentOffset: -40,
          delta: 80,
          cardWidth: 360,
          canSwipeRightComplete: false,
        ),
        0,
      );
    });

    test('resolves targets with current thresholds', () {
      expect(_destination(offset: 179), HabitCardSwipeDestination.closed);
      expect(_destination(offset: 180), HabitCardSwipeDestination.rightCommit);
      expect(
        _destination(offset: 30, velocity: 700),
        HabitCardSwipeDestination.rightCommit,
      );
      expect(
        _destination(offset: -106),
        HabitCardSwipeDestination.leftOpen,
      );
      expect(_destination(offset: -12), HabitCardSwipeDestination.closed);
      expect(
        _destination(offset: 180, velocity: -700),
        HabitCardSwipeDestination.rightCommit,
      );
      expect(
        _destination(offset: 30, velocity: -700),
        HabitCardSwipeDestination.closed,
      );
      expect(
        _destination(offset: -20, velocity: -700),
        HabitCardSwipeDestination.leftOpen,
      );
      expect(
        _destination(offset: 30, velocity: 700, startedOpen: true),
        HabitCardSwipeDestination.closed,
      );
    });

    test('normalizes progress', () {
      expect(config.progressForOffset(108, 216), 0.5);
      expect(config.progressForOffset(-4, 216), 0);
      expect(config.progressForOffset(240, 216), 1);
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

    test('defines exact closed and leftOpen targets', () {
      expect(config.closedOffset, 0);
      expect(config.openOffset, -config.leftActionsExtent);
      expect(config.openOffset, -234);
    });

    test('keeps phase 3 thresholds and resistance intact', () {
      expect(config.leftActionsExtent, 234);
      expect(config.leftOpenThresholdFraction, 0.45);
      expect(config.rightCommitThresholdFraction, 0.50);
      expect(config.rightFlickVelocity, 700);
      expect(config.leftFlickVelocity, 700);
      expect(config.overdragResistance, 0.20);
      expect(config.rightVisualLimitFraction, 0.60);
      expect(config.rightRevealExtent(360), config.rightCommitThreshold(360));
    });

    test('centralizes spring parameters', () {
      expect(config.springMass, 1.0);
      expect(config.springStiffness, 480.0);
      expect(config.springDamping, 42.0);
      expect(config.springToleranceDistance, greaterThan(0));
      expect(config.springToleranceVelocity, greaterThan(0));
      expect(config.springDescription.mass, config.springMass);
      expect(config.springDescription.stiffness, config.springStiffness);
      expect(config.springDescription.damping, config.springDamping);
    });

    test('passes initial velocity direction and magnitude to the spring', () {
      final positive = config.springSimulation(
        start: 120,
        target: config.closedOffset,
        velocity: 900,
      );
      final negative = config.springSimulation(
        start: -120,
        target: config.openOffset,
        velocity: -850,
      );

      expect(positive.x(0), 120);
      expect(positive.dx(0), closeTo(900, 0.1));
      expect(negative.x(0), -120);
      expect(negative.dx(0), closeTo(-850, 0.1));
    });

    test('spring creation does not modify destination decisions', () {
      const offset = 30.0;
      const velocity = 700.0;
      final before = _destination(offset: offset, velocity: velocity);

      config.springSimulation(
        start: offset,
        target: config.closedOffset,
        velocity: velocity,
      );

      final after = _destination(offset: offset, velocity: velocity);
      expect(after, before);
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

    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.forward_end_fill),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.pencil),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.delete),
      ),
      findsOneWidget,
    );
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

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(190, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump();

    expect(completeCalls, 1);
  });

  testWidgets('horizontal drag moves the card proportionally to the gesture',
      (tester) async {
    await tester.pumpWidget(
      _testApp(_shell(onSwipeRightComplete: () async {})),
    );

    final gesture = await tester.startGesture(_visibleCardPoint());
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

  testWidgets('short drag to closed does not execute completion callback',
      (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(90, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(completeCalls, 0);
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
  });

  testWidgets('right overdrag reduces only the excess after the limit',
      (tester) async {
    await tester.pumpWidget(
      _testApp(_shell(onSwipeRightComplete: () async {})),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(260, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(224.8, 0.1));

    await gesture.up();
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

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-130, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(openedIds, isNotEmpty);
    expect(_cardOffsetX(tester), closeTo(-234, 0.1));
    expect(find.text('Saltar'), findsOneWidget);
  });

  testWidgets('leftOpen settling target is exactly negative action extent',
      (tester) async {
    const config = HabitCardSwipeMotionConfig();

    await tester.pumpWidget(_testApp(_shell(motionConfig: config)));

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-130, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(_cardOffsetX(tester), closeTo(config.openOffset, 0.1));
    expect(_cardOffsetX(tester), closeTo(-config.leftActionsExtent, 0.1));
  });

  testWidgets('leftOpen settling does not execute completion callback',
      (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-130, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(completeCalls, 0);
    expect(_cardOffsetX(tester), closeTo(-234, 0.1));
  });

  testWidgets('release velocity affects spring evolution for the same target',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));
    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-110, 0),
      const Duration(milliseconds: 800),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final slowOffset = _cardOffsetX(tester);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(_testApp(_shell()));
    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-110, 0),
      const Duration(milliseconds: 100),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final fastOffset = _cardOffsetX(tester);

    expect(fastOffset, lessThan(slowOffset));
  });

  testWidgets('right drag below the 50 percent threshold closes',
      (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(160, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(completeCalls, 0);
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
  });

  testWidgets('right drag is inert when right completion is disabled',
      (tester) async {
    HabitCardRightCommitVisualState? reportedVisualState;
    var completeCalls = 0;

    await tester.pumpWidget(
      _testApp(
        _shell(
          canSwipeRightComplete: false,
          onSwipeRightCompleteWithVisualState: (visualState) async {
            reportedVisualState = visualState;
            completeCalls += 1;
          },
        ),
      ),
    );

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(0, 0.1));
    expect(find.byKey(const Key('habitCardRightCommitFeedback')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(completeCalls, 0);
    expect(reportedVisualState, isNull);
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
  });

  testWidgets('right drag above the 50 percent threshold completes once',
      (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(190, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();

    expect(completeCalls, 1);
  });

  testWidgets('right commit reports the exact visual offset to Home',
      (tester) async {
    HabitCardRightCommitVisualState? reportedVisualState;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightCompleteWithVisualState: (visualState) async {
            reportedVisualState = visualState;
          },
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(190, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pump();

    expect(reportedVisualState, isNotNull);
    expect(reportedVisualState!.offsetX, closeTo(190, 1.0));
    expect(reportedVisualState!.cardWidth, closeTo(360, 0.1));
    expect(reportedVisualState!.commitProgress, greaterThanOrEqualTo(1));
    expect(reportedVisualState!.rightRevealProgress, greaterThanOrEqualTo(1));
  });

  testWidgets('completed feedback is mounted under the foreground and reveals',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(onSwipeRightComplete: () async {}),
      ),
    );

    expect(
        find.byKey(const Key('habitCardRightCommitFeedback')), findsOneWidget);
    expect(_rightFeedbackIconOpacity(tester), 0);
    final feedbackLeft = tester
        .getTopLeft(find.byKey(const Key('habitCardRightCommitFeedback')))
        .dx;
    final initialIconCenter = tester.getCenter(
      find.descendant(
        of: find.byKey(const Key('habitCardRightCommitFeedback')),
        matching: find.byKey(const Key('habitCardStatusFeedbackIcon')),
      ),
    );
    final feedbackCenter =
        tester.getCenter(find.byKey(const Key('habitCardRightCommitFeedback')));
    expect(
      initialIconCenter.dx,
      closeTo(
        feedbackLeft +
            HabitCardStatusFeedbackMotionConfig.statusIconHorizontalInset +
            16,
        0.1,
      ),
    );
    expect(initialIconCenter.dx, lessThan(feedbackCenter.dx));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump();
    final partialOpacity = _rightFeedbackIconOpacity(tester);
    expect(partialOpacity, greaterThan(0));
    expect(partialOpacity, lessThan(1));
    expect(_cardOffsetX(tester), closeTo(50, 0.1));
    expect(
      tester
          .getTopLeft(find.byKey(const Key('habitCardRightCommitFeedback')))
          .dx,
      closeTo(feedbackLeft, 0.1),
    );
    expect(
      tester
          .getCenter(
            find.descendant(
              of: find.byKey(const Key('habitCardRightCommitFeedback')),
              matching: find.byKey(const Key('habitCardStatusFeedbackIcon')),
            ),
          )
          .dx,
      closeTo(initialIconCenter.dx, 0.1),
    );

    await gesture.moveBy(const Offset(90, 0));
    await tester.pump();
    expect(_rightFeedbackIconOpacity(tester), greaterThan(partialOpacity));
    expect(_rightFeedbackIconOpacity(tester), closeTo(1, 0.01));

    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
    expect(_rightFeedbackIconOpacity(tester), 0);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('left swipe does not reveal completed feedback', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(onSwipeRightComplete: () async {}),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(-120, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), lessThan(0));
    expect(_rightFeedbackIconOpacity(tester), 0);
  });

  testWidgets(
      'left drag shows only the white action rail, not skipped feedback',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    expect(find.byKey(const Key('habitCardLeftSkipFeedback')), findsNothing);

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();
    expect(find.byKey(const Key('habitCardLeftSkipFeedback')), findsNothing);
    expect(find.byKey(const Key('habitCardLeftSkipFeedbackIconOpacity')),
        findsNothing);
    expect(find.text('Saltar'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);
    expect(_rightFeedbackIconOpacity(tester), 0);
    expect(_cardOffsetX(tester), closeTo(-60, 0.1));

    await gesture.moveBy(const Offset(-120, 0));
    await tester.pump();
    expect(find.byKey(const Key('habitCardLeftSkipFeedback')), findsNothing);
    expect(_cardOffsetX(tester), closeTo(-180, 0.1));

    await gesture.moveBy(const Offset(180, 0));
    await tester.pump();
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
    expect(find.byKey(const Key('habitCardLeftSkipFeedback')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('right swipe does not reveal skipped feedback', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _shell(onSwipeRightComplete: () async {}),
      ),
    );

    await tester.drag(find.byKey(_childKey), const Offset(120, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), greaterThan(0));
    expect(_leftSkipFeedbackIconOpacity(tester), 0);
  });

  testWidgets('edit and delete do not execute skip transition callback',
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

    await tester.tap(find.text('Editar'));
    await tester.pump();
    await tester.tap(find.text('Eliminar'));
    await tester.pump();

    expect(skipCalls, 0);
    expect(editCalls, 1);
    expect(deleteCalls, 1);
  });

  testWidgets('emoji moves with the foreground and feedback has no emoji',
      (tester) async {
    const emojiKey = Key('foregroundEmoji');
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async {},
          child: Container(
            key: _childKey,
            width: 360,
            height: 96,
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: const Text('💧', key: emojiKey),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('habitCardRightCommitFeedback')),
        matching: find.text('💧'),
      ),
      findsNothing,
    );
    final initialEmojiLeft = tester.getTopLeft(find.byKey(emojiKey)).dx;

    await tester.drag(find.byKey(_childKey), const Offset(80, 0));
    await tester.pump();

    expect(
      tester.getTopLeft(find.byKey(emojiKey)).dx,
      closeTo(initialEmojiLeft + 80, 1),
    );
  });

  testWidgets('right commit does not settle the card back to center',
      (tester) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () => completer.future,
        ),
      ),
    );

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(190, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    final commitOffset = _cardOffsetX(tester);

    await tester.pump(const Duration(milliseconds: 120));
    expect(_cardOffsetX(tester), closeTo(commitOffset, 0.1));
    expect(_cardOffsetX(tester), greaterThan(0));

    completer.complete();
    await tester.pump();
  });

  testWidgets('right flick completes with shorter travel', (tester) async {
    var completeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          onSwipeRightComplete: () async => completeCalls += 1,
        ),
      ),
    );

    await tester.fling(find.byKey(_childKey), const Offset(70, 0), 900);
    await tester.pump();

    expect(completeCalls, 1);
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
    await gesture.moveBy(const Offset(190, 0));
    await tester.pump();

    expect(completeCalls, 0);

    await gesture.up();
    await tester.pump();
    expect(completeCalls, 1);
  });

  testWidgets('new drag during settling starts from current visual offset',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-130, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final settlingOffset = _cardOffsetX(tester);
    expect(settlingOffset, lessThan(-90));
    expect(settlingOffset, greaterThan(-234));

    final gesture = await tester.startGesture(_visibleCardPoint());
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(settlingOffset + 20, 1.0));

    await gesture.up();
  });

  testWidgets('new drag interrupts settlingClosed from the visible offset',
      (tester) async {
    await tester
        .pumpWidget(_testApp(_shell(onSwipeRightComplete: () async {})));

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(150, 0),
      const Duration(milliseconds: 700),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    final settlingOffset = _cardOffsetX(tester);
    expect(settlingOffset, greaterThan(0));
    expect(settlingOffset, lessThan(150));

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(_childKey)));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();

    expect(_cardOffsetX(tester), closeTo(settlingOffset - 20, 1.0));

    await gesture.up();
  });

  testWidgets('new drag interrupts settlingLeftOpen from the visible offset',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    await tester.timedDrag(
      find.byKey(_childKey),
      const Offset(-130, 0),
      const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
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

  testWidgets('left actions remain fixed while the spring is settling',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell(isOpen: true)));

    final before = tester.getCenter(find.text('Saltar')).dx;

    await tester.timedDragFrom(
      _visibleCardPoint(),
      const Offset(180, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final after = tester.getCenter(find.text('Saltar')).dx;
    expect(after, closeTo(before, 0.1));
  });

  testWidgets('opened card can close from its current position',
      (tester) async {
    var closeCalls = 0;
    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onRequestClose: () => closeCalls += 1,
        ),
      ),
    );

    expect(_cardOffsetX(tester), closeTo(-234, 0.1));

    await tester.dragFrom(_visibleCardPoint(), const Offset(180, 0));
    await tester.pumpAndSettle();

    expect(closeCalls, greaterThanOrEqualTo(1));
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
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

  testWidgets('skip action reports the open rail visual state before callback',
      (tester) async {
    HabitCardSkipVisualState? reportedVisualState;
    var skipCalls = 0;

    await tester.pumpWidget(
      _testApp(
        _shell(
          isOpen: true,
          onSkipWithVisualState: (visualState) async {
            reportedVisualState = visualState;
            skipCalls += 1;
          },
        ),
      ),
    );

    await tester.tap(find.text('Saltar'));
    await tester.pump();

    expect(skipCalls, 1);
    expect(reportedVisualState, isNotNull);
    expect(reportedVisualState!.offsetX, closeTo(-234, 0.1));
    expect(reportedVisualState!.cardWidth, closeTo(360, 0.1));
    expect(reportedVisualState!.revealProgress, closeTo(1, 0.01));
    expect(reportedVisualState!.leftRevealProgress, closeTo(1, 0.01));
    expect(_cardOffsetX(tester), closeTo(-234, 0.1));
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

  testWidgets('external isOpen owner synchronizes the visual offset',
      (tester) async {
    var isOpen = false;

    Widget buildHarness() {
      return _testApp(
        _shell(
          isOpen: isOpen,
          onRequestOpen: (_) => isOpen = true,
          onRequestClose: () => isOpen = false,
        ),
      );
    }

    await tester.pumpWidget(buildHarness());
    expect(_cardOffsetX(tester), closeTo(0, 0.1));

    isOpen = true;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    expect(_cardOffsetX(tester), closeTo(-234, 0.1));

    isOpen = false;
    await tester.pumpWidget(buildHarness());
    await tester.pumpAndSettle();
    expect(_cardOffsetX(tester), closeTo(0, 0.1));
  });

  testWidgets('does not use AnimatedContainer for horizontal position',
      (tester) async {
    await tester.pumpWidget(_testApp(_shell()));

    expect(
      find.descendant(
        of: find.byType(HabitCardSwipeShell),
        matching: find.byType(AnimatedContainer),
      ),
      findsNothing,
    );
    expect(find.byType(Transform), findsWidgets);
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
    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.forward_end_fill),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.pencil),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byIcon(CupertinoIcons.delete),
      ),
      findsOneWidget,
    );
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
          child: SizedBox(width: 360, child: child),
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
  Future<void> Function(HabitCardRightCommitVisualState visualState)?
      onSwipeRightCompleteWithVisualState,
  Future<void> Function()? onSkip,
  Future<void> Function(HabitCardSkipVisualState visualState)?
      onSkipWithVisualState,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
  HabitCardSwipeMotionConfig motionConfig = const HabitCardSwipeMotionConfig(),
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
    onSwipeRightComplete: onSwipeRightCompleteWithVisualState ??
        (onSwipeRightComplete == null
            ? null
            : (_) => onSwipeRightComplete.call()),
    onSkip: onSkipWithVisualState ??
        (visualState) async {
          await onSkip?.call();
        },
    onEdit: onEdit,
    onDelete: onDelete ?? () async {},
    motionConfig: motionConfig,
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

Offset _visibleCardPoint() => const Offset(80, 64);

HabitCardSwipeDestination _destination({
  required double offset,
  double velocity = 0,
  bool startedOpen = false,
}) {
  const config = HabitCardSwipeMotionConfig();
  return resolveSwipeDestination(
    offset: offset,
    velocity: velocity,
    cardWidth: 360,
    leftActionsExtent: config.leftActionsExtent,
    startedOpen: startedOpen,
    canSwipeRightComplete: true,
    hasRightCompleteCallback: true,
    config: config,
  );
}

double _cardOffsetX(WidgetTester tester) {
  final transformFinder = find.ancestor(
    of: find.byKey(_childKey),
    matching: find.byType(Transform),
  );
  final transform = tester.widget<Transform>(transformFinder.first);
  return transform.transform.getTranslation().x;
}

double _rightFeedbackIconOpacity(WidgetTester tester) {
  final finder =
      find.byKey(const Key('habitCardRightCommitFeedbackIconOpacity'));
  if (finder.evaluate().isEmpty) return 0;
  final opacity = tester.widget<Opacity>(
    finder,
  );
  return opacity.opacity;
}

double _leftSkipFeedbackIconOpacity(WidgetTester tester) {
  final finder = find.byKey(const Key('habitCardLeftSkipFeedbackIconOpacity'));
  if (finder.evaluate().isEmpty) return 0;
  final opacity = tester.widget<Opacity>(
    finder,
  );
  return opacity.opacity;
}
