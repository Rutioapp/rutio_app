class MysteryBoxRewardResult {
  MysteryBoxRewardResult({
    required this.rewardId,
    required this.coins,
    required this.xp,
    required Map<String, int> utilityRewards,
  }) : utilityRewards = Map<String, int>.unmodifiable(
          Map<String, int>.from(utilityRewards),
        );

  final String rewardId;
  final int coins;
  final int xp;
  final Map<String, int> utilityRewards;

  bool get hasCoins => coins > 0;
  bool get hasXp => xp > 0;
  bool get hasUtilityRewards => utilityRewards.isNotEmpty;

  MysteryBoxRewardResult copyWith({
    String? rewardId,
    int? coins,
    int? xp,
    Map<String, int>? utilityRewards,
  }) {
    return MysteryBoxRewardResult(
      rewardId: rewardId ?? this.rewardId,
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      utilityRewards: utilityRewards ?? this.utilityRewards,
    );
  }

  factory MysteryBoxRewardResult.fromJson(Map<String, dynamic> json) {
    final rawUtilityRewards = json['utilityRewards'];
    final utilityRewards = <String, int>{};
    if (rawUtilityRewards is Map) {
      for (final entry in rawUtilityRewards.entries) {
        final key = entry.key.toString().trim();
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (key.isEmpty) continue;
        utilityRewards[key] = value;
      }
    }

    return MysteryBoxRewardResult(
      rewardId: (json['rewardId'] ?? '').toString(),
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      utilityRewards: Map<String, int>.unmodifiable(utilityRewards),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rewardId': rewardId,
      'coins': coins,
      'xp': xp,
      'utilityRewards': Map<String, int>.from(utilityRewards),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MysteryBoxRewardResult &&
        other.rewardId == rewardId &&
        other.coins == coins &&
        other.xp == xp &&
        _mapEquals(other.utilityRewards, utilityRewards);
  }

  @override
  int get hashCode => Object.hash(
        rewardId,
        coins,
        xp,
        Object.hashAll(
          utilityRewards.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
      );
}

bool _mapEquals(Map<String, int> a, Map<String, int> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}
