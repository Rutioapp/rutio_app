import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';
import 'package:rutio/l10n/l10n.dart';

class MysteryBoxHeroView extends StatelessWidget {
  const MysteryBoxHeroView({
    super.key,
    required this.onTap,
    this.isPressed = false,
    this.assetPath = defaultAssetPath,
  });

  static const String defaultAssetPath =
      'assets/shop/utilities/mystery_box/mystery_box_closed.png';
  static const String openedAssetPath =
      'assets/shop/utilities/mystery_box/mystery_box_opened.png';
  static const double _sourceAspectRatio = 941 / 1673;

  final VoidCallback? onTap;
  final bool isPressed;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : mediaSize.width;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : mediaSize.height * 0.62;
        final safeWidth = math.max(0.0, maxWidth);
        final safeHeight = math.max(0.0, maxHeight);
        final cardWidth = math.max(120.0, math.min(safeWidth, 360.0));
        final cardHeight = math.max(
          210.0,
          math.min(safeHeight, cardWidth / _sourceAspectRatio),
        );

        return Semantics(
          button: onTap != null,
          label: l10n.shopMysteryBoxOpeningTitle,
          hint: l10n.shopMysteryBoxTapToOpen,
          child: GestureDetector(
            key: const Key('mysteryBoxHeroTapTarget'),
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: AnimatedScale(
              scale: isPressed ? 0.985 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: isPressed ? const Offset(0, 0.012) : Offset.zero,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      IgnorePointer(
                        child: Container(
                          width: cardWidth * 0.88,
                          height: cardHeight * 0.54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: ShopUiTokens.coinSoft
                                    .withValues(alpha: 0.46),
                                blurRadius: 60,
                                spreadRadius: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: ShopUiTokens.surfaceRaised.withValues(
                              alpha: isPressed ? 0.82 : 0.68,
                            ),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 28,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32),
                          child: AspectRatio(
                            aspectRatio: _sourceAspectRatio,
                            child: Image.asset(
                              assetPath,
                              key: const Key('mysteryBoxHeroImage'),
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
