import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class AccountActionSettingsRow extends StatelessWidget {
  const AccountActionSettingsRow({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.earth.withValues(alpha: 0.12)),
            color: AppColors.cream2,
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.square_arrow_right,
                  size: 18,
                  color: AppColors.earth,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.earth,
                  ),
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: AppColors.earthSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
