import 'package:flutter/material.dart';

import '../../../../utils/app_theme.dart';

class HabitEditorHeader extends StatelessWidget {
  const HabitEditorHeader({
    super.key,
    required this.title,
    required this.familyColor,
    required this.onBack,
  });

  final String title;
  final Color familyColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
      child: Row(
        children: [
          _HabitEditorHeaderButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.authTitle.copyWith(
                fontSize: 24,
                color: const Color(0xFF3D2010),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: familyColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitEditorHeaderButton extends StatelessWidget {
  const _HabitEditorHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(184, 137, 90, 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromRGBO(184, 137, 90, 0.22)),
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFF3D2010),
          ),
        ),
      ),
    );
  }
}
