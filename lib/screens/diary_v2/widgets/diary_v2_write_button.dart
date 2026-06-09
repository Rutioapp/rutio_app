import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

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
    return SizedBox(
      height: 62,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC98327),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                textStyle: AppTextStyles.btnLabel.copyWith(fontSize: 15),
              ),
              icon: const Icon(CupertinoIcons.pencil_outline, size: 20),
              label: Text(label),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 8,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFD48B2B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26261A12),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.pencil,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
