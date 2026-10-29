import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/observability/crash_reporting_service.dart';
import '../../../core/storage/pending_queue_storage.dart';
import '../domain/models/pending_shop_purchase.dart';
import '../domain/pending_shop_operation_store.dart';

class SharedPreferencesPendingShopOperationStore
    implements PendingShopOperationStore, PendingShopOperationStoreWithStatus {
  SharedPreferencesPendingShopOperationStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  }) : _storage = PendingQueueStorage(
          queueName: 'shop_purchase',
          sharedPreferencesProvider:
              sharedPreferencesProvider ?? SharedPreferences.getInstance,
          diagnosticSink: diagnosticSink,
          crashReportingService: crashReportingService,
        );

  static const String storagePrefix = 'rutio_shop_pending_purchase_v1';

  final PendingQueueStorage _storage;

  @override
  Future<List<PendingShopPurchase>> loadPendingPurchases(String userId) async {
    return (await loadPendingPurchasesWithStatus(userId)).values;
  }

  @override
  Future<PendingQueueReadResult<PendingShopPurchase>>
      loadPendingPurchasesWithStatus(String userId) {
    return _storage.read<PendingShopPurchase>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingShopPurchase> purchases,
  ) async {
    await _storage.write<PendingShopPurchase>(
      key: _storageKey(userId),
      values: purchases,
      decode: _decode,
      encode: (values) =>
          values.map((purchase) => purchase.toJson()).toList(growable: false),
    );
  }

  @override
  Future<bool> savePendingPurchasesConfirmed(
    String userId,
    List<PendingShopPurchase> purchases,
  ) {
    return _storage.write<PendingShopPurchase>(
      key: _storageKey(userId),
      values: purchases,
      decode: _decode,
      encode: (values) =>
          values.map((purchase) => purchase.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearPendingPurchases(String userId) async {
    await _storage.clear<PendingShopPurchase>(
      key: _storageKey(userId),
      decode: _decode,
    );
  }

  List<PendingShopPurchase> _decode(List<dynamic> rows) {
    final pending = <PendingShopPurchase>[];
    for (final value in rows) {
      if (value is! Map) throw const FormatException('Invalid queue row.');
      pending.add(
        PendingShopPurchase.fromJson(
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
