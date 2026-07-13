import 'dart:collection';

Map<String, dynamic> shopJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry(key.toString(), shopJsonValue(value)),
    );
  }
  return <String, dynamic>{};
}

List<T> shopJsonList<T>(
  dynamic value,
  T Function(dynamic value) mapper,
) {
  if (value is! List) return <T>[];
  return value.map<T>(mapper).toList(growable: false);
}

dynamic shopJsonValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic value) =>
          MapEntry(key.toString(), shopJsonValue(value)),
    );
  }
  if (value is List) {
    return value.map<dynamic>(shopJsonValue).toList(growable: false);
  }
  if (value is Set) {
    return value.map<dynamic>(shopJsonValue).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> shopNormalizeMetadata(Map<String, dynamic> metadata) {
  return UnmodifiableMapView<String, dynamic>(
    metadata.map(
      (String key, dynamic value) => MapEntry(key, shopJsonValue(value)),
    ),
  );
}

bool shopDeepEquals(dynamic left, dynamic right) {
  if (identical(left, right)) return true;

  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final dynamic key in left.keys) {
      if (!right.containsKey(key)) return false;
      if (!shopDeepEquals(left[key], right[key])) return false;
    }
    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!shopDeepEquals(left[index], right[index])) return false;
    }
    return true;
  }

  if (left is Set && right is Set) {
    if (left.length != right.length) return false;
    final remaining = right.map<int>(shopDeepHash).toList(growable: true);
    for (final dynamic item in left) {
      final hash = shopDeepHash(item);
      final matchIndex = remaining.indexOf(hash);
      if (matchIndex == -1) return false;
      remaining.removeAt(matchIndex);
    }
    return remaining.isEmpty;
  }

  return left == right;
}

int shopDeepHash(dynamic value) {
  if (value is Map) {
    final entries = value.entries
        .map<int>(
          (entry) => Object.hash(
            entry.key,
            shopDeepHash(entry.value),
          ),
        )
        .toList(growable: false)
      ..sort();
    return Object.hashAll(entries);
  }

  if (value is List) {
    return Object.hashAll(value.map<int>(shopDeepHash));
  }

  if (value is Set) {
    final hashes = value.map<int>(shopDeepHash).toList(growable: false)..sort();
    return Object.hashAll(hashes);
  }

  return value.hashCode;
}
