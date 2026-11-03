import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/observability/crash_reporting_service.dart';
import '../../../core/storage/pending_queue_storage.dart';
import 'pending_habit_mutation.dart';

class PendingHabitMutationStore {
  PendingHabitMutationStore({
    PendingQueueStorage? storage,
    DateTime Function()? nowProvider,
    String Function()? operationIdProvider,
    CrashReportingService? crashReportingService,
  })  : _storage = storage ??
            PendingQueueStorage(
              queueName: 'habit_mutations',
              sharedPreferencesProvider: _sharedPreferences,
              crashReportingService: crashReportingService,
            ),
        _nowProvider = nowProvider ?? DateTime.now,
        _operationIdProvider = operationIdProvider ?? const Uuid().v4;

  final PendingQueueStorage _storage;
  final DateTime Function() _nowProvider;
  final String Function() _operationIdProvider;

  static Future<SharedPreferences> _sharedPreferences() {
    return SharedPreferences.getInstance();
  }

  static const int maxReplayBatch = 20;

  String keyForUser(String userId) {
    final normalized = userId.trim();
    return 'pending_habit_mutations_v1_$normalized';
  }

  Future<PendingQueueReadResult<PendingHabitMutation>> read(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return Future<PendingQueueReadResult<PendingHabitMutation>>.value(
        const PendingQueueReadResult<PendingHabitMutation>(
          status: PendingQueueReadStatus.empty,
          values: <PendingHabitMutation>[],
        ),
      );
    }
    return _storage.read<PendingHabitMutation>(
      key: keyForUser(normalized),
      decode: (rows) =>
          rows.map(PendingHabitMutation.fromJson).toList(growable: false),
    );
  }

  Future<bool> enqueue({
    required String userId,
    required String localHabitId,
    required PendingHabitMutationType type,
    required Map<String, dynamic> snapshot,
    String? remoteHabitId,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedLocalId = localHabitId.trim();
    if (normalizedUserId.isEmpty || normalizedLocalId.isEmpty) return false;

    final current = await read(normalizedUserId);
    if (!current.isUsable) return false;

    final next = compact(
      current.values,
      PendingHabitMutation(
        operationId: _operationIdProvider(),
        userId: normalizedUserId,
        localHabitId: normalizedLocalId,
        remoteHabitId: remoteHabitId,
        type: type,
        snapshot: Map<String, dynamic>.from(snapshot),
        createdAt: _nowProvider().toUtc(),
      ),
    );
    return _write(normalizedUserId, next);
  }

  Future<bool> replace(
    String userId,
    List<PendingHabitMutation> values,
  ) {
    return _write(userId, values);
  }

  Future<bool> removeIfUnchanged({
    required String userId,
    required String operationId,
    required int revision,
  }) async {
    final current = await read(userId);
    if (!current.isUsable) return false;
    final kept = current.values
        .where(
          (entry) =>
              entry.operationId != operationId || entry.revision != revision,
        )
        .toList(growable: false);
    if (kept.length == current.values.length) return true;
    return _write(userId, kept);
  }

  List<PendingHabitMutation> compact(
    List<PendingHabitMutation> current,
    PendingHabitMutation incoming,
  ) {
    final index = current.indexWhere(
      (entry) => entry.localHabitId == incoming.localHabitId,
    );
    if (index == -1) return <PendingHabitMutation>[...current, incoming];

    final existing = current[index];
    PendingHabitMutation? result;
    if (existing.type == PendingHabitMutationType.create &&
        incoming.type == PendingHabitMutationType.update) {
      result = existing.copyWith(
        snapshot: incoming.snapshot,
        remoteHabitId: incoming.remoteHabitId ?? existing.remoteHabitId,
        revision: existing.revision + 1,
        lastError: null,
        uncertain: existing.uncertain,
      );
    } else if (existing.type == PendingHabitMutationType.create &&
        incoming.type == PendingHabitMutationType.archive) {
      if (existing.attempts == 0 && !existing.uncertain) {
        final without = [...current]..removeAt(index);
        return without;
      }
      result = incoming.copyWith(
        operationId: existing.operationId,
        createdAt: existing.createdAt,
        revision: existing.revision + 1,
        createSnapshot: existing.snapshot,
        remoteHabitId: incoming.remoteHabitId ?? existing.remoteHabitId,
      );
    } else if (existing.type == PendingHabitMutationType.update &&
        incoming.type == PendingHabitMutationType.update) {
      result = incoming.copyWith(
        operationId: existing.operationId,
        createdAt: existing.createdAt,
        revision: existing.revision + 1,
      );
    } else if (incoming.type == PendingHabitMutationType.archive) {
      result = incoming.copyWith(
        operationId: existing.operationId,
        createdAt: existing.createdAt,
        revision: existing.revision + 1,
        createSnapshot: existing.createSnapshot,
        remoteHabitId: incoming.remoteHabitId ?? existing.remoteHabitId,
      );
    } else if (existing.type == PendingHabitMutationType.archive) {
      result = existing;
    } else {
      result = incoming;
    }

    final output = [...current];
    output[index] = result;
    return output;
  }

  Future<bool> _write(
    String userId,
    List<PendingHabitMutation> values,
  ) {
    return _storage.write<PendingHabitMutation>(
      key: keyForUser(userId),
      values: values,
      decode: (rows) =>
          rows.map(PendingHabitMutation.fromJson).toList(growable: false),
      encode: (items) => items.map((item) => item.toJson()).toList(),
    );
  }
}
