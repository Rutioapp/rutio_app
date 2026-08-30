import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rutio/features/feedback/data/feedback_technical_context_service.dart';

void main() {
  test('buildTechnicalContext merges app metadata, device data and locale',
      () async {
    final service = FeedbackTechnicalContextService(
      appMetadataSource: _FakeAppMetadataSource(
        const FeedbackAppMetadata(
          appVersion: '1.2.3',
          buildNumber: '456',
        ),
      ),
      deviceSnapshotSource: _FakeDeviceSnapshotSource(
        const FeedbackDeviceSnapshot(
          platform: 'Android',
          osVersion: '15',
          deviceModel: 'Pixel 8',
        ),
      ),
      localeProvider: () => const Locale('es', 'MX'),
    );

    final context = await service.buildTechnicalContext(
      sourceRoute: '  /feedback/new  ',
    );

    expect(context.appVersion, '1.2.3');
    expect(context.buildNumber, '456');
    expect(context.platform, 'android');
    expect(context.osVersion, '15');
    expect(context.deviceModel, 'Pixel 8');
    expect(context.appLocale, 'es_MX');
    expect(context.sourceRoute, '/feedback/new');
  });

  test('buildTechnicalContext rejects empty routes', () async {
    final service = FeedbackTechnicalContextService(
      appMetadataSource: _FakeAppMetadataSource(
        const FeedbackAppMetadata(
          appVersion: '1.2.3',
          buildNumber: '456',
        ),
      ),
      deviceSnapshotSource: _FakeDeviceSnapshotSource(
        const FeedbackDeviceSnapshot(
          platform: 'web',
          osVersion: 'web',
          deviceModel: 'web',
        ),
      ),
      localeProvider: () => const Locale('es'),
    );

    expect(
      () => service.buildTechnicalContext(sourceRoute: '   '),
      throwsA(isA<ArgumentError>()),
    );
  });
}

class _FakeAppMetadataSource implements FeedbackAppMetadataSource {
  const _FakeAppMetadataSource(this.value);

  final FeedbackAppMetadata value;

  @override
  Future<FeedbackAppMetadata> read() async => value;
}

class _FakeDeviceSnapshotSource implements FeedbackDeviceSnapshotSource {
  const _FakeDeviceSnapshotSource(this.value);

  final FeedbackDeviceSnapshot value;

  @override
  Future<FeedbackDeviceSnapshot> read() async => value;
}
