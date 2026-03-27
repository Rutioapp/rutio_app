import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:rutio/core/assets/app_assets.dart';

class HomeCatalogService {
  HomeCatalogService({this.assetPath = AppAssets.habitsCatalog});

  final String assetPath;

  Future<Map<String, dynamic>> loadCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    return (decoded as Map).cast<String, dynamic>();
  }

  Color parseColor(dynamic v, {required Color fallback}) {
    if (v is int) return Color(v);
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x')) s = s.substring(2);
      if (s.length == 6) s = 'FF$s';
      final value = int.tryParse(s, radix: 16);
      if (value != null) return Color(value);
    }
    return fallback;
  }

  /// Returns a map keyed by familyId with {name, emoji, color}.
  Future<Map<String, Map<String, dynamic>>> loadFamilies(
      {required Color fallbackColor}) async {
    final catalog = await loadCatalog();
    final families = (catalog['families'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    final out = <String, Map<String, dynamic>>{};
    for (final f in families) {
      final id = (f['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final name = (f['name'] ?? id).toString();
      final emoji = (f['emoji'] ?? '').toString();
      final color = parseColor(f['color'] ?? f['hexColor'] ?? f['bgColor'],
          fallback: fallbackColor);
      out[id] = {
        'name': name,
        'emoji': emoji,
        'color': color,
      };
    }
    return out;
  }
}
