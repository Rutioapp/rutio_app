import 'dart:io' show Platform;

String detectFeedbackPlatform() {
  if (Platform.isIOS) return 'iOS';
  if (Platform.isAndroid) return 'Android';
  return 'Unknown';
}
