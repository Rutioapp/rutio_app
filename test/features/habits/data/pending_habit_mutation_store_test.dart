import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/core/storage/pending_queue_storage.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  PendingHabitMutation createMutation({
    String operationId = 'op-create',
    String userId = 'user-a',
    PendingHabitMutationType type = PendingHabitMutationType.create,
    int revision = 0,
    int attempts = 0,
    bool uncertain = false,
    Map<String, dynamic>? snapshot,
    Map<String, dynamic>? createSnapshot,
  }) {
    return PendingHabitMutation(
      operationId: operationId,
      userId: userId,
      localHabitId: 'habit-1',
      remoteHabitId: '550e8400-e29b-41d4-a716-446655440000',
      type: type,
      snapshot: snapshot ?? <String, dynamic>{'id': 'habit-1', 'name': 'Read'},
      createdAt: DateTime.utc(2026, 1, 1),
      revision: revision,
      attempts: attempts,
      uncertain: uncertain,
      createSnapshot: createSnapshot,
    );
  }

  PendingHabitMutationStore createStore() => PendingHabitMutationStore(
        nowProvider: () => DateTime.utc(2026, 1, 2),
        operationIdProvider: () => 'generated-op',
      );

  test('persists mutations across store recreation and isolates users',
      () async {
    final store = createStore();
    expect(
      await store.enqueue(
        userId: 'user-a',
        localHabitId: 'habit-1',
        type: PendingHabitMutationType.create,
        snapshot: <String, dynamic>{'id': 'habit-1', 'name': 'Read'},
      ),
      isTrue,
    );
    expect(
      await store.enqueue(
        userId: 'user-b',
        localHabitId: 'habit-1',
        type: PendingHabitMutationType.create,
        snapshot: <String, dynamic>{'id': 'habit-1', 'name': 'Other'},
      ),
      isTrue,
    );

    final recreated = createStore();
    expect((await recreated.read('user-a')).values.single.snapshot['name'],
        'Read');
    expect((await recreated.read('user-b')).values.single.snapshot['name'],
        'Other');
  });

  test('compacts create plus update into create with the final snapshot', () {
    final store = createStore();
    final compacted = store.compact(
      <PendingHabitMutation>[createMutation()],
      createMutation(
        operationId: 'op-update',
        type: PendingHabitMutationType.update,
        snapshot: <String, dynamic>{'id': 'habit-1', 'name': 'Run'},
      ),
    );
    expect(compacted, hasLength(1));
    expect(compacted.single.type, PendingHabitMutationType.create);
    expect(compacted.single.operationId, 'op-create');
    expect(compacted.single.snapshot['name'], 'Run');
    expect(compacted.single.revision, 1);
  });

  test('compacts update plus update and gives archive priority', () {
    final store = createStore();
    final first = createMutation(
      type: PendingHabitMutationType.update,
      snapshot: <String, dynamic>{'id': 'habit-1', 'name': 'One'},
    );
    final updated = store.compact(
      <PendingHabitMutation>[first],
      createMutation(
        operationId: 'op-update-2',
        type: PendingHabitMutationType.update,
        snapshot: <String, dynamic>{'id': 'habit-1', 'name': 'Two'},
      ),
    );
    final archived = store.compact(
      updated,
      createMutation(
        operationId: 'op-archive',
        type: PendingHabitMutationType.archive,
        snapshot: <String, dynamic>{
          'id': 'habit-1',
          'name': 'Two',
          'archived': true
        },
      ),
    );
    expect(updated.single.snapshot['name'], 'Two');
    expect(archived.single.type, PendingHabitMutationType.archive);
    expect(archived.single.snapshot['archived'], isTrue);
  });

  test('cancels an unsent create followed by archive', () {
    final store = createStore();
    final compacted = store.compact(
      <PendingHabitMutation>[createMutation()],
      createMutation(
        type: PendingHabitMutationType.archive,
        snapshot: <String, dynamic>{'id': 'habit-1', 'archived': true},
      ),
    );
    expect(compacted, isEmpty);
  });

  test('keeps an attempted create and archive intent together', () {
    final store = createStore();
    final compacted = store.compact(
      <PendingHabitMutation>[
        createMutation(attempts: 1, uncertain: true),
      ],
      createMutation(
        type: PendingHabitMutationType.archive,
        snapshot: <String, dynamic>{'id': 'habit-1', 'archived': true},
      ),
    );
    expect(compacted.single.type, PendingHabitMutationType.archive);
    expect(compacted.single.createSnapshot, isNotNull);
    expect(compacted.single.operationId, 'op-create');
  });

  test('corrupt queue is not treated as empty or overwritten', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = createStore();
    await prefs.setString(store.keyForUser('user-a'), '{broken');

    final result = await store.read('user-a');
    expect(result.status, PendingQueueReadStatus.corrupt);
    expect(
      await store.enqueue(
        userId: 'user-a',
        localHabitId: 'habit-1',
        type: PendingHabitMutationType.create,
        snapshot: <String, dynamic>{'id': 'habit-1'},
      ),
      isFalse,
    );
    expect(prefs.getString(store.keyForUser('user-a')), '{broken');
  });
}
