import 'package:flutter/foundation.dart';

@immutable
class Inventory {
  final Set<String> ownedItemIds;

  const Inventory({
    required this.ownedItemIds,
  });

  Inventory copyWith({
    Set<String>? ownedItemIds,
  }) {
    return Inventory(
      ownedItemIds: ownedItemIds ?? this.ownedItemIds,
    );
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      ownedItemIds: Set<String>.from((json['ownedItemIds'] as List<dynamic>? ?? const [])),
    );
  }

  Map<String, dynamic> toJson() => {
        'ownedItemIds': ownedItemIds.toList(),
      };
}

