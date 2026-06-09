import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class DiaryV2Styles {
  static const Color text = Color(0xFF5B3A25);
  static const Color mutedText = Color(0xFF7F6C5E);
  static const Color border = Color(0xFFE8DED2);
  static const Color cream = Color(0xFFFDF9F3);
  static const Color creamStrong = Color(0xFFF8F1E5);
  static const Color accent = Color(0xFFC98A47);
  static const Color accentSoft = Color(0xFFFFE7C8);
  static const Color sage = Color(0xFF9CAD7E);
  static const Color sageSoft = Color(0xFFEFF2E6);
  static const Color shadow = Color(0x14261A12);

  static BoxDecoration cardDecoration({bool accented = false}) {
    return BoxDecoration(
      color: accented ? creamStrong : cream,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: border),
      boxShadow: const [
        BoxShadow(
          color: shadow,
          blurRadius: 18,
          offset: Offset(0, 8),
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
}
