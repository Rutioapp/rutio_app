import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/observability/crash_reporting_service.dart';
import '../../../../core/storage/pending_queue_storage.dart';

class PendingMysteryBoxOpening {
  const PendingMysteryBoxOpening({
    required this.userId,
    required this.requestId,
    required this.createdAtMillis,
    required this.lastAttemptAtMillis,
    required this.attemptCount,
  });

  final String userId;
  final String requestId;
  final int createdAtMillis;
  final int lastAttemptAtMillis;
  final int attemptCount;

  PendingMysteryBoxOpening copyWith({
    String? userId,
    String? requestId,
    int? createdAtMillis,
    int? lastAttemptAtMillis,
    int? attemptCount,
  }) {
    return PendingMysteryBoxOpening(
      userId: userId ?? this.userId,
      requestId: requestId ?? this.requestId,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis ?? this.lastAttemptAtMillis,
      attemptCount: attemptCount ?? this.attemptCount,
    );
  }

  factory PendingMysteryBoxOpening.fromJson(Map<String, dynamic> json) {
    final userId = _trim(json['userId'] ?? json['user_id']);
    final requestId = _trim(json['requestId'] ?? json['request_id']);
    final createdAtMillis =
        _int(json['createdAtMillis'] ?? json['created_at_millis']);
    final lastAttemptAtMillis =
        _int(json['lastAttemptAtMillis'] ?? json['last_attempt_at_millis']);
    final attemptCount = _int(json['attemptCount'] ?? json['attempt_count']);

    if (userId == null ||
        requestId == null ||
        createdAtMillis == null ||
        lastAttemptAtMillis == null ||
        attemptCount == null) {
      throw const FormatException('Invalid pending mystery box operation.');
    }

    return PendingMysteryBoxOpening(
      userId: userId,
      requestId: requestId,
      createdAtMillis: createdAtMillis,
      lastAttemptAtMillis: lastAttemptAtMillis,
      attemptCount: attemptCount,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'requestId': requestId,
      'createdAtMillis': createdAtMillis,
      'lastAttemptAtMillis': lastAttemptAtMillis,
      'attemptCount': attemptCount,
    };
  }
}

abstract interface class PendingMysteryBoxOperationStore {
  Future<List<PendingMysteryBoxOpening>> loadPendingOperations(String userId);

  Future<void> savePendingOperations(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  );

  Future<void> clearPendingOperations(String userId);
}

abstract interface class PendingMysteryBoxOperationStoreWithStatus {
  Future<PendingQueueReadResult<PendingMysteryBoxOpening>>
      loadPendingOperationsWithStatus(String userId);
  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  );
  Future<bool> clearPendingOperationsConfirmed(String userId);
}

extension PendingMysteryBoxOperationStoreStatusAccess
    on PendingMysteryBoxOperationStore {
  Future<PendingQueueReadResult<PendingMysteryBoxOpening>>
      loadPendingOperationsWithStatus(String userId) {
    final store = this;
    if (store is PendingMysteryBoxOperationStoreWithStatus) {
      return (store as PendingMysteryBoxOperationStoreWithStatus)
          .loadPendingOperationsWithStatus(userId);
    }
    return loadPendingOperations(userId).then(
      (values) => PendingQueueReadResult<PendingMysteryBoxOpening>(
        status: PendingQueueReadStatus.valid,
        values: values,
      ),
    );
  }

  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  ) {
    final store = this;
    if (store is PendingMysteryBoxOperationStoreWithStatus) {
      return (store as PendingMysteryBoxOperationStoreWithStatus)
          .savePendingOperationsConfirmed(userId, operations);
    }
    return savePendingOperations(userId, operations)
        .then((_) => true)
        .catchError((_) => false);
  }

  Future<bool> clearPendingOperationsConfirmed(String userId) {
    final store = this;
    if (store is PendingMysteryBoxOperationStoreWithStatus) {
      return (store as PendingMysteryBoxOperationStoreWithStatus)
          .clearPendingOperationsConfirmed(userId);
    }
    return clearPendingOperations(userId)
        .then((_) => true)
        .catchError((_) => false);
  }
}

class SharedPreferencesPendingMysteryBoxOperationStore
    implements
        PendingMysteryBoxOperationStore,
        PendingMysteryBoxOperationStoreWithStatus {
  SharedPreferencesPendingMysteryBoxOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  }) : _storage = PendingQueueStorage(
          queueName: 'mystery_box_opening',
          sharedPreferencesProvider:
              sharedPreferencesProvider ?? SharedPreferences.getInstance,
          diagnosticSink: diagnosticSink,
          crashReportingService: crashReportingService,
        );

  static const String storagePrefix = 'rutio_mystery_box_pending_opening_v1';

  final PendingQueueStorage _storage;

  @override
  Future<List<PendingMysteryBoxOpening>> loadPendingOperations(
    String userId,
  ) async {
    return (await loadPendingOperationsWithStatus(userId)).values;
  }

  @override
  Future<PendingQueueReadResult<PendingMysteryBoxOpening>>
      loadPendingOperationsWithStatus(String userId) {
    return _storage.read<PendingMysteryBoxOpening>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  ) async {
    await _storage.write<PendingMysteryBoxOpening>(
      key: _storageKey(userId),
      values: operations,
      decode: _decode,
      encode: (values) =>
          values.map((operation) => operation.toJson()).toList(growable: false),
    );
  }

  @override
  Future<bool> savePendingOperationsConfirmed(
    String userId,
    List<PendingMysteryBoxOpening> operations,
  ) {
    return _storage.write<PendingMysteryBoxOpening>(
      key: _storageKey(userId),
      values: operations,
      decode: _decode,
      encode: (values) =>
          values.map((operation) => operation.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearPendingOperations(String userId) async {
    await _storage.clear<PendingMysteryBoxOpening>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  @override
  Future<bool> clearPendingOperationsConfirmed(String userId) {
    return _storage.clear<PendingMysteryBoxOpening>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  List<PendingMysteryBoxOpening> _decode(List<dynamic> rows) {
    final pending = <PendingMysteryBoxOpening>[];
    for (final value in rows) {
      if (value is! Map) throw const FormatException('Invalid queue row.');
      pending.add(
        PendingMysteryBoxOpening.fromJson(
          Map<String, dynamic>.from(value.cast<String, dynamic>()),
        ),
      );
    }
    pending.sort((a, b) {
      final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
      if (byCreated != 0) return byCreated;
      return a.requestId.compareTo(b.requestId);
    });
    return pending;
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}
