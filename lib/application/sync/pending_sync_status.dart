import 'package:rutio/core/storage/pending_queue_storage.dart';
import 'package:rutio/features/achievements/data/cloud/shared_preferences_pending_reward_claim_store.dart';
import 'package:rutio/features/achievements/domain/pending_reward_claim_store.dart';
import 'package:rutio/features/habits/data/cloud/shared_preferences_pending_currency_operation_store.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation.dart';
import 'package:rutio/features/habits/data/pending_habit_mutation_store.dart';
import 'package:rutio/features/habits/domain/pending_currency_operation_store.dart';

enum SyncStatusKind { synchronized, pending, attention }

class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    required this.userId,
    required this.kind,
    this.pendingDomains = const <String>{},
    this.attentionDomains = const <String>{},
  });

  const SyncStatusSnapshot.signedOut()
      : userId = null,
        kind = SyncStatusKind.synchronized,
        pendingDomains = const <String>{},
        attentionDomains = const <String>{};

  final String? userId;
  final SyncStatusKind kind;
  final Set<String> pendingDomains;
  final Set<String> attentionDomains;

  bool get isVisible => userId != null && kind != SyncStatusKind.synchronized;
  bool get needsAttention => kind == SyncStatusKind.attention;

  @override
  bool operator ==(Object other) {
    return other is SyncStatusSnapshot &&
        other.userId == userId &&
        other.kind == kind &&
        _sameSet(other.pendingDomains, pendingDomains) &&
        _sameSet(other.attentionDomains, attentionDomains);
  }

  @override
  int get hashCode => Object.hash(
        userId,
        kind,
        Object.hashAllUnordered(pendingDomains),
        Object.hashAllUnordered(attentionDomains),
      );

  static bool _sameSet(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}

/// Reads local pending queues only. It never repairs, clears, replays, or
/// contacts Supabase, so the Home indicator cannot change synchronization
/// semantics.
class PendingSyncStatusReader {
  PendingSyncStatusReader({
    String? Function()? currentUserIdProvider,
    PendingHabitMutationStore? habitMutationStore,
    Future<PendingQueueReadResult<PendingHabitMutation>> Function(
            String userId)?
        habitMutationReader,
    PendingCurrencyOperationStore? habitCurrencyStore,
    PendingRewardClaimStore? rewardClaimStore,
  })  : _currentUserIdProvider = currentUserIdProvider,
        _habitMutationStore = habitMutationStore ?? PendingHabitMutationStore(),
        _habitMutationReader = habitMutationReader,
        _habitCurrencyStore = habitCurrencyStore ??
            SharedPreferencesPendingCurrencyOperationStore(),
        _rewardClaimStore =
            rewardClaimStore ?? SharedPreferencesPendingRewardClaimStore();

  final String? Function()? _currentUserIdProvider;
  final PendingHabitMutationStore _habitMutationStore;
  final Future<PendingQueueReadResult<PendingHabitMutation>> Function(
      String userId)? _habitMutationReader;
  final PendingCurrencyOperationStore _habitCurrencyStore;
  final PendingRewardClaimStore _rewardClaimStore;

  Future<SyncStatusSnapshot> readCurrent() async {
    final userId = _normalizedUserId(_currentUserIdProvider?.call());
    if (userId == null) return const SyncStatusSnapshot.signedOut();
    return readForUser(userId);
  }

  Future<SyncStatusSnapshot> readForUser(String userId) async {
    final normalizedUserId = _normalizedUserId(userId);
    if (normalizedUserId == null) return const SyncStatusSnapshot.signedOut();

    final results = await Future.wait<_QueueStatus>([
      _readQueue(
        domain: 'habit_mutations',
        read: () =>
            _habitMutationReader?.call(normalizedUserId) ??
            _habitMutationStore.read(normalizedUserId),
        isAttentionValue: (value) => value.uncertain,
      ),
      _readQueue(
        domain: 'habit_rewards',
        read: () => _habitCurrencyStore
            .loadPendingOperationsWithStatus(normalizedUserId),
        isAttentionValue: (value) => value.isAwaitingResolution,
      ),
      _readQueue(
        domain: 'achievement_level_rewards',
        read: () => _rewardClaimStore.loadPendingClaimsWithStatus(
          normalizedUserId,
        ),
        isAttentionValue: (value) => value.isAwaitingResolution,
      ),
    ]);

    final pendingDomains = <String>{};
    final attentionDomains = <String>{};
    for (final result in results) {
      if (result.attention) {
        attentionDomains.add(result.domain);
      } else if (result.hasPending) {
        pendingDomains.add(result.domain);
      }
    }

    final kind = attentionDomains.isNotEmpty
        ? SyncStatusKind.attention
        : pendingDomains.isNotEmpty
            ? SyncStatusKind.pending
            : SyncStatusKind.synchronized;
    return SyncStatusSnapshot(
      userId: normalizedUserId,
      kind: kind,
      pendingDomains: Set<String>.unmodifiable(pendingDomains),
      attentionDomains: Set<String>.unmodifiable(attentionDomains),
    );
  }

  Future<_QueueStatus> _readQueue<T>({
    required String domain,
    required Future<PendingQueueReadResult<T>> Function() read,
    required bool Function(T value) isAttentionValue,
  }) async {
    try {
      final result = await read();
      switch (result.status) {
        case PendingQueueReadStatus.empty:
          return _QueueStatus(domain: domain);
        case PendingQueueReadStatus.valid:
          return _QueueStatus(
            domain: domain,
            hasPending: result.values.isNotEmpty,
            attention: result.values.any(isAttentionValue),
          );
        case PendingQueueReadStatus.corrupt:
        case PendingQueueReadStatus.incompatible:
        case PendingQueueReadStatus.storageError:
          return _QueueStatus(domain: domain, attention: true);
      }
    } catch (_) {
      return _QueueStatus(domain: domain, attention: true);
    }
  }

  static String? _normalizedUserId(String? userId) {
    final normalized = userId?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

class _QueueStatus {
  const _QueueStatus({
    required this.domain,
    this.hasPending = false,
    this.attention = false,
  });

  final String domain;
  final bool hasPending;
  final bool attention;
}
