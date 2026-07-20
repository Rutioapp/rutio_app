import 'dart:convert';

import '../../domain/models/mystery_box_opening_transaction.dart';
import '../../domain/models/mystery_box_reward_result.dart';

enum RemoteMysteryBoxRewardType {
  coins,
  xp,
  utility,
  cosmetic,
  unknown,
}

extension RemoteMysteryBoxRewardTypeX on RemoteMysteryBoxRewardType {
  static RemoteMysteryBoxRewardType fromKey(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'coins':
      case 'coin':
        return RemoteMysteryBoxRewardType.coins;
      case 'xp':
        return RemoteMysteryBoxRewardType.xp;
      case 'utility':
        return RemoteMysteryBoxRewardType.utility;
      case 'cosmetic':
        return RemoteMysteryBoxRewardType.cosmetic;
      default:
        return RemoteMysteryBoxRewardType.unknown;
    }
  }

  String? get dbKey {
    switch (this) {
      case RemoteMysteryBoxRewardType.coins:
        return 'coins';
      case RemoteMysteryBoxRewardType.xp:
        return 'xp';
      case RemoteMysteryBoxRewardType.utility:
        return 'utility';
      case RemoteMysteryBoxRewardType.cosmetic:
        return 'cosmetic';
      case RemoteMysteryBoxRewardType.unknown:
        return null;
    }
  }
}

class RemoteMysteryBoxRewardDto {
  const RemoteMysteryBoxRewardDto({
    required this.rewardId,
    required this.rewardType,
    required this.quantity,
    required this.weight,
    required this.rarity,
    required this.isActive,
    required this.catalogVersion,
    required this.coins,
    required this.xp,
    required this.utilityRewards,
    required this.maxQuantity,
  });

  final String rewardId;
  final RemoteMysteryBoxRewardType rewardType;
  final int quantity;
  final int weight;
  final String? rarity;
  final bool isActive;
  final int catalogVersion;
  final int coins;
  final int xp;
  final Map<String, int> utilityRewards;
  final int? maxQuantity;

  factory RemoteMysteryBoxRewardDto.fromJson(Map<String, dynamic> json) {
    final rawUtilityRewards = json['utilityRewards'] ?? json['utility_rewards'];
    final utilityRewards = <String, int>{};
    if (rawUtilityRewards is Map) {
      for (final entry in rawUtilityRewards.entries) {
        final key = entry.key.toString().trim();
        final value = (entry.value as num?)?.toInt() ?? 0;
        if (key.isEmpty || value <= 0) continue;
        utilityRewards[key] = value;
      }
    }

    final rewardId = _trim(json['rewardId'] ?? json['reward_id']);
    final quantity =
        _int(json['quantity'] ?? json['rewardQuantity'] ?? json['reward_quantity']);
    final weight = _int(json['weight']);
    final catalogVersion =
        _int(json['catalogVersion'] ?? json['catalog_version']);
    final rewardType =
        RemoteMysteryBoxRewardTypeX.fromKey(
          json['rewardType'] ?? json['reward_type'] ?? json['type'],
        );
    final coins = _int(json['coins'] ?? json['coinDelta'] ?? json['coin_delta']);
    final xp = _int(json['xp'] ?? json['xpDelta'] ?? json['xp_delta']);
    final isActive = _bool(json['isActive'] ?? json['is_active']);

    if (rewardId == null ||
        rewardId.isEmpty ||
        quantity == null ||
        quantity < 0 ||
        weight == null ||
        weight <= 0 ||
        rewardType == RemoteMysteryBoxRewardType.unknown ||
        catalogVersion == null ||
        catalogVersion < 1) {
      throw const FormatException('Invalid mystery box reward payload.');
    }

    return RemoteMysteryBoxRewardDto(
      rewardId: rewardId,
      rewardType: rewardType,
      quantity: quantity,
      weight: weight,
      rarity: _nullableTrim(json['rarity'] ?? json['reward_rarity']),
      isActive: isActive,
      catalogVersion: catalogVersion,
      coins: coins ?? 0,
      xp: xp ?? 0,
      utilityRewards: Map<String, int>.unmodifiable(utilityRewards),
      maxQuantity: _nullableInt(json['maxQuantity'] ?? json['max_quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'rewardId': rewardId,
      'rewardType': rewardType.dbKey,
      'quantity': quantity,
      'weight': weight,
      'rarity': rarity,
      'isActive': isActive,
      'catalogVersion': catalogVersion,
      'coins': coins,
      'xp': xp,
      'utilityRewards': Map<String, int>.from(utilityRewards),
      'maxQuantity': maxQuantity,
    };
  }

  MysteryBoxRewardResult toRewardResult() {
    final utilityRewards = <String, int>{};
    for (final entry in this.utilityRewards.entries) {
      utilityRewards[entry.key] = entry.value;
    }

    return MysteryBoxRewardResult(
      rewardId: rewardId,
      coins: coins,
      xp: xp,
      utilityRewards: utilityRewards,
    );
  }
}

class RemoteMysteryBoxOpeningResultDto {
  const RemoteMysteryBoxOpeningResultDto({
    required this.requestId,
    required this.operation,
    required this.userId,
    required this.mysteryBoxUtilityId,
    required this.reward,
    required this.createdAt,
    required this.balanceAfter,
    required this.walletVersion,
    required this.remainingBoxes,
  });

  final String requestId;
  final String operation;
  final String userId;
  final String mysteryBoxUtilityId;
  final RemoteMysteryBoxRewardDto reward;
  final DateTime createdAt;
  final int balanceAfter;
  final int walletVersion;
  final int remainingBoxes;

  factory RemoteMysteryBoxOpeningResultDto.fromRpcResponse(
    Object? response, {
    required String requestId,
    required String expectedUserId,
  }) {
    final payload = _extractMap(response);
    if (payload == null) {
      throw const FormatException('Invalid mystery box response payload.');
    }

    final normalizedRequestId =
        _trim(payload['requestId'] ?? payload['request_id']);
    final operation = _trim(payload['operation']);
    final userId = _trim(payload['userId'] ?? payload['user_id']);
    final mysteryBoxUtilityId =
        _trim(payload['mysteryBoxUtilityId'] ?? payload['mystery_box_utility_id']);
    final rewardPayload = payload['reward'];
    final balanceAfter = _int(payload['balanceAfter'] ?? payload['balance_after']);
    final walletVersion =
        _int(payload['walletVersion'] ?? payload['wallet_version']);
    final remainingBoxes =
        _int(payload['remainingBoxes'] ?? payload['remaining_boxes']);
    final rewardType = rewardPayload is Map
        ? _trim(
            rewardPayload['rewardType'] ??
                rewardPayload['reward_type'] ??
                rewardPayload['type'],
          )
        : null;
    final createdAt = _dateTime(payload['createdAt'] ?? payload['created_at']);

    if (normalizedRequestId == null ||
        normalizedRequestId != requestId.trim() ||
        operation != 'open' ||
        userId == null ||
        userId != expectedUserId.trim() ||
        mysteryBoxUtilityId == null ||
        rewardPayload is! Map ||
        rewardType == null ||
        balanceAfter == null ||
        balanceAfter < 0 ||
        walletVersion == null ||
        walletVersion < 0 ||
        remainingBoxes == null ||
        remainingBoxes < 0 ||
        createdAt == null) {
      throw const FormatException('Invalid mystery box response payload.');
    }

    return RemoteMysteryBoxOpeningResultDto(
      requestId: normalizedRequestId,
      operation: operation ?? '',
      userId: userId,
      mysteryBoxUtilityId: mysteryBoxUtilityId,
      reward: RemoteMysteryBoxRewardDto.fromJson(
        Map<String, dynamic>.from(rewardPayload),
      ),
      createdAt: createdAt.toUtc(),
      balanceAfter: balanceAfter,
      walletVersion: walletVersion,
      remainingBoxes: remainingBoxes,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'requestId': requestId,
      'operation': operation,
      'userId': userId,
      'mysteryBoxUtilityId': mysteryBoxUtilityId,
      'reward': reward.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'balanceAfter': balanceAfter,
      'walletVersion': walletVersion,
      'remainingBoxes': remainingBoxes,
    };
  }

  MysteryBoxOpeningTransaction toTransaction() {
    return MysteryBoxOpeningTransaction(
      id: requestId,
      userScope: userId,
      mysteryBoxUtilityId: mysteryBoxUtilityId,
      reward: reward.toRewardResult(),
      createdAtMillis: createdAt.millisecondsSinceEpoch,
      status: MysteryBoxOpeningStatus.granted,
    );
  }
}

Map<String, dynamic>? _extractMap(Object? response) {
  if (response == null) return null;
  if (response is Map<String, dynamic>) return response;
  if (response is Map) {
    return Map<String, dynamic>.from(response.cast<String, dynamic>());
  }
  if (response is List && response.isNotEmpty) {
    final first = response.first;
    if (first is Map<String, dynamic>) return first;
    if (first is Map) {
      return Map<String, dynamic>.from(first.cast<String, dynamic>());
    }
  }
  if (response is String) {
    final trimmed = response.trim();
    if (trimmed.isEmpty) return null;
    final decoded = jsonDecode(trimmed);
    return _extractMap(decoded);
  }
  return null;
}

String? _trim(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString().trim());
}

int? _nullableInt(Object? value) => _int(value);

bool _bool(Object? value) {
  if (value is bool) return value;
  final normalized = (value ?? '').toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final normalized = value.toString().trim();
  if (normalized.isEmpty) return null;
  return DateTime.tryParse(normalized);
}

String? _nullableTrim(Object? value) => _trim(value);
