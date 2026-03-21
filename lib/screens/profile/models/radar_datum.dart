import 'package:flutter/material.dart';

class RadarDatum {
  final String label;
  final double value; // 0..1 normalized
  final Color color;

  const RadarDatum({
    required this.label,
    required this.value,
    required this.color,
  });
}
