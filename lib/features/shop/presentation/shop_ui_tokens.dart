import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class ShopUiTokens {
  ShopUiTokens._();

  static const Color background = AppColors.cream;
  static const Color backgroundAlt = AppColors.cream2;
  static const Color surface = Color(0xFFFDFBF6);
  static const Color surfaceMuted = Color(0xFFF3ECDD);
  static const Color surfaceRaised = Colors.white;
  static const Color stroke = Color(0x1F18180F);
  static const Color strokeStrong = Color(0x3318180F);
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = AppColors.inkSoft;
  static const Color textTertiary = AppColors.inkFaint;
  static const Color accent = AppColors.earth;
  static const Color accentSoft = Color(0x229E7540);
  static const Color success = AppColors.sage;
  static const Color successSoft = Color(0x1F4A8240);
  static const Color danger = AppColors.rust;
  static const Color shadow = Color(0x1218180F);
  static const Color coin = Color(0xFFE2B84D);
  static const Color coinSoft = Color(0x33E2B84D);
  static const Color placeholderCamel = Color(0xFFE0CCAF);
  static const Color placeholderSage = Color(0xFFC6D6BF);
  static const Color placeholderSand = Color(0xFFE7DDC8);
  static const Color placeholderClay = Color(0xFFD5B9A5);
  static const Color placeholderIce = Color(0xFFD6E6EA);
  static const Color placeholderCharcoal = Color(0xFF59554D);

  static const double radiusXs = 12;
  static const double radiusSm = 16;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusXl = 36;
  static const double borderWidth = 1;
  static const double headerIconSize = 18;
  static const double walletIconSize = 16;
  static const double cardPreviewHeight = 120;
  static const double categoryTileHeight = 104;
  static const double buttonHeight = 54;
  static const double minTouchTarget = 44;
  static const double sectionSpacing = 24;
  static const double itemSpacing = 16;
  static const double contentMaxWidth = 640;

  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(20, 16, 20, 24);
  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(4, 4, 4, 8);
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.only(bottom: 12);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets tilePadding = EdgeInsets.all(16);
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 10,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 20);
  static const EdgeInsets placeholderPadding = EdgeInsets.all(16);
  static const EdgeInsets emptyStatePadding = EdgeInsets.all(24);

  static BorderRadius get radiusXsShape => BorderRadius.circular(radiusXs);
  static BorderRadius get radiusSmShape => BorderRadius.circular(radiusSm);
  static BorderRadius get radiusMdShape => BorderRadius.circular(radiusMd);
  static BorderRadius get radiusLgShape => BorderRadius.circular(radiusLg);
  static BorderRadius get radiusXlShape => BorderRadius.circular(radiusXl);

  static List<BoxShadow> get softShadow => const <BoxShadow>[
        BoxShadow(
          color: shadow,
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ];
}

class ShopUiTextStyles {
  ShopUiTextStyles._();

  static const String _serif = AppTextStyles.serifFamily;
  static const String _sans = AppTextStyles.sansFamily;

  static const TextStyle pageTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 34,
    height: 1.02,
    letterSpacing: -0.8,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle headerTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 21,
    height: 1.02,
    letterSpacing: -0.2,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle headerTitleCompact = TextStyle(
    fontFamily: _serif,
    fontSize: 15,
    height: 1.02,
    letterSpacing: 0,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 24,
    height: 1.08,
    letterSpacing: -0.4,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: _serif,
    fontSize: 22,
    height: 1.1,
    letterSpacing: -0.3,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.45,
    color: ShopUiTokens.textSecondary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.42,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _sans,
    fontSize: 12,
    height: 1.35,
    color: ShopUiTokens.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: ShopUiTokens.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _sans,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: ShopUiTokens.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: ShopUiTokens.surfaceRaised,
  );

  static const TextStyle buttonDisabled = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: ShopUiTokens.textTertiary,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: _sans,
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.6,
    color: ShopUiTokens.textSecondary,
  );

  static const TextStyle wallet = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1,
    fontWeight: FontWeight.w700,
    color: ShopUiTokens.textPrimary,
  );
}
