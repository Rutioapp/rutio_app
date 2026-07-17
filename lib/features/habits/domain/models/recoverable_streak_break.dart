enum RecoverableStreakBreakStatus {
  recoverable,
  recovered,
  expired,
}

extension RecoverableStreakBreakStatusX on RecoverableStreakBreakStatus {
  String get key {
    switch (this) {
      case RecoverableStreakBreakStatus.recoverable:
        return 'recoverable';
      case RecoverableStreakBreakStatus.recovered:
        return 'recovered';
      case RecoverableStreakBreakStatus.expired:
        return 'expired';
    }
  }

  static RecoverableStreakBreakStatus? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'recoverable':
        return RecoverableStreakBreakStatus.recoverable;
      case 'recovered':
        return RecoverableStreakBreakStatus.recovered;
      case 'expired':
        return RecoverableStreakBreakStatus.expired;
      default:
        return null;
    }
  }
}

class RecoverableStreakBreak {
  const RecoverableStreakBreak({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.brokenAtMillis,
    required this.missedOccurrenceDateKey,
    required this.previousStreak,
    required this.currentStreakAfterBreak,
    required this.status,
    this.recoveredAtMillis,
    this.recoveryOperationId,
    this.shieldProtected = false,
  });

  final String id;
  final String userId;
  final String habitId;
  final int brokenAtMillis;
  final String missedOccurrenceDateKey;
  final int previousStreak;
  final int currentStreakAfterBreak;
  final RecoverableStreakBreakStatus status;
  final int? recoveredAtMillis;
  final String? recoveryOperationId;
  final bool shieldProtected;

  bool get isRecoverable => status == RecoverableStreakBreakStatus.recoverable;
  bool get isRecovered => status == RecoverableStreakBreakStatus.recovered;
  bool get isExpired => status == RecoverableStreakBreakStatus.expired;

  RecoverableStreakBreak copyWith({
    String? id,
    String? userId,
    String? habitId,
    int? brokenAtMillis,
    String? missedOccurrenceDateKey,
    int? previousStreak,
    int? currentStreakAfterBreak,
    RecoverableStreakBreakStatus? status,
    int? recoveredAtMillis,
    bool clearRecoveredAtMillis = false,
    String? recoveryOperationId,
    bool clearRecoveryOperationId = false,
    bool? shieldProtected,
  }) {
    return RecoverableStreakBreak(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      habitId: habitId ?? this.habitId,
      brokenAtMillis: brokenAtMillis ?? this.brokenAtMillis,
      missedOccurrenceDateKey:
          missedOccurrenceDateKey ?? this.missedOccurrenceDateKey,
      previousStreak: previousStreak ?? this.previousStreak,
      currentStreakAfterBreak:
          currentStreakAfterBreak ?? this.currentStreakAfterBreak,
      status: status ?? this.status,
      recoveredAtMillis: clearRecoveredAtMillis
          ? null
          : recoveredAtMillis ?? this.recoveredAtMillis,
      recoveryOperationId: clearRecoveryOperationId
          ? null
          : recoveryOperationId ?? this.recoveryOperationId,
      shieldProtected: shieldProtected ?? this.shieldProtected,
    );
  }

  factory RecoverableStreakBreak.fromJson(Map<String, dynamic> json) {
    return RecoverableStreakBreak(
      id: (json['id'] ?? '').toString().trim(),
      userId: (json['userId'] ?? '').toString().trim(),
      habitId: (json['habitId'] ?? '').toString().trim(),
      brokenAtMillis: (json['brokenAtMillis'] as num?)?.toInt() ?? 0,
      missedOccurrenceDateKey:
          (json['missedOccurrenceDateKey'] ?? '').toString().trim(),
      previousStreak: (json['previousStreak'] as num?)?.toInt() ?? 0,
      currentStreakAfterBreak:
          (json['currentStreakAfterBreak'] as num?)?.toInt() ?? 0,
      status:
          RecoverableStreakBreakStatusX.fromKey(json['status']?.toString()) ??
              RecoverableStreakBreakStatus.recoverable,
      recoveredAtMillis: (json['recoveredAtMillis'] as num?)?.toInt(),
      recoveryOperationId:
          (json['recoveryOperationId'] ?? '').toString().trim(),
      shieldProtected: json['shieldProtected'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'habitId': habitId,
      'brokenAtMillis': brokenAtMillis,
      'missedOccurrenceDateKey': missedOccurrenceDateKey,
      'previousStreak': previousStreak,
      'currentStreakAfterBreak': currentStreakAfterBreak,
      'status': status.key,
      if (recoveredAtMillis != null) 'recoveredAtMillis': recoveredAtMillis,
      if ((recoveryOperationId ?? '').trim().isNotEmpty)
        'recoveryOperationId': recoveryOperationId,
      'shieldProtected': shieldProtected,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecoverableStreakBreak &&
        other.id == id &&
        other.userId == userId &&
        other.habitId == habitId &&
        other.brokenAtMillis == brokenAtMillis &&
        other.missedOccurrenceDateKey == missedOccurrenceDateKey &&
        other.previousStreak == previousStreak &&
        other.currentStreakAfterBreak == currentStreakAfterBreak &&
        other.status == status &&
        other.recoveredAtMillis == recoveredAtMillis &&
        other.recoveryOperationId == recoveryOperationId &&
        other.shieldProtected == shieldProtected;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        habitId,
        brokenAtMillis,
        missedOccurrenceDateKey,
        previousStreak,
        currentStreakAfterBreak,
        status,
        recoveredAtMillis,
        recoveryOperationId,
        shieldProtected,
      );
}
