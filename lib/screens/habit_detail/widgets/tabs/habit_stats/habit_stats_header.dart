import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../utils/app_theme.dart';

class HabitStatsHeader extends StatelessWidget {
  const HabitStatsHeader({
    super.key,
    required this.title,
    required this.familyColor,
    required this.familyAndGoal,
    this.onBackPressed,
    this.onMorePressed,
  });

  final String title;
  final Color familyColor;
  final String familyAndGoal;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onBackPressed,
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    CupertinoIcons.back,
                    size: 30,
                    color: Color(0xFF3D2010),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onMorePressed,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.55),
                    border: Border.all(
                      color: const Color(0xFFDFCFB9),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.ellipsis,
                    size: 24,
                    color: Color(0xFF3D2010),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppTextStyles.serifFamily,
              fontSize: 64,
              height: 0.96,
              letterSpacing: -1.3,
              color: Color(0xFF2E160A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: familyColor.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  familyAndGoal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.sansFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF53514A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
