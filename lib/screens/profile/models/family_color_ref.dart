import 'package:flutter/foundation.dart';

/// A lightweight reference object passed to resolver callbacks coming from
/// `home_screen.dart`.
///
/// Your existing code in Home was treating this resolver argument like a Map
/// (e.g. `h['familyId']`, `h['name']`). To keep backwards compatibility without
/// forcing changes in Home, this class implements the `[]` operator and provides
/// sensible fallbacks.
@immutable
class FamilyColorRef {
  final String familyId;

  /// Optional display name/title for the family.
  final String? familyName;

  /// Optional extra payload for advanced resolvers.
  final Map<String, Object?> data;

  const FamilyColorRef({
    required this.familyId,
    this.familyName,
    this.data = const {},
  });

  /// Map-style accessor for backward compatibility with old resolver code.
  Object? operator [](String key) {
    if (data.containsKey(key)) return data[key];

    switch (key) {
      case 'familyId':
      case 'family':
      case 'Family':
      case 'id':
        return familyId;
      case 'name':
      case 'title':
      case 'habitName':
      case 'label':
        return familyName;
      default:
        return null;
    }
  }
}
