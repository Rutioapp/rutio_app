import 'package:flutter/material.dart';
import 'package:rutio/features/shop/presentation/shop_ui_tokens.dart';

class ShopPageShell extends StatelessWidget {
  const ShopPageShell({
    super.key,
    this.header,
    required this.child,
    this.padding = ShopUiTokens.pagePadding,
    this.scrollable = true,
    this.bottomBar,
    this.backgroundColor = ShopUiTokens.background,
    this.extendBody = false,
    this.drawer,
  });

  final Widget? header;
  final Widget child;
  final EdgeInsets padding;
  final bool scrollable;
  final Widget? bottomBar;
  final Color backgroundColor;
  final bool extendBody;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: ShopUiTokens.contentMaxWidth),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (header != null) ...<Widget>[
                header!,
                const SizedBox(height: ShopUiTokens.sectionSpacing),
              ],
              child,
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: extendBody,
      drawer: drawer,
      body: SafeArea(
        bottom: bottomBar == null,
        child: scrollable
            ? SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: content,
              )
            : SizedBox.expand(child: content),
      ),
      bottomNavigationBar: bottomBar == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ShopUiTokens.contentMaxWidth,
                    ),
                    child: bottomBar,
                  ),
                ),
              ),
            ),
    );
  }
}
