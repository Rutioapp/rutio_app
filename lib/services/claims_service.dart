class ClaimsService {
  /// Reclama un milestone por ID si no está reclamado.
  /// Aplica currencyRewards (monedas).
  Map<String, dynamic> claimMilestone({
    required Map<String, dynamic> gameConfig,
    required Map<String, dynamic> userState,
    required String milestoneId,
  }) {
    final gc = gameConfig['gameConfig'] as Map<String, dynamic>;
    final claims = gc['claims'] as Map<String, dynamic>;
    final milestones =
        (claims['milestones'] as List).cast<Map<String, dynamic>>();

    final milestone = milestones.firstWhere(
      (m) => m['id'] == milestoneId,
      orElse: () => throw StateError('Milestone not found: $milestoneId'),
    );

    final us = userState['userState'] as Map<String, dynamic>;
    final claimed = (us['claims']?['milestonesClaimed'] as List).cast<String>();

    if (claimed.contains(milestoneId)) {
      throw StateError('Milestone already claimed.');
    }

    // Apply currencyRewards
    final wallet = us['wallet'] as Map<String, dynamic>;
    final currentCoins = (wallet['coins'] ?? 0) as int;

    final currencyRewards = (milestone['currencyRewards'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    int coinsToAdd = 0;
    for (final r in currencyRewards) {
      if (r['currencyId'] == 'coins') {
        coinsToAdd += (r['amount'] ?? 0) as int;
      }
    }

    wallet['coins'] = currentCoins + coinsToAdd;
    claimed.add(milestoneId);

    return userState;
  }
}
