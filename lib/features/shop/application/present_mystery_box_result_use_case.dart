import 'package:rutio/features/shop/application/mystery_box_operation_result.dart';
import 'package:rutio/features/shop/application/open_mystery_box_use_case.dart';

class PresentMysteryBoxResultUseCase {
  PresentMysteryBoxResultUseCase(this._openMysteryBoxUseCase);

  final OpenMysteryBoxUseCase _openMysteryBoxUseCase;

  Future<MysteryBoxOperationResult> present({
    required String transactionId,
  }) {
    return _openMysteryBoxUseCase.markPresented(transactionId);
  }
}
