import 'auth_callback_type.dart';

/// Safe callback metadata. The original URI and all credential-bearing
/// parameters are intentionally absent from this model.
class AuthCallbackIntent {
  const AuthCallbackIntent({
    required this.type,
    required this.scheme,
    required this.host,
    required this.path,
    required this.receivedAt,
    required this.isColdStart,
    this.safeParameters = const <String, String>{},
  });

  final AuthCallbackType type;
  final String scheme;
  final String host;
  final String path;
  final DateTime receivedAt;
  final bool isColdStart;
  final Map<String, String> safeParameters;
}
