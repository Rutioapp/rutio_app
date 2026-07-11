import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopHomeEntryTile extends StatelessWidget {
  const ShopHomeEntryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.arrow_outward_rounded,
    this.placeholderTone = ShopPreviewPlaceholderTone.camel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;
  final ShopPreviewPlaceholderTone placeholderTone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ShopUiTokens.surfaceRaised,
      borderRadius: ShopUiTokens.radiusLgShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
          decoration: BoxDecoration(
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(color: ShopUiTokens.stroke),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: ShopUiTextStyles.cardTitle.copyWith(fontSize: 19),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: ShopUiTextStyles.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 76,
                height: 84,
                child: ShopPreviewPlaceholder(
                  tone: placeholderTone,
                  icon: icon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
