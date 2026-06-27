abstract final class RewardConstants {
  static const int habitCheckXpReward = 10;
  static const int habitCheckAmbarReward = 5;
  static const int dailyDiaryXpReward = 10;
  static const int dailyDiaryAmbarReward = 5;

  static int habitCountXpReward(num target) =>
      ((target / 5).ceil() * 2 + 5).clamp(5, 15);

  static int habitCountAmbarReward(num xpReward) =>
      (xpReward / 2).floor().clamp(0, 10);
}
