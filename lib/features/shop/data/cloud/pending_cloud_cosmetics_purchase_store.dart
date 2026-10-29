import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/observability/crash_reporting_service.dart';
import '../../../../core/storage/pending_queue_storage.dart';
import '../../domain/models/pending_cloud_cosmetics_purchase.dart';
import '../../domain/pending_cloud_cosmetics_purchase_store.dart';

class SharedPreferencesPendingCloudCosmeticsPurchaseStore
    implements PendingCloudCosmeticsPurchaseStore {
  SharedPreferencesPendingCloudCosmeticsPurchaseStore({
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  }) : _storage = PendingQueueStorage(
          queueName: 'shop_cosmetics_purchase',
          sharedPreferencesProvider:
              sharedPreferencesProvider ?? SharedPreferences.getInstance,
          diagnosticSink: diagnosticSink,
          crashReportingService: crashReportingService,
        );

  static const String storagePrefix =
      'rutio_shop_cosmetics_pending_operations_v1';

  final PendingQueueStorage _storage;

  @override
  Future<List<PendingCloudCosmeticsPurchase>> loadPendingPurchases(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <PendingCloudCosmeticsPurchase>[];
    }

    return (await loadPendingPurchasesWithStatus(normalizedUserId)).values;
  }

  Future<PendingQueueReadResult<PendingCloudCosmeticsPurchase>>
      loadPendingPurchasesWithStatus(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Future.value(const PendingQueueReadResult(
        status: PendingQueueReadStatus.empty,
        values: <PendingCloudCosmeticsPurchase>[],
      ));
    }
    return _storage.read<PendingCloudCosmeticsPurchase>(
      key: _storageKey(normalizedUserId),
      decode: (rows) => _decode(rows, normalizedUserId),
    );
  }

  @override
  Future<void> savePendingPurchases(
    String userId,
    List<PendingCloudCosmeticsPurchase> purchases,
  ) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    final byKey = <String, PendingCloudCosmeticsPurchase>{};
    for (final purchase in purchases) {
      if (purchase.userId != normalizedUserId) continue;
      byKey[purchase.logicalKey] = purchase;
    }
    final normalized = byKey.values.toList(growable: false)
      ..sort((a, b) {
        final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
        if (byCreated != 0) return byCreated;
        return a.logicalKey.compareTo(b.logicalKey);
      });

    await _storage.write<PendingCloudCosmeticsPurchase>(
      key: _storageKey(normalizedUserId),
      values: normalized,
      decode: (rows) => _decode(rows, normalizedUserId),
      encode: (values) =>
          values.map((purchase) => purchase.toJson()).toList(growable: false),
    );
  }

  @override
  Future<void> clearPendingPurchases(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return;

    await _storage.clear<PendingCloudCosmeticsPurchase>(
      key: _storageKey(normalizedUserId),
      decode: (rows) => _decode(rows, normalizedUserId),
    );
  }

  List<PendingCloudCosmeticsPurchase> _decode(
    List<dynamic> rows,
    String userId,
  ) {
    final pending = <PendingCloudCosmeticsPurchase>[];
    final seenKeys = <String>{};
    for (final value in rows) {
      if (value is! Map) throw const FormatException('Invalid queue row.');
      final purchase = PendingCloudCosmeticsPurchase.fromJson(
        Map<String, dynamic>.from(value.cast<String, dynamic>()),
      );
      if (purchase.userId != userId ||
          purchase.resourceId.trim().isEmpty ||
          !seenKeys.add(purchase.logicalKey)) {
        throw const FormatException('Invalid or foreign queue row.');
      }
      pending.add(purchase);
    }
    pending.sort((a, b) {
      final byCreated = a.createdAtMillis.compareTo(b.createdAtMillis);
      if (byCreated != 0) return byCreated;
      return a.logicalKey.compareTo(b.logicalKey);
    });
    return pending;
  }

  String _storageKey(String userId) {
    return '${storagePrefix}_${userId.trim()}';
  }
}
