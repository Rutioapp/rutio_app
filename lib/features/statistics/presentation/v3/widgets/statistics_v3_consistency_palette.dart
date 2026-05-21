import 'package:flutter/material.dart';

enum StatisticsV3ConsistencyIntensity {
  unavailable,
  future,
  zero,
  low,
  medium,
  high,
}

class StatisticsV3ConsistencyTone {
  const StatisticsV3ConsistencyTone({
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color textColor;
}

class StatisticsV3ConsistencyRangeBucket {
  const StatisticsV3ConsistencyRangeBucket({
    required this.intensity,
    required this.minPercentage,
    required this.maxPercentage,
  });

  final StatisticsV3ConsistencyIntensity intensity;
  final int minPercentage;
  final int maxPercentage;
}

class StatisticsV3ConsistencyPalette {
  const StatisticsV3ConsistencyPalette._();

  static const Color text = Color(0xFF2F251C);
  static const Color mutedText = Color(0xFF6A6155);
  static const Color futureFill = Color(0xFFF0EBE3);
  static const Color unavailableFill = Color(0xFFF5EFE5);
  static const Color futureBorder = Color(0xFFE4DBCD);
  static const Color unavailableBorder = Color(0xFFE4DBCD);
  static const Color zero = Color(0xFFF1E5D3);
  static const Color low = Color(0xFFE7CC9F);
  static const Color medium = Color(0xFFBBD09A);
  static const Color high = Color(0xFF70965D);
  static const List<StatisticsV3ConsistencyRangeBucket> percentageBuckets = [
    StatisticsV3ConsistencyRangeBucket(
      intensity: StatisticsV3ConsistencyIntensity.zero,
      minPercentage: 0,
      maxPercentage: 0,
    ),
    StatisticsV3ConsistencyRangeBucket(
      intensity: StatisticsV3ConsistencyIntensity.low,
      minPercentage: 1,
      maxPercentage: 39,
    ),
    StatisticsV3ConsistencyRangeBucket(
      intensity: StatisticsV3ConsistencyIntensity.medium,
      minPercentage: 40,
      maxPercentage: 74,
    ),
    StatisticsV3ConsistencyRangeBucket(
      intensity: StatisticsV3ConsistencyIntensity.high,
      minPercentage: 75,
      maxPercentage: 100,
    ),
  ];

  static StatisticsV3ConsistencyIntensity intensityFor({
    required int percentage,
    required int expectedCount,
    required bool isFuture,
  }) {
    if (isFuture) return StatisticsV3ConsistencyIntensity.future;
    if (expectedCount <= 0) return StatisticsV3ConsistencyIntensity.unavailable;

    final value = percentage.clamp(0, 100);
    for (final bucket in percentageBuckets) {
      if (value >= bucket.minPercentage && value <= bucket.maxPercentage) {
        return bucket.intensity;
      }
    }

    return StatisticsV3ConsistencyIntensity.high;
  }

  static StatisticsV3ConsistencyTone toneFor(
    StatisticsV3ConsistencyIntensity intensity,
  ) {
    switch (intensity) {
      case StatisticsV3ConsistencyIntensity.unavailable:
        return const StatisticsV3ConsistencyTone(
          fillColor: unavailableFill,
          borderColor: unavailableBorder,
          textColor: mutedText,
        );
      case StatisticsV3ConsistencyIntensity.future:
        return const StatisticsV3ConsistencyTone(
          fillColor: futureFill,
          borderColor: futureBorder,
          textColor: mutedText,
        );
      case StatisticsV3ConsistencyIntensity.zero:
        return const StatisticsV3ConsistencyTone(
          fillColor: zero,
          borderColor: Color(0xFFE4D6C2),
          textColor: text,
        );
      case StatisticsV3ConsistencyIntensity.low:
        return const StatisticsV3ConsistencyTone(
          fillColor: low,
          borderColor: Color(0xFFE0C18E),
          textColor: text,
        );
      case StatisticsV3ConsistencyIntensity.medium:
        return const StatisticsV3ConsistencyTone(
          fillColor: medium,
          borderColor: Color(0xFFA7BF84),
          textColor: text,
        );
      case StatisticsV3ConsistencyIntensity.high:
        return const StatisticsV3ConsistencyTone(
          fillColor: high,
          borderColor: Color(0xFF628750),
          textColor: Colors.white,
        );
    }
  }
}
