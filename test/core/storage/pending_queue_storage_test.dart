import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/core/storage/pending_queue_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  PendingQueueStorage createStore({
    Future<SharedPreferences> Function()? provider,
    PendingQueueDiagnosticSink? diagnosticSink,
  }) {
    return PendingQueueStorage(
      queueName: 'test_queue',
      sharedPreferencesProvider:
          provider ?? SharedPreferences.getInstance,
      diagnosticSink: diagnosticSink,
    );
  }

  List<int> decodeInts(List<dynamic> rows) {
    return rows.map((row) {
      if (row is! int) throw const FormatException('invalid row');
      return row;
    }).toList(growable: false);
  }

  test('distinguishes empty and valid queues', () async {
    final store = createStore();
    expect(
      (await store.read<int>(key: 'queue_user-a', decode: decodeInts)).status,
      PendingQueueReadStatus.empty,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('queue_user-a', '[1,2]');
    final result = await store.read<int>(key: 'queue_user-a', decode: decodeInts);
    expect(result.status, PendingQueueReadStatus.valid);
    expect(result.values, <int>[1, 2]);
  });

  test('classifies invalid JSON, wrong root, and invalid rows as corrupt', () async {
    final diagnostics = <PendingQueueDiagnostic>[];
    final store = createStore(diagnosticSink: diagnostics.add);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('invalid-json', '{not-json');
    await prefs.setString('wrong-root', '{"items":[]}');
    await prefs.setString('invalid-row', '[1,"bad",2]');

    expect(
      (await store.read<int>(key: 'invalid-json', decode: decodeInts)).status,
      PendingQueueReadStatus.corrupt,
    );
    expect(
      (await store.read<int>(key: 'wrong-root', decode: decodeInts)).status,
      PendingQueueReadStatus.corrupt,
    );
    expect(
      (await store.read<int>(key: 'invalid-row', decode: decodeInts)).status,
      PendingQueueReadStatus.corrupt,
    );
    expect(diagnostics.map((entry) => entry.reason), contains('payload_unreadable'));
    expect(diagnostics.every((entry) => entry.payloadLength > 0), isTrue);
  });

  test('classifies unsupported version and quarantines once without logging payload', () async {
    final diagnostics = <PendingQueueDiagnostic>[];
    final store = createStore(diagnosticSink: diagnostics.add);
    final prefs = await SharedPreferences.getInstance();
    const raw = '{"schemaVersion":99,"items":[7]}';
    await prefs.setString('versioned-user-a', raw);

    final result = await store.read<int>(
      key: 'versioned-user-a',
      decode: decodeInts,
    );
    expect(result.status, PendingQueueReadStatus.incompatible);
    expect(
      prefs.getString('versioned-user-a'),
      raw,
    );
    expect(
      prefs.getString('versioned-user-a_quarantine_v1'),
      raw,
    );
    expect(diagnostics.single.reason, 'unsupported_version');
    expect(diagnostics.single.queueName, 'test_queue');
  });

  test('does not overwrite or clear a corrupt queue', () async {
    final store = createStore();
    final prefs = await SharedPreferences.getInstance();
    const raw = '[1,"broken",2]';
    await prefs.setString('queue_user-a', raw);

    final wrote = await store.write<int>(
      key: 'queue_user-a',
      values: <int>[9],
      decode: decodeInts,
      encode: (values) => values,
    );
    final cleared = await store.clear<int>(
      key: 'queue_user-a',
      decode: decodeInts,
    );

    expect(wrote, isFalse);
    expect(cleared, isFalse);
    expect(prefs.getString('queue_user-a'), raw);
  });

  test('persists across recreated stores and isolates users', () async {
    final store = createStore();
    await store.write<int>(
      key: 'queue_user-a',
      values: <int>[3],
      decode: decodeInts,
      encode: (values) => values,
    );
    await store.write<int>(
      key: 'queue_user-b',
      values: <int>[8],
      decode: decodeInts,
      encode: (values) => values,
    );

    final recreated = createStore();
    expect(
      (await recreated.read<int>(key: 'queue_user-a', decode: decodeInts)).values,
      <int>[3],
    );
    expect(
      (await recreated.read<int>(key: 'queue_user-b', decode: decodeInts)).values,
      <int>[8],
    );
  });

  test('recovers after the storage provider becomes available', () async {
    var available = false;
    final prefs = await SharedPreferences.getInstance();
    final store = createStore(
      provider: () async {
        if (!available) throw StateError('temporarily unavailable');
        return prefs;
      },
    );

    final unavailable = await store.read<int>(
      key: 'recoverable',
      decode: decodeInts,
    );
    expect(unavailable.status, PendingQueueReadStatus.storageError);

    available = true;
    final recovered = await store.write<int>(
      key: 'recoverable',
      values: <int>[4],
      decode: decodeInts,
      encode: (values) => values,
    );
    expect(recovered, isTrue);
    expect(prefs.getString('recoverable'), jsonEncode(<int>[4]));
  });
}
