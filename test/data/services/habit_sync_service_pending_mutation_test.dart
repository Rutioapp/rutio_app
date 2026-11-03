import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/data/models/remote/remote_habit.dart';
import 'package:rutio/data/repositories/habit_repository.dart';
import 'package:rutio/data/repositories/repository_result.dart';
import 'package:rutio/data/services/habit_sync_service.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation_store.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _remoteId = '550e8400-e29b-41d4-a716-446655440000';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Map<String, dynamic> habit({bool archived = false, String name = 'Read'}) {
    return <String, dynamic>{
      'id': _remoteId,
      'remoteId': _remoteId,
      'name': name,
      'type': 'check',
      'target': 1,
      'schedule': <String, dynamic>{'type': 'daily'},
      'archived': archived,
    };
  }

  test(
      'keeps create pending through a failed request and replays after restart',
      () async {
    var available = false;
    final repository = _FakeHabitRepository(
      currentUserId: () => 'user-a',
      create: (_) async => available
          ? RepositoryResult<RemoteHabit>.success(data: _remoteHabit())
          : const RepositoryResult<RemoteHabit>.failure(
              RepositoryError(
                code: RepositoryErrorCode.network,
                message: 'offline',
              ),
            ),
    );
    final first = HabitSyncService(
      habitRepository: repository,
      currentUserIdProvider: () => 'user-a',
      pendingMutationStore: PendingHabitMutationStore(),
    );

    await first.syncHabitCreated(
      localHabit: habit(),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );
    expect(repository.createCalls, 1);
    expect((await first.pendingHabitMutationsForTest('user-a')), hasLength(1));

    available = true;
    final recreated = HabitSyncService(
      habitRepository: repository,
      currentUserIdProvider: () => 'user-a',
      pendingMutationStore: PendingHabitMutationStore(),
    );
    expect(
      await recreated.syncPendingHabitMutationsForCurrentUser(
        expectedLocalUserId: 'user-a',
      ),
      1,
    );
    expect(repository.createCalls, 2);
    expect(await recreated.pendingHabitMutationsForTest('user-a'), isEmpty);
  });

  test('create plus update replays the final snapshot only', () async {
    final repository = _FakeHabitRepository(
      currentUserId: () => 'user-a',
      create: (_) async => const RepositoryResult<RemoteHabit>.failure(
        RepositoryError(code: RepositoryErrorCode.network, message: 'offline'),
      ),
    );
    final service = HabitSyncService(
      habitRepository: repository,
      currentUserIdProvider: () => 'user-a',
      pendingMutationStore: PendingHabitMutationStore(),
    );

    await service.syncHabitCreated(
      localHabit: habit(name: 'Old'),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );
    await service.syncHabitUpdated(
      localHabit: habit(name: 'New'),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );

    final pending = await service.pendingHabitMutationsForTest('user-a');
    expect(
      pending.single.type,
      PendingHabitMutationType.create,
    );
    expect(pending.single.snapshot['name'], 'New');
  });

  test('archive after an attempted create preserves create dependency',
      () async {
    var createAvailable = false;
    final repository = _FakeHabitRepository(
      currentUserId: () => 'user-a',
      create: (_) async => createAvailable
          ? RepositoryResult<RemoteHabit>.success(data: _remoteHabit())
          : const RepositoryResult<RemoteHabit>.failure(
              RepositoryError(
                  code: RepositoryErrorCode.network, message: 'offline'),
            ),
      archive: (_) async => const RepositoryResult<void>.success(),
    );
    final service = HabitSyncService(
      habitRepository: repository,
      currentUserIdProvider: () => 'user-a',
      pendingMutationStore: PendingHabitMutationStore(),
    );

    await service.syncHabitCreated(
      localHabit: habit(),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );
    await service.syncHabitArchived(
      localHabit: habit(archived: true),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );
    expect(
        (await service.pendingHabitMutationsForTest('user-a'))
            .single
            .createSnapshot,
        isNotNull);

    createAvailable = true;
    expect(
      await service.syncPendingHabitMutationsForCurrentUser(
        expectedLocalUserId: 'user-a',
      ),
      1,
    );
    expect(repository.archiveCalls, 1);
  });

  test('does not call the repository when the queue is corrupt', () async {
    final store = PendingHabitMutationStore();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(store.keyForUser('user-a'), '{broken');
    final repository = _FakeHabitRepository(currentUserId: () => 'user-a');
    final service = HabitSyncService(
      habitRepository: repository,
      currentUserIdProvider: () => 'user-a',
      pendingMutationStore: store,
    );

    await service.syncHabitCreated(
      localHabit: habit(),
      sortOrder: 0,
      expectedLocalUserId: 'user-a',
    );
    expect(repository.createCalls, 0);
  });
}

RemoteHabit _remoteHabit() => const RemoteHabit(
      id: _remoteId,
      userId: 'user-a',
      name: 'Read',
      habitType: 'check',
      reminderEnabled: false,
      isArchived: false,
      sortOrder: 0,
    );

class _FakeHabitRepository extends HabitRepository {
  _FakeHabitRepository({
    required this.currentUserId,
    this.create,
    this.archive,
  }) : super(
          client: SupabaseClient('https://example.com', 'anon-key'),
          currentUserIdProvider: currentUserId,
        );

  final String? Function() currentUserId;
  final Future<RepositoryResult<RemoteHabit>> Function(RemoteHabit)? create;
  final Future<RepositoryResult<void>> Function(String)? archive;
  int createCalls = 0;
  int archiveCalls = 0;

  @override
  Future<RepositoryResult<RemoteHabit>> createHabitIdempotentlyForCurrentUser(
    RemoteHabit habit,
  ) async {
    createCalls += 1;
    final handler = create;
    if (handler != null) return handler(habit);
    return RepositoryResult<RemoteHabit>.success(data: _remoteHabit());
  }

  @override
  Future<RepositoryResult<RemoteHabit>> updateHabitForCurrentUser(
    RemoteHabit habit,
  ) async =>
      RepositoryResult<RemoteHabit>.success(data: _remoteHabit());

  @override
  Future<RepositoryResult<void>> deleteHabitForCurrentUser({
    required String habitId,
  }) async {
    archiveCalls += 1;
    final handler = archive;
    if (handler != null) return handler(habitId);
    return const RepositoryResult<void>.success();
  }
}

extension on HabitSyncService {
  Future<List<dynamic>> pendingHabitMutationsForTest(String userId) async {
    final result = await readPendingHabitMutationsForUser(userId);
    return result.values;
  }
}
