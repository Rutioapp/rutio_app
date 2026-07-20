class HabitRewardTransaction {
  const HabitRewardTransaction({
    required this.id,
    required this.habitId,
    required this.localDateKey,
    this.completionEventId,
    this.applyRequestId,
    this.reverseRequestId,
    this.cloudOperationType,
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
  final String? completionEventId;
  final String? applyRequestId;
  final String? reverseRequestId;
  final String? cloudOperationType;
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
    String? completionEventId,
    String? applyRequestId,
    String? reverseRequestId,
    String? cloudOperationType,
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
      completionEventId: completionEventId ?? this.completionEventId,
      applyRequestId: applyRequestId ?? this.applyRequestId,
      reverseRequestId: reverseRequestId ?? this.reverseRequestId,
      cloudOperationType: cloudOperationType ?? this.cloudOperationType,
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
      completionEventId: _nullableTrim(json['completionEventId']),
      applyRequestId: _nullableTrim(json['applyRequestId']),
      reverseRequestId: _nullableTrim(json['reverseRequestId']),
      cloudOperationType: _nullableTrim(json['cloudOperationType']),
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
      'completionEventId': completionEventId,
      'applyRequestId': applyRequestId,
      'reverseRequestId': reverseRequestId,
      'cloudOperationType': cloudOperationType,
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
        other.completionEventId == completionEventId &&
        other.applyRequestId == applyRequestId &&
        other.reverseRequestId == reverseRequestId &&
        other.cloudOperationType == cloudOperationType &&
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
        completionEventId,
        applyRequestId,
        reverseRequestId,
        cloudOperationType,
        baseXp,
        bonusXp,
        baseCoins,
        bonusCoins,
        Object.hashAll(appliedEffectIds),
        createdAtMillis,
        isReversed,
      );
}

String? _nullableTrim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

bool _listEquals(List<String> a, List<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
