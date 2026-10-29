import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/observability/crash_reporting_service.dart';
import '../../../../core/storage/pending_queue_storage.dart';
import '../../domain/models/pending_currency_operation.dart';
import '../../domain/pending_currency_operation_store.dart';

class SharedPreferencesPendingCurrencyOperationStore
    implements
        PendingCurrencyOperationStore,
        PendingCurrencyOperationStoreWithStatus {
  SharedPreferencesPendingCurrencyOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  }) : _storage = PendingQueueStorage(
          queueName: 'habit_currency',
          sharedPreferencesProvider:
              sharedPreferencesProvider ?? SharedPreferences.getInstance,
          diagnosticSink: diagnosticSink,
          crashReportingService: crashReportingService,
        );

  static const String storagePrefix =
      'rutio_habit_pending_currency_operation_v1';

  final PendingQueueStorage _storage;

  @override
  Future<List<PendingCurrencyOperation>> loadPendingOperations(
    String userId,
  ) async {
    final result = await loadPendingOperationsWithStatus(userId);
    return result.values;
  }

  @override
  Future<PendingQueueReadResult<PendingCurrencyOperation>>
      loadPendingOperationsWithStatus(String userId) {
    return _storage.read<PendingCurrencyOperation>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  @override
  Future<void> savePendingOperations(
    String userId,
    List<PendingCurrencyOperation> operations,
  ) async {
    await _storage.write<PendingCurrencyOperation>(
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
    List<PendingCurrencyOperation> operations,
  ) {
    return _storage.write<PendingCurrencyOperation>(
      key: _storageKey(userId),
      values: operations,
      decode: _decode,
      encode: (values) =>
          values.map((operation) => operation.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearPendingOperations(String userId) async {
    await _storage.clear<PendingCurrencyOperation>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  List<PendingCurrencyOperation> _decode(List<dynamic> rows) {
    final pending = <PendingCurrencyOperation>[];
    for (final value in rows) {
      if (value is! Map) throw const FormatException('Invalid queue row.');
      pending.add(
        PendingCurrencyOperation.fromJson(
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
