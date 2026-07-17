class HabitRewardTransaction {
  const HabitRewardTransaction({
    required this.id,
    required this.habitId,
    required this.localDateKey,
    required this.baseXp,
    required this.bonusXp,
    required this.baseCoins,
    required this.bonusCoins,
    required this.appliedEffectIds,
    required this.createdAtMillis,
    required this.isReversed,
  });

  final String id;
  final String habitId;
  final String localDateKey;
  final int baseXp;
  final int bonusXp;
  final int baseCoins;
  final int bonusCoins;
  final List<String> appliedEffectIds;
  final int createdAtMillis;
  final bool isReversed;

  int get totalXp => baseXp + bonusXp;
  int get totalCoins => baseCoins + bonusCoins;
  String get completionKey => '$habitId|$localDateKey';

  HabitRewardTransaction copyWith({
    String? id,
    String? habitId,
    String? localDateKey,
    int? baseXp,
    int? bonusXp,
    int? baseCoins,
    int? bonusCoins,
    List<String>? appliedEffectIds,
    int? createdAtMillis,
    bool? isReversed,
  }) {
    return HabitRewardTransaction(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      localDateKey: localDateKey ?? this.localDateKey,
      baseXp: baseXp ?? this.baseXp,
      bonusXp: bonusXp ?? this.bonusXp,
      baseCoins: baseCoins ?? this.baseCoins,
      bonusCoins: bonusCoins ?? this.bonusCoins,
      appliedEffectIds: appliedEffectIds ?? this.appliedEffectIds,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      isReversed: isReversed ?? this.isReversed,
    );
  }

  factory HabitRewardTransaction.fromJson(Map<String, dynamic> json) {
    final appliedEffectIds = (json['appliedEffectIds'] is List)
        ? (json['appliedEffectIds'] as List)
            .map((value) => value.toString().trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false)
        : <String>[];
    return HabitRewardTransaction(
      id: (json['id'] ?? '').toString(),
      habitId: (json['habitId'] ?? '').toString(),
      localDateKey: (json['localDateKey'] ?? '').toString(),
      baseXp: (json['baseXp'] as num?)?.toInt() ?? 0,
      bonusXp: (json['bonusXp'] as num?)?.toInt() ?? 0,
      baseCoins: (json['baseCoins'] as num?)?.toInt() ?? 0,
      bonusCoins: (json['bonusCoins'] as num?)?.toInt() ?? 0,
      appliedEffectIds: appliedEffectIds,
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt() ?? 0,
      isReversed: json['isReversed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'habitId': habitId,
      'localDateKey': localDateKey,
      'baseXp': baseXp,
      'bonusXp': bonusXp,
      'baseCoins': baseCoins,
      'bonusCoins': bonusCoins,
      'appliedEffectIds': appliedEffectIds,
      'createdAtMillis': createdAtMillis,
      'isReversed': isReversed,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HabitRewardTransaction &&
        other.id == id &&
        other.habitId == habitId &&
        other.localDateKey == localDateKey &&
        other.baseXp == baseXp &&
        other.bonusXp == bonusXp &&
        other.baseCoins == baseCoins &&
        other.bonusCoins == bonusCoins &&
        _listEquals(other.appliedEffectIds, appliedEffectIds) &&
        other.createdAtMillis == createdAtMillis &&
        other.isReversed == isReversed;
  }

  @override
  int get hashCode => Object.hash(
        id,
        habitId,
        localDateKey,
        baseXp,
        bonusXp,
        baseCoins,
        bonusCoins,
        Object.hashAll(appliedEffectIds),
        createdAtMillis,
        isReversed,
      );
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
