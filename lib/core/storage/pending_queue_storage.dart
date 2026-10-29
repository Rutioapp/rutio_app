import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../observability/crash_reporting_service.dart';

enum PendingQueueReadStatus {
  empty,
  valid,
  corrupt,
  incompatible,
  storageError,
}

@immutable
class PendingQueueDiagnostic {
  const PendingQueueDiagnostic({
    required this.queueName,
    required this.status,
    required this.reason,
    required this.payloadLength,
  });

  final String queueName;
  final PendingQueueReadStatus status;
  final String reason;
  final int payloadLength;
}

@immutable
class PendingQueueReadResult<T> {
  const PendingQueueReadResult({
    required this.status,
    required this.values,
  });

  final PendingQueueReadStatus status;
  final List<T> values;

  bool get isUsable =>
      status == PendingQueueReadStatus.empty ||
      status == PendingQueueReadStatus.valid;
}

typedef PendingQueueDecoder<T> = List<T> Function(List<dynamic> rows);
typedef PendingQueueDiagnosticSink = void Function(
  PendingQueueDiagnostic diagnostic,
);

/// Hardened SharedPreferences access for legacy pending-operation lists.
///
/// Legacy payloads remain JSON arrays. A versioned envelope is accepted for
/// forward compatibility, but writes intentionally keep the legacy shape so
/// older app versions can still read data written by this version.
class PendingQueueStorage {
  PendingQueueStorage({
    required this.queueName,
    required Future<SharedPreferences> Function() sharedPreferencesProvider,
    PendingQueueDiagnosticSink? diagnosticSink,
    CrashReportingService? crashReportingService,
  })  : _sharedPreferencesProvider = sharedPreferencesProvider,
        _diagnosticSink = diagnosticSink ?? _defaultDiagnosticSink,
        _crashReportingService = crashReportingService;

  static const int currentPayloadVersion = 1;
  static const String _quarantineSuffix = '_quarantine_v1';

  final String queueName;
  final Future<SharedPreferences> Function() _sharedPreferencesProvider;
  final PendingQueueDiagnosticSink _diagnosticSink;
  final CrashReportingService? _crashReportingService;

  Future<PendingQueueReadResult<T>> read<T>({
    required String key,
    required PendingQueueDecoder<T> decode,
  }) async {
    SharedPreferences prefs;
    try {
      prefs = await _sharedPreferencesProvider();
    } catch (_) {
      _report(
          PendingQueueReadStatus.storageError, 'preferences_unavailable', 0);
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.storageError,
        values: <T>[],
      );
    }

    String? raw;
    try {
      raw = prefs.getString(key);
    } catch (_) {
      _report(PendingQueueReadStatus.storageError, 'read_failed', 0);
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.storageError,
        values: <T>[],
      );
    }

    if (raw == null || raw.trim().isEmpty) {
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.empty,
        values: <T>[],
      );
    }

    try {
      final decoded = jsonDecode(raw);
      final rows = _extractRows(decoded);
      final values = decode(rows);
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.valid,
        values: List<T>.unmodifiable(values),
      );
    } on _IncompatiblePayloadException {
      await _quarantine(prefs, key, raw);
      _report(PendingQueueReadStatus.incompatible, 'unsupported_version',
          raw.length);
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.incompatible,
        values: <T>[],
      );
    } catch (_) {
      await _quarantine(prefs, key, raw);
      _report(PendingQueueReadStatus.corrupt, 'payload_unreadable', raw.length);
      return PendingQueueReadResult<T>(
        status: PendingQueueReadStatus.corrupt,
        values: <T>[],
      );
    }
  }

  Future<bool> write<T>({
    required String key,
    required List<T> values,
    required PendingQueueDecoder<T> decode,
    required List<Object?> Function(List<T> values) encode,
  }) async {
    final current = await read(key: key, decode: decode);
    if (!current.isUsable) return false;

    try {
      final prefs = await _sharedPreferencesProvider();
      final encoded = jsonEncode(encode(values));
      final saved = await prefs.setString(key, encoded);
      if (!saved) {
        _report(PendingQueueReadStatus.storageError, 'write_rejected',
            encoded.length);
        return false;
      }
      final verification = await read<T>(key: key, decode: decode);
      if (!verification.isUsable ||
          verification.values.length != values.length) {
        _report(PendingQueueReadStatus.storageError, 'write_not_verified',
            encoded.length);
        return false;
      }
      return true;
    } catch (_) {
      _report(PendingQueueReadStatus.storageError, 'write_failed', 0);
      return false;
    }
  }

  Future<bool> clear<T>({
    required String key,
    required PendingQueueDecoder<T> decode,
  }) async {
    final current = await read(key: key, decode: decode);
    if (!current.isUsable) return false;

    try {
      final prefs = await _sharedPreferencesProvider();
      return await prefs.remove(key);
    } catch (_) {
      _report(PendingQueueReadStatus.storageError, 'clear_failed', 0);
      return false;
    }
  }

  List<dynamic> _extractRows(Object? decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      if (!decoded.containsKey('schemaVersion')) {
        throw const FormatException('Pending queue payload is not versioned.');
      }
      final version = decoded['schemaVersion'];
      if (version is! int || version != currentPayloadVersion) {
        throw const _IncompatiblePayloadException();
      }
      final items = decoded['items'];
      if (items is List) return items;
    }
    throw const FormatException('Pending queue payload is not a list.');
  }

  Future<void> _quarantine(
    SharedPreferences prefs,
    String key,
    String raw,
  ) async {
    final quarantineKey = '$key$_quarantineSuffix';
    try {
      if (!prefs.containsKey(quarantineKey)) {
        await prefs.setString(quarantineKey, raw);
      }
    } catch (_) {
      // Quarantine is best-effort. The original payload is never removed.
    }
  }

  void _report(PendingQueueReadStatus status, String reason, int length) {
    _diagnosticSink(
      PendingQueueDiagnostic(
        queueName: queueName,
        status: status,
        reason: reason,
        payloadLength: length,
      ),
    );
    final reporting = _crashReportingService;
    if (reporting != null) {
      unawaited(
        reporting
            .recordNonFatal(
              StateError('pending_queue_${status.name}'),
              StackTrace.current,
              reason: 'pending_queue:$queueName:$reason',
            )
            .catchError((_) {}),
      );
    }
  }

  static void _defaultDiagnosticSink(PendingQueueDiagnostic diagnostic) {
    debugPrint(
      'pending_queue status=${diagnostic.status.name} '
      'queue=${diagnostic.queueName} reason=${diagnostic.reason} '
      'bytes=${diagnostic.payloadLength}',
    );
  }
}

class _IncompatiblePayloadException implements Exception {
  const _IncompatiblePayloadException();
}
