import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class DiaryV2Styles {
  static const Color text = Color(0xFF5B3A25);
  static const Color textStrong = Color(0xFF3D291C);
  static const Color mutedText = Color(0xFF7F6C5E);
  static const Color mutedTextStrong = Color(0xFF6C584C);
  static const Color border = Color(0xFFE8DED2);
  static const Color cream = Color(0xFFFDF9F3);
  static const Color creamStrong = Color(0xFFF8F1E5);
  static const Color creamGlass = Color(0xF4FFFCF8);
  static const Color accent = Color(0xFFC98A47);
  static const Color accentSoft = Color(0xFFFFE7C8);
  static const Color accentSoftMuted = Color(0xFFFBEAD2);
  static const Color accentDeep = Color(0xFFB86E1C);
  static const Color sage = Color(0xFF9CAD7E);
  static const Color sageSoft = Color(0xFFEFF2E6);
  static const Color sageMuted = Color(0xFFC9D0B3);
  static const Color warmOverlay = Color(0xFFF7EBDD);
  static const Color dividerWarm = Color(0xFFEDE2D4);
  static const Color shadowWarm = Color(0x1F8A5A23);
  static const Color shadow = Color(0x14261A12);
  static const double cardRadius = 28;
  static const double compactCardRadius = 24;
  static const double sectionGap = 18;
  static const double weekStripOuterVerticalPadding = 5;
  static const double weekStripOuterHorizontalPadding = 4;
  static const double weekStripMinItemHeight = 66;
  static const double weekStripItemVerticalPadding = 6;
  static const double weekStripItemHorizontalPadding = 2;
  static const double weekStripSelectedHorizontalPadding = 10;
  static const double weekStripItemRadius = 17;
  static const double weekStripDayFontSize = 11;
  static const double weekStripDateFontSize = 14;
  static const double weekStripDotSize = 5;

  static BoxDecoration cardDecoration({bool accented = false}) {
    return BoxDecoration(
      color: accented ? creamStrong : creamGlass,
      borderRadius: BorderRadius.circular(cardRadius),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: shadow,
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
    );
  }

  static BoxDecoration compactCardDecoration({bool accented = false}) {
    return BoxDecoration(
      color: accented ? creamStrong : creamGlass,
      borderRadius: BorderRadius.circular(compactCardRadius),
      border: Border.all(color: border.withValues(alpha: 0.9)),
      boxShadow: const [
        BoxShadow(
          color: shadow,
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration softButtonDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.56)),
      boxShadow: const [
        BoxShadow(
          color: shadow,
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    );
  }

  static BoxDecoration subtleButtonDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.72),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: border.withValues(alpha: 0.5)),
      boxShadow: const [
        BoxShadow(
          color: shadow,
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static TextStyle title(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      color: text,
      fontFamily: AppTextStyles.serifFamily,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return Theme.of(context).textTheme.headlineSmall!.copyWith(
      color: text,
      fontFamily: AppTextStyles.serifFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.6,
    );
  }
}
