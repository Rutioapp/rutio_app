import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../domain/feedback_technical_context.dart';

class FeedbackAppMetadata {
  const FeedbackAppMetadata({
    required this.appVersion,
    required this.buildNumber,
  });

  final String appVersion;
  final String buildNumber;
}

abstract interface class FeedbackAppMetadataSource {
  Future<FeedbackAppMetadata> read();
}

class DefaultFeedbackAppMetadataSource implements FeedbackAppMetadataSource {
  const DefaultFeedbackAppMetadataSource();

  @override
  Future<FeedbackAppMetadata> read() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return FeedbackAppMetadata(
      appVersion: packageInfo.version.trim(),
      buildNumber: packageInfo.buildNumber.trim(),
    );
  }
}

class FeedbackDeviceSnapshot {
  const FeedbackDeviceSnapshot({
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
  });

  final String platform;
  final String osVersion;
  final String deviceModel;
}

abstract interface class FeedbackDeviceSnapshotSource {
  Future<FeedbackDeviceSnapshot> read();
}

class DefaultFeedbackDeviceSnapshotSource
    implements FeedbackDeviceSnapshotSource {
  const DefaultFeedbackDeviceSnapshotSource();

  @override
  Future<FeedbackDeviceSnapshot> read() async {
    if (kIsWeb) {
      return const FeedbackDeviceSnapshot(
        platform: 'web',
        osVersion: 'web',
        deviceModel: 'web',
      );
    }

    final plugin = DeviceInfoPlugin();
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final androidInfo = await plugin.androidInfo;
        return FeedbackDeviceSnapshot(
          platform: 'android',
          osVersion: androidInfo.version.release.trim(),
          deviceModel: androidInfo.model.trim(),
        );
      case TargetPlatform.iOS:
        final iosInfo = await plugin.iosInfo;
        return FeedbackDeviceSnapshot(
          platform: 'ios',
          osVersion: iosInfo.systemVersion.trim(),
          deviceModel: iosInfo.model.trim(),
        );
      case TargetPlatform.macOS:
        return const FeedbackDeviceSnapshot(
          platform: 'macos',
          osVersion: 'unknown',
          deviceModel: 'unknown',
        );
      case TargetPlatform.windows:
        return const FeedbackDeviceSnapshot(
          platform: 'windows',
          osVersion: 'unknown',
          deviceModel: 'unknown',
        );
      case TargetPlatform.linux:
        return const FeedbackDeviceSnapshot(
          platform: 'linux',
          osVersion: 'unknown',
          deviceModel: 'unknown',
        );
      case TargetPlatform.fuchsia:
        return const FeedbackDeviceSnapshot(
          platform: 'fuchsia',
          osVersion: 'unknown',
          deviceModel: 'unknown',
        );
    }
  }
}

class FeedbackTechnicalContextService {
  FeedbackTechnicalContextService({
    FeedbackAppMetadataSource? appMetadataSource,
    FeedbackDeviceSnapshotSource? deviceSnapshotSource,
    Locale Function()? localeProvider,
  })  : _appMetadataSource =
            appMetadataSource ?? const DefaultFeedbackAppMetadataSource(),
        _deviceSnapshotSource =
            deviceSnapshotSource ?? const DefaultFeedbackDeviceSnapshotSource(),
        _localeProvider = localeProvider ?? _defaultLocaleProvider;

  final FeedbackAppMetadataSource _appMetadataSource;
  final FeedbackDeviceSnapshotSource _deviceSnapshotSource;
  final Locale Function() _localeProvider;

  Future<FeedbackTechnicalContext> buildTechnicalContext({
    required String sourceRoute,
  }) async {
    final normalizedSourceRoute = sourceRoute.trim();
    if (normalizedSourceRoute.isEmpty) {
      throw ArgumentError.value(
        sourceRoute,
        'sourceRoute',
        'sourceRoute must not be empty.',
      );
    }

    final appMetadata = await _appMetadataSource.read();
    final deviceSnapshot = await _deviceSnapshotSource.read();
    final locale = _localeProvider();

    return FeedbackTechnicalContext(
      appVersion: appMetadata.appVersion.trim(),
      buildNumber: appMetadata.buildNumber.trim(),
      platform: deviceSnapshot.platform.trim().toLowerCase(),
      osVersion: deviceSnapshot.osVersion.trim(),
      deviceModel: deviceSnapshot.deviceModel.trim(),
      appLocale: _formatLocale(locale),
      sourceRoute: normalizedSourceRoute,
    );
  }

  static Locale _defaultLocaleProvider() {
    return WidgetsBinding.instance.platformDispatcher.locale;
  }

  static String _formatLocale(Locale locale) {
    final normalized = locale.toString().trim();
    return normalized.isEmpty ? 'unknown' : normalized;
  }
}
