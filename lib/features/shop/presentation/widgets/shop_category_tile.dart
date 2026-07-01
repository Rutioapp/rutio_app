import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/features/shop/presentation/widgets/shop_preview_placeholder.dart';

class ShopCategoryTile extends StatelessWidget {
  const ShopCategoryTile({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.onTap,
    this.placeholderTone = ShopPreviewPlaceholderTone.camel,
    this.leadingIcon = Icons.grid_view_rounded,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;
  final ShopPreviewPlaceholderTone placeholderTone;
  final IconData leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ShopUiTokens.surface : ShopUiTokens.surfaceRaised,
      borderRadius: ShopUiTokens.radiusLgShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: ShopUiTokens.radiusLgShape,
        child: Ink(
          height: ShopUiTokens.categoryTileHeight,
          padding: ShopUiTokens.tilePadding,
          decoration: BoxDecoration(
            borderRadius: ShopUiTokens.radiusLgShape,
            border: Border.all(
              color: selected
                  ? ShopUiTokens.accent.withValues(alpha: 0.4)
                  : ShopUiTokens.stroke,
            ),
            boxShadow: selected ? ShopUiTokens.softShadow : null,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: ShopUiTokens.backgroundAlt,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        leadingIcon,
                        size: 18,
                        color: ShopUiTokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ShopUiTextStyles.label.copyWith(
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ShopUiTextStyles.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 82,
                child: ShopPreviewPlaceholder(
                  tone: placeholderTone,
                  height: double.infinity,
                  icon: selected
                      ? Icons.check_circle_outline_rounded
                      : Icons.layers_outlined,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
