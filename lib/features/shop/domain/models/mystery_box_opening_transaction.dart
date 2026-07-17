import 'mystery_box_reward_result.dart';

enum MysteryBoxOpeningStatus {
  resolved,
  granted,
  presented,
}

extension MysteryBoxOpeningStatusX on MysteryBoxOpeningStatus {
  String get key {
    switch (this) {
      case MysteryBoxOpeningStatus.resolved:
        return 'resolved';
      case MysteryBoxOpeningStatus.granted:
        return 'granted';
      case MysteryBoxOpeningStatus.presented:
        return 'presented';
    }
  }

  static MysteryBoxOpeningStatus? fromKey(String? key) {
    switch ((key ?? '').trim()) {
      case 'resolved':
        return MysteryBoxOpeningStatus.resolved;
      case 'granted':
        return MysteryBoxOpeningStatus.granted;
      case 'presented':
        return MysteryBoxOpeningStatus.presented;
      default:
        return null;
    }
  }
}

class MysteryBoxOpeningTransaction {
  const MysteryBoxOpeningTransaction({
    required this.id,
    required this.userScope,
    required this.mysteryBoxUtilityId,
    required this.reward,
    required this.createdAtMillis,
    required this.status,
  });

  final String id;
  final String userScope;
  final String mysteryBoxUtilityId;
  final MysteryBoxRewardResult reward;
  final int createdAtMillis;
  final MysteryBoxOpeningStatus status;

  bool get isGranted => status == MysteryBoxOpeningStatus.granted;
  bool get isPresented => status == MysteryBoxOpeningStatus.presented;
  bool get isResolved => status == MysteryBoxOpeningStatus.resolved;
  bool get isPendingPresentation =>
      status == MysteryBoxOpeningStatus.granted ||
      status == MysteryBoxOpeningStatus.resolved;

  MysteryBoxOpeningTransaction copyWith({
    String? id,
    String? userScope,
    String? mysteryBoxUtilityId,
    MysteryBoxRewardResult? reward,
    int? createdAtMillis,
    MysteryBoxOpeningStatus? status,
  }) {
    return MysteryBoxOpeningTransaction(
      id: id ?? this.id,
      userScope: userScope ?? this.userScope,
      mysteryBoxUtilityId: mysteryBoxUtilityId ?? this.mysteryBoxUtilityId,
      reward: reward ?? this.reward,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      status: status ?? this.status,
    );
  }

  factory MysteryBoxOpeningTransaction.fromJson(Map<String, dynamic> json) {
    return MysteryBoxOpeningTransaction(
      id: (json['id'] ?? '').toString(),
      userScope: (json['userScope'] ?? json['userScopeId'] ?? '').toString(),
      mysteryBoxUtilityId:
          (json['mysteryBoxUtilityId'] ?? json['utilityId'] ?? '').toString(),
      reward: MysteryBoxRewardResult.fromJson(
        (json['reward'] is Map)
            ? Map<String, dynamic>.from(json['reward'] as Map)
            : <String, dynamic>{},
      ),
      createdAtMillis: (json['createdAtMillis'] as num?)?.toInt() ?? 0,
      status: MysteryBoxOpeningStatusX.fromKey(json['status']?.toString()) ??
          MysteryBoxOpeningStatus.resolved,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userScope': userScope,
      'mysteryBoxUtilityId': mysteryBoxUtilityId,
      'reward': reward.toJson(),
      'createdAtMillis': createdAtMillis,
      'status': status.key,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MysteryBoxOpeningTransaction &&
        other.id == id &&
        other.userScope == userScope &&
        other.mysteryBoxUtilityId == mysteryBoxUtilityId &&
        other.reward == reward &&
        other.createdAtMillis == createdAtMillis &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userScope,
        mysteryBoxUtilityId,
        reward,
        createdAtMillis,
        status,
      );
}
