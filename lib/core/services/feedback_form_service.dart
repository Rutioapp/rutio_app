import 'package:url_launcher/url_launcher.dart';

import 'feedback_form_platform.dart';

class FeedbackFormService {
  FeedbackFormService();

  static final Uri _baseUri = Uri.parse(
    'https://docs.google.com/forms/d/e/1FAIpQLSe7SQu0BKEjmIhNYowV5oFaFD5g92Cj2zdAwRkpkjsLCiUqbQ/viewform',
  );

  String buildReportIssueUrl({
    required String userId,
    required String email,
    required String platform,
  }) {
    return _baseUri.replace(
      queryParameters: <String, String>{
        'usp': 'pp_url',
        'entry.459298202': userId,
        'entry.771646886': email,
        'entry.1592633689': platform,
      },
    ).toString();
  }

  String detectPlatform() => detectFeedbackPlatform();

  Future<bool> launchReportIssueForm({
    required String userId,
    required String email,
  }) {
    final url = buildReportIssueUrl(
      userId: userId,
      email: email,
      platform: detectPlatform(),
    );

    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }
}
