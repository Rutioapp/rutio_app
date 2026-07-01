import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopEmptyState extends StatelessWidget {
  const ShopEmptyState({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.inventory_2_outlined,
    this.action,
  });

  final String message;
  final String? title;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ShopUiTokens.surfaceRaised,
        borderRadius: ShopUiTokens.radiusLgShape,
        border: Border.all(color: ShopUiTokens.stroke),
      ),
      child: Padding(
        padding: ShopUiTokens.emptyStatePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: ShopUiTokens.backgroundAlt,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 24,
                color: ShopUiTokens.textPrimary,
              ),
            ),
            if (title != null && title!.trim().isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                title!,
                textAlign: TextAlign.center,
                style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 20),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ShopUiTextStyles.subtitle,
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
