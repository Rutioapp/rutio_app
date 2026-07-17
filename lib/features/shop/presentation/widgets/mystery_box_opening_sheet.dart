import 'package:flutter/material.dart';
import 'package:rutio/features/shop/domain/models/mystery_box_opening_transaction.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/mystery_box_reward_view.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_primary_button.dart';
import 'package:rutio/l10n/l10n.dart';

class MysteryBoxOpeningSheet extends StatelessWidget {
  const MysteryBoxOpeningSheet({
    super.key,
    required this.transaction,
    required this.isPresenting,
    required this.onContinue,
    this.errorMessage,
  });

  final MysteryBoxOpeningTransaction transaction;
  final bool isPresenting;
  final VoidCallback onContinue;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.74;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: maxHeight,
        ),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: ShopUiTokens.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: SingleChildScrollView(
            child: Column(
              key: const Key('mysteryBoxRewardSheetContent'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ShopUiTokens.stroke,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.shopMysteryBoxRewardTitle,
                  textAlign: TextAlign.center,
                  style: ShopUiTextStyles.pageTitle.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.shopMysteryBoxRewardDescription,
                  textAlign: TextAlign.center,
                  style: ShopUiTextStyles.bodySmall,
                ),
                const SizedBox(height: 28),
                MysteryBoxRewardView(
                  key: const Key('mysteryBoxRewardView'),
                  transaction: transaction,
                  showIntroCopy: false,
                  reducedMotion:
                      MediaQuery.maybeOf(context)?.disableAnimations ?? false,
                ),
                if (errorMessage != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: ShopUiTextStyles.bodySmall.copyWith(
                      color: ShopUiTokens.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                ShopPrimaryButton(
                  key: const Key('mysteryBoxContinueButton'),
                  label: isPresenting
                      ? l10n.shopProcessingLabel
                      : l10n.shopActionAccept,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: isPresenting ? null : onContinue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
