import 'package:flutter/material.dart';

class PillButton extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PillButton({
    super.key,
    required this.accent,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w700, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}
