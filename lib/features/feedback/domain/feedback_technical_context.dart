class FeedbackTechnicalContext {
  const FeedbackTechnicalContext({
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appLocale,
    required this.sourceRoute,
  });

  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String appLocale;
  final String sourceRoute;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'appVersion': appVersion,
      'buildNumber': buildNumber,
      'platform': platform,
      'osVersion': osVersion,
      'deviceModel': deviceModel,
      'appLocale': appLocale,
      'sourceRoute': sourceRoute,
    };
  }

  factory FeedbackTechnicalContext.fromJson(Map<String, dynamic> json) {
    return FeedbackTechnicalContext(
      appVersion: _requiredString(json['appVersion'], field: 'appVersion'),
      buildNumber: _requiredString(json['buildNumber'], field: 'buildNumber'),
      platform: _requiredString(json['platform'], field: 'platform'),
      osVersion: _requiredString(json['osVersion'], field: 'osVersion'),
      deviceModel: _requiredString(json['deviceModel'], field: 'deviceModel'),
      appLocale: _requiredString(json['appLocale'], field: 'appLocale'),
      sourceRoute: _requiredString(json['sourceRoute'], field: 'sourceRoute'),
    );
  }

  static String _requiredString(Object? value, {required String field}) {
    final normalized = (value ?? '').toString().trim();
    if (normalized.isEmpty) {
      throw FormatException('Missing or empty $field.');
    }
    return normalized;
  }
}
