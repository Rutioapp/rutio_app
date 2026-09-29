import 'analytics_service.dart';

/// Serializes identity transitions so logout/reset cannot race a new login.
class AnalyticsIdentityLifecycle {
  AnalyticsIdentityLifecycle(this._analytics);

  final AnalyticsService _analytics;
  String? _currentUserId;
  Future<void> _transition = Future<void>.value();

  Future<void> resolveUser(String? userId) {
    final normalized = userId?.trim();
    final next = normalized == null || normalized.isEmpty ? null : normalized;
    if (_currentUserId == next) return _transition;

    final previous = _currentUserId;
    _currentUserId = next;
    _transition = _transition.then((_) async {
      if (next == null) {
        if (previous != null) await _analytics.resetIdentity();
        return;
      }
      if (previous != null && previous != next) {
        await _analytics.resetIdentity();
      }
      await _analytics.identifyUser(next);
    });
    return _transition;
  }
}
