const Object _equippedUnset = Object();

class EquippedCosmetics {
  const EquippedCosmetics({
    this.backgroundItemId,
    this.habitCardItemId,
    this.userCardItemId,
  });

  final String? backgroundItemId;
  final String? habitCardItemId;
  final String? userCardItemId;

  EquippedCosmetics copyWith({
    Object? backgroundItemId = _equippedUnset,
    Object? habitCardItemId = _equippedUnset,
    Object? userCardItemId = _equippedUnset,
  }) {
    return EquippedCosmetics(
      backgroundItemId: identical(backgroundItemId, _equippedUnset)
          ? this.backgroundItemId
          : backgroundItemId as String?,
      habitCardItemId: identical(habitCardItemId, _equippedUnset)
          ? this.habitCardItemId
          : habitCardItemId as String?,
      userCardItemId: identical(userCardItemId, _equippedUnset)
          ? this.userCardItemId
          : userCardItemId as String?,
    );
  }

  factory EquippedCosmetics.fromJson(Map<String, dynamic> json) {
    return EquippedCosmetics(
      backgroundItemId: json['backgroundItemId']?.toString(),
      habitCardItemId: json['habitCardItemId']?.toString(),
      userCardItemId: json['userCardItemId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'backgroundItemId': backgroundItemId,
      'habitCardItemId': habitCardItemId,
      'userCardItemId': userCardItemId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EquippedCosmetics &&
        other.backgroundItemId == backgroundItemId &&
        other.habitCardItemId == habitCardItemId &&
        other.userCardItemId == userCardItemId;
  }

  @override
  int get hashCode => Object.hash(
        backgroundItemId,
        habitCardItemId,
        userCardItemId,
      );
}
