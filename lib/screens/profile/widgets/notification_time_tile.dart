import 'package:flutter/material.dart';

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
    final titleColor =
        canTap ? const Color(0xFF1A1A1A) : const Color(0xFF9A9A9A);
    final subtitleColor =
        canTap ? const Color(0xFF7A7A7A) : const Color(0xFFB0B0B0);

    return InkWell(
      onTap: canTap ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: enabled ? 1 : 0.7,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEFEFEF)),
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
                  color: canTap
                      ? const Color(0xFF6C5CE7)
                      : const Color(0xFFB0B0B0),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color:
                    canTap ? const Color(0xFFB0B0B0) : const Color(0xFFD0D0D0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
