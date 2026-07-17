enum ActiveStreakShieldStatus {
  armed,
  consumed,
  cancelled,
}

extension ActiveStreakShieldStatusX on ActiveStreakShieldStatus {
  String get key {
    switch (this) {
      case ActiveStreakShieldStatus.armed:
        return 'armed';
      case ActiveStreakShieldStatus.consumed:
        return 'consumed';
      case ActiveStreakShieldStatus.cancelled:
        return 'cancelled';
    }
  }

  static ActiveStreakShieldStatus? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'armed':
        return ActiveStreakShieldStatus.armed;
      case 'consumed':
        return ActiveStreakShieldStatus.consumed;
      case 'cancelled':
        return ActiveStreakShieldStatus.cancelled;
      default:
        return null;
    }
  }
}

class ActiveStreakShield {
  const ActiveStreakShield({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.utilityId,
    required this.activatedAtMillis,
    required this.status,
    required this.protectedOccurrenceDateKey,
    this.consumedAtMillis,
    this.operationId,
  });

  final String id;
  final String userId;
  final String habitId;
  final String utilityId;
  final int activatedAtMillis;
  final ActiveStreakShieldStatus status;
  final String? protectedOccurrenceDateKey;
  final int? consumedAtMillis;
  final String? operationId;

  bool get isActive => status == ActiveStreakShieldStatus.armed;
  bool get isConsumed => status == ActiveStreakShieldStatus.consumed;

  ActiveStreakShield copyWith({
    String? id,
    String? userId,
    String? habitId,
    String? utilityId,
    int? activatedAtMillis,
    ActiveStreakShieldStatus? status,
    String? protectedOccurrenceDateKey,
    bool clearProtectedOccurrenceDateKey = false,
    int? consumedAtMillis,
    bool clearConsumedAtMillis = false,
    String? operationId,
    bool clearOperationId = false,
  }) {
    return ActiveStreakShield(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      utilityId: utilityId ?? this.utilityId,
      activatedAtMillis: activatedAtMillis ?? this.activatedAtMillis,
      status: status ?? this.status,
      protectedOccurrenceDateKey: clearProtectedOccurrenceDateKey
          ? null
          : protectedOccurrenceDateKey ?? this.protectedOccurrenceDateKey,
      consumedAtMillis: clearConsumedAtMillis
          ? null
          : consumedAtMillis ?? this.consumedAtMillis,
      operationId: clearOperationId ? null : operationId ?? this.operationId,
    );
  }

  factory ActiveStreakShield.fromJson(Map<String, dynamic> json) {
    return ActiveStreakShield(
      id: (json['id'] ?? '').toString().trim(),
      userId: (json['userId'] ?? '').toString().trim(),
      habitId: (json['habitId'] ?? '').toString().trim(),
      utilityId:
          (json['utilityId'] ?? 'utility_streak_shield_1').toString().trim(),
      activatedAtMillis: (json['activatedAtMillis'] as num?)?.toInt() ?? 0,
      status: ActiveStreakShieldStatusX.fromKey(json['status']?.toString()) ??
          ActiveStreakShieldStatus.armed,
      protectedOccurrenceDateKey:
          (json['protectedOccurrenceDateKey'] ?? '').toString().trim(),
      consumedAtMillis: (json['consumedAtMillis'] as num?)?.toInt(),
      operationId: (json['operationId'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'habitId': habitId,
      'utilityId': utilityId,
      'activatedAtMillis': activatedAtMillis,
      'status': status.key,
      if ((protectedOccurrenceDateKey ?? '').trim().isNotEmpty)
        'protectedOccurrenceDateKey': protectedOccurrenceDateKey!.trim(),
      if (consumedAtMillis != null) 'consumedAtMillis': consumedAtMillis,
      if ((operationId ?? '').trim().isNotEmpty) 'operationId': operationId,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveStreakShield &&
        other.id == id &&
        other.userId == userId &&
        other.habitId == habitId &&
        other.utilityId == utilityId &&
        other.activatedAtMillis == activatedAtMillis &&
        other.status == status &&
        other.protectedOccurrenceDateKey == protectedOccurrenceDateKey &&
        other.consumedAtMillis == consumedAtMillis &&
        other.operationId == operationId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        habitId,
        utilityId,
        activatedAtMillis,
        status,
        protectedOccurrenceDateKey,
        consumedAtMillis,
        operationId,
      );
}
