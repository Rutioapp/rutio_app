enum ActiveUtilityEffectType {
  xpBoost,
  coinBoost,
  streakShield,
}

extension ActiveUtilityEffectTypeX on ActiveUtilityEffectType {
  String get key {
    switch (this) {
      case ActiveUtilityEffectType.xpBoost:
        return 'xpBoost';
      case ActiveUtilityEffectType.coinBoost:
        return 'coinBoost';
      case ActiveUtilityEffectType.streakShield:
        return 'streakShield';
    }
  }

  static ActiveUtilityEffectType? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'xpBoost':
        return ActiveUtilityEffectType.xpBoost;
      case 'coinBoost':
        return ActiveUtilityEffectType.coinBoost;
      case 'streakShield':
        return ActiveUtilityEffectType.streakShield;
      default:
        return null;
    }
  }
}

class ActiveUtilityEffect {
  const ActiveUtilityEffect({
    required this.id,
    required this.utilityId,
    required this.type,
    required this.activatedAtMillis,
    required this.remainingUses,
    required this.totalUses,
    this.habitId,
  });

  final String id;
  final String utilityId;
  final ActiveUtilityEffectType type;
  final int activatedAtMillis;
  final int remainingUses;
  final int totalUses;
  final String? habitId;

  bool get isActive => remainingUses > 0;
  bool get isExhausted => remainingUses <= 0;

  ActiveUtilityEffect copyWith({
    String? id,
    String? utilityId,
    ActiveUtilityEffectType? type,
    int? activatedAtMillis,
    int? remainingUses,
    int? totalUses,
    String? habitId,
    bool clearHabitId = false,
  }) {
    return ActiveUtilityEffect(
      id: id ?? this.id,
      utilityId: utilityId ?? this.utilityId,
      type: type ?? this.type,
      activatedAtMillis: activatedAtMillis ?? this.activatedAtMillis,
      remainingUses: remainingUses ?? this.remainingUses,
      totalUses: totalUses ?? this.totalUses,
      habitId: clearHabitId ? null : habitId ?? this.habitId,
    );
  }

  factory ActiveUtilityEffect.fromJson(Map<String, dynamic> json) {
    final type = ActiveUtilityEffectTypeX.fromKey(json['type']?.toString());
    return ActiveUtilityEffect(
      id: (json['id'] ?? '').toString(),
      utilityId: (json['utilityId'] ?? json['itemId'] ?? '').toString(),
      type: type ?? ActiveUtilityEffectType.xpBoost,
      activatedAtMillis: (json['activatedAtMillis'] as num?)?.toInt() ?? 0,
      remainingUses: (json['remainingUses'] as num?)?.toInt() ?? 0,
      totalUses: (json['totalUses'] as num?)?.toInt() ?? 10,
      habitId:
          (json['habitId'] ?? json['targetHabitId'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'utilityId': utilityId,
      'type': type.key,
      'activatedAtMillis': activatedAtMillis,
      'remainingUses': remainingUses,
      'totalUses': totalUses,
      if ((habitId ?? '').trim().isNotEmpty) 'habitId': habitId!.trim(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveUtilityEffect &&
        other.id == id &&
        other.utilityId == utilityId &&
        other.type == type &&
        other.activatedAtMillis == activatedAtMillis &&
        other.remainingUses == remainingUses &&
        other.totalUses == totalUses &&
        other.habitId == habitId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        utilityId,
        type,
        activatedAtMillis,
        remainingUses,
        totalUses,
        habitId,
      );
}

bool activeUtilityEffectEquals(
  ActiveUtilityEffect? a,
  ActiveUtilityEffect? b,
) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  return a == b;
}

const int activeUtilityEffectDefaultTotalUses = 10;
