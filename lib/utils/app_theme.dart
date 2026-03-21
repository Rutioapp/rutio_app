import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Core
  static const ink = Color(0xFF18180F);
  static const inkSoft = Color(0x8018180F);
  static const inkFaint = Color(0x5218180F);
  static const cream = Color(0xFFF6F2E9);
  static const cream2 = Color(0xFFEDE8DA);

  // Accent
  static const earth = Color(0xFF9E7540);
  static const earthSoft = Color(0xB29E7540);
  static const sage = Color(0xFF4A8240);
  static const sageSoft = Color(0x734A8240);
  static const rust = Color(0xFFC24A28);

  // Sky gradient stops
  static const skyTop = Color(0xFFEAF3FB);
  static const skyMid1 = Color(0xFFD6EAF6);
  static const skyMid2 = Color(0xFFC8DDED);
  static const skyBottom = Color(0xFFD4CAAC);

  // Ground progression
  static const groundDry = Color(0xFFBAA460);
  static const groundSprout = Color(0xFFB2A260);
  static const groundGrass = Color(0xFF569620); // login
  static const groundLush = Color(0xFF2E6820); // signup

  // Green gradient bottoms
  static const hillLoginTop = Color(0xFFE4F0F8);
  static const hillLoginBottom = Color(0xFF8AB85A);
  static const hillSignupTop = Color(0xFFE0F0F8);
  static const hillSignupBottom = Color(0xFF3E8828);

  // Flowers
  static const flowerYellow = Color(0xFFE8C44C);
  static const flowerPink = Color(0xFFD86074);
}

class AppTextStyles {
  static const serifFamily = 'DMSerifDisplay';
  static const sansFamily = 'DMSans';

  static const splash = TextStyle(
    fontFamily: serifFamily,
    fontSize: 46,
    color: AppColors.ink,
    letterSpacing: -2,
    height: 1,
  );

  static const tagline = TextStyle(
    fontFamily: sansFamily,
    fontSize: 9.5,
    color: AppColors.earth,
    letterSpacing: 3.8,
  );

  static const welcomeEyebrow = TextStyle(
    fontFamily: sansFamily,
    fontSize: 10,
    color: AppColors.earth,
    letterSpacing: 2.5,
    fontWeight: FontWeight.w500,
  );

  static const welcomeTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 29,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1.18,
  );

  static const welcomeSub = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12.5,
    color: AppColors.inkSoft,
    height: 1.6,
  );

  /// Alias para pantallas que esperan `welcomeSubtitle`
  /// (mantiene compatibilidad y evita errores de getters inexistentes).
  static const welcomeSubtitle = welcomeSub;

  /// Texto pequeño "RUTIO" / eyebrow (kicker) en welcome.
  /// Si ya usas `welcomeEyebrow`, este es un alias más semántico.
  static const welcomeKicker = welcomeEyebrow;

  static const authTitle = TextStyle(
    fontFamily: serifFamily,
    fontSize: 22,
    color: AppColors.ink,
    letterSpacing: -0.3,
  );

  static const authSub = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12,
    color: AppColors.inkSoft,
    height: 1.5,
  );

  static const fieldLabel = TextStyle(
    fontFamily: sansFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.sage,
    letterSpacing: 1.6,
  );

  static const fieldInput = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    color: AppColors.ink,
  );

  static const fieldHint = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    color: AppColors.inkFaint,
  );

  static const forgot = TextStyle(
    fontFamily: sansFamily,
    fontSize: 11,
    color: AppColors.earth,
    letterSpacing: 0.1,
  );

  static const btnLabel = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.cream,
  );

  static const btnOutlineLabel = TextStyle(
    fontFamily: sansFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.ink,
  );

  /// Alias semánticos para evitar inconsistencias entre pantallas.
  static const buttonPrimary = btnLabel;
  static const buttonOutline = btnOutlineLabel;

  static const authSwitch = TextStyle(
    fontFamily: sansFamily,
    fontSize: 11.5,
    color: AppColors.inkFaint,
  );

  static const authSwitchLink = TextStyle(
    fontFamily: sansFamily,
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.rust,
  );

  static const brandName = TextStyle(
    fontFamily: serifFamily,
    fontSize: 26,
    color: AppColors.ink,
    letterSpacing: -0.5,
    height: 1,
  );

  static const brandSub = TextStyle(
    fontFamily: sansFamily,
    fontSize: 9.5,
    color: AppColors.earth,
    letterSpacing: 2.2,
  );

  static const drawerSection = TextStyle(
    fontFamily: sansFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 3.0,
    color: Color(0xFFB2A58B),
    height: 1.0,
  );

  static const drawerItem = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.ink,
    height: 1.0,
  );

  static const drawerItemActive = TextStyle(
    fontFamily: sansFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.0,
  );

  static const drawerFooter = TextStyle(
    fontFamily: sansFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkSoft,
    height: 1.0,
  );
}

class AppTheme {
  // IOS-FIRST IMPROVEMENT START
  static TextTheme _buildTextTheme(TextTheme base) {
    TextStyle serif(TextStyle? style) {
      return (style ?? const TextStyle()).copyWith(
        fontFamily: AppTextStyles.serifFamily,
        color: AppColors.ink,
      );
    }

    TextStyle sans(TextStyle? style) {
      return (style ?? const TextStyle()).copyWith(
        fontFamily: AppTextStyles.sansFamily,
        color: AppColors.ink,
      );
    }

    return base.copyWith(
      displayLarge: serif(base.displayLarge).copyWith(
        fontSize: 38,
        height: 1.0,
        letterSpacing: -1.0,
      ),
      displayMedium: serif(base.displayMedium).copyWith(
        fontSize: 32,
        height: 1.02,
        letterSpacing: -0.8,
      ),
      displaySmall: serif(base.displaySmall).copyWith(
        fontSize: 28,
        height: 1.04,
        letterSpacing: -0.6,
      ),
      headlineLarge: serif(base.headlineLarge).copyWith(
        fontSize: 26,
        height: 1.06,
        letterSpacing: -0.5,
      ),
      headlineMedium: serif(base.headlineMedium).copyWith(
        fontSize: 22,
        height: 1.08,
        letterSpacing: -0.4,
      ),
      headlineSmall: serif(base.headlineSmall).copyWith(
        fontSize: 20,
        height: 1.1,
        letterSpacing: -0.3,
      ),
      titleLarge: serif(base.titleLarge).copyWith(
        fontSize: 20,
        height: 1.08,
        letterSpacing: -0.2,
      ),
      titleMedium: sans(base.titleMedium).copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: sans(base.titleSmall).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: sans(base.bodyLarge).copyWith(
        fontSize: 16,
        height: 1.45,
      ),
      bodyMedium: sans(base.bodyMedium).copyWith(
        fontSize: 14,
        height: 1.42,
      ),
      bodySmall: sans(base.bodySmall).copyWith(
        fontSize: 12,
        height: 1.35,
        color: AppColors.inkSoft,
      ),
      labelLarge: sans(base.labelLarge).copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: sans(base.labelMedium).copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: sans(base.labelSmall).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );
  }

  static CupertinoThemeData _buildCupertinoTheme() {
    return const CupertinoThemeData(
      primaryColor: AppColors.ink,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: AppTextStyles.sansFamily,
          color: AppColors.ink,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: AppTextStyles.serifFamily,
          fontSize: 20,
          color: AppColors.ink,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: AppTextStyles.serifFamily,
          fontSize: 34,
          color: AppColors.ink,
          letterSpacing: -0.8,
        ),
        navActionTextStyle: TextStyle(
          fontFamily: AppTextStyles.sansFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        actionTextStyle: TextStyle(
          fontFamily: AppTextStyles.sansFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabLabelTextStyle: TextStyle(
          fontFamily: AppTextStyles.sansFamily,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  // IOS-FIRST IMPROVEMENT END

  static ThemeData get theme => ThemeData(
        fontFamily: AppTextStyles.sansFamily,
        textTheme: _buildTextTheme(ThemeData.light().textTheme),
        primaryTextTheme: _buildTextTheme(ThemeData.light().primaryTextTheme),
        cupertinoOverrideTheme: _buildCupertinoTheme(),
        scaffoldBackgroundColor: AppColors.cream,
        colorScheme: const ColorScheme.light(
          primary: AppColors.ink,
          secondary: AppColors.sage,
          surface: AppColors.cream,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.68),
          hintStyle: AppTextStyles.fieldHint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: const Color(0xFF283C1E).withValues(alpha: 0.13),
                width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: const Color(0xFF283C1E).withValues(alpha: 0.13),
                width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.sageSoft, width: 1.5),
          ),
        ),
      );
}
