import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import 'diary_v2_styles.dart';

class DiaryV2WriteButton extends StatelessWidget {
  const DiaryV2WriteButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD48B2E),
            Color(0xFFC17A22),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2AA45F19),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 58,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: DiaryV2Styles.cream.withValues(alpha: 0.2),
              ),
            ),
            textStyle: AppTextStyles.btnLabel.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          icon: const Icon(CupertinoIcons.pencil_outline, size: 19),
          label: Text(label),
        ),
      ),
    );
  }
}
