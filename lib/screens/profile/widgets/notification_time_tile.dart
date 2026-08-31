import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

class NotificationTimeTile extends StatelessWidget {
  const NotificationTimeTile({
    super.key,
    required this.title,
    required this.valueLabel,
    this.subtitle,
    this.enabled = true,
    this.onTap,
  });

  final String title;
  final String valueLabel;
  final String? subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;
    final titleColor = canTap ? AppColors.ink : AppColors.inkSoft;
    final subtitleColor = canTap ? AppColors.inkSoft : AppColors.inkFaint;

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.earth.withValues(alpha: 0.10)),
            color: AppColors.cream,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(fontSize: 12.5, color: subtitleColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: canTap ? AppColors.earth : AppColors.inkFaint,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: canTap ? AppColors.earthSoft : AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
