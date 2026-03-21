import 'package:flutter/services.dart';

// IOS-FIRST IMPROVEMENT START
abstract final class IosFeedback {
  static Future<void> selection() => HapticFeedback.selectionClick();

  static Future<void> lightImpact() => HapticFeedback.lightImpact();

  static Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  static Future<void> success() => HapticFeedback.lightImpact();
}
// IOS-FIRST IMPROVEMENT END
