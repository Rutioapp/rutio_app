import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/screens/home/widgets/habit/habit_card_swipe_shell.dart';

void main() {
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
