import 'dart:convert';

String normalizeRequiredUserId(String userId) {
  final normalized = userId.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(userId, 'userId', 'User id must not be empty.');
  }
  return normalized;
}

String safeUserNamespace(String userId) {
  final normalized = normalizeRequiredUserId(userId);
  return base64Url.encode(utf8.encode(normalized)).replaceAll('=', '');
}
