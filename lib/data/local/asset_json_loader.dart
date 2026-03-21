import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class AssetJsonLoader {
  Future<Map<String, dynamic>> loadJsonMap(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a JSON object at $assetPath');
    }
    return decoded;
  }
}
