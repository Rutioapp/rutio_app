import 'models/mystery_box_opening_transaction.dart';

abstract interface class MysteryBoxOpeningRepository {
  Future<List<MysteryBoxOpeningTransaction>> loadTransactions(String userScope);

  Future<void> saveTransactions(
    String userScope,
    List<MysteryBoxOpeningTransaction> transactions,
  );
}
