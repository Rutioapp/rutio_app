import 'package:flutter/material.dart';
import 'package:rutio/utils/app_theme.dart';

import '../../../l10n/l10n.dart';
import '../../profile/widgets/section_card.dart';

class ProfileFields extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController bioCtrl;
  final VoidCallback onAnyFieldChanged;

  const ProfileFields({
    super.key,
    required this.nameCtrl,
    required this.bioCtrl,
    required this.onAnyFieldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: Listenable.merge([nameCtrl, bioCtrl]),
      builder: (context, _) {
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.person_outline_rounded,
                title: l10n.editProfilePersonalInfoTitle,
              ),
              const SizedBox(height: 12),
              _EditFieldShell(
                fieldKey: const Key('editProfileNameField'),
                controller: nameCtrl,
                isNameField: true,
                hint: l10n.editProfileNamePlaceholder,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                maxLines: 1,
                onChanged: onAnyFieldChanged,
              ),
              const SizedBox(height: 3),
              _FieldCounter(
                currentLength: nameCtrl.text.trim().length,
                maxLength: 50,
              ),
              const SizedBox(height: 12),
              _EditFieldShell(
                fieldKey: const Key('editProfileBioField'),
                controller: bioCtrl,
                isNameField: false,
                hint: l10n.editProfileBioHint,
                maxLength: 150,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                onChanged: onAnyFieldChanged,
              ),
              const SizedBox(height: 3),
              _FieldCounter(
                currentLength: bioCtrl.text.trim().length,
                maxLength: 150,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProfileGoalField extends StatelessWidget {
  final TextEditingController goalCtrl;
  final VoidCallback onChanged;

  const ProfileGoalField({
    super.key,
    required this.goalCtrl,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: goalCtrl,
      builder: (context, _) {
        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.gps_fixed_rounded,
                title: l10n.editProfilePersonalGoalSectionTitle,
              ),
              const SizedBox(height: 12),
              _EditFieldShell(
                fieldKey: const Key('editProfileGoalField'),
                controller: goalCtrl,
                isNameField: false,
                hint: l10n.editProfileGoalHint,
                maxLength: 100,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                onChanged: onChanged,
              ),
              const SizedBox(height: 3),
              _FieldCounter(
                currentLength: goalCtrl.text.trim().length,
                maxLength: 100,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2E241A),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditFieldShell extends StatelessWidget {
  const _EditFieldShell({
    required this.fieldKey,
    required this.controller,
    required this.isNameField,
    required this.hint,
    required this.maxLength,
    required this.maxLines,
    required this.textInputAction,
    required this.textCapitalization,
    required this.onChanged,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final bool isNameField;
  final String hint;
  final int maxLength;
  final int maxLines;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.earth.withValues(alpha: 0.16)),
      ),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        textInputAction: textInputAction,
        textCapitalization: textCapitalization,
        cursorColor: AppColors.earth,
        style: const TextStyle(
          fontSize: 14.5,
          height: 1.36,
          color: AppColors.ink,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: AppColors.earth.withValues(alpha: 0.76),
              width: 1.2,
            ),
          ),
          counterText: '',
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.inkSoft,
          ),
        ),
        validator: isNameField
            ? (v) {
                if (v == null || v.trim().isEmpty) {
                  return context.l10n.editProfileNameRequired;
                }
                if (v.trim().length < 2) {
                  return context.l10n.editProfileNameMinLength;
                }
                return null;
              }
            : null,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _FieldCounter extends StatelessWidget {
  const _FieldCounter({
    required this.currentLength,
    required this.maxLength,
  });

  final int currentLength;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$currentLength/$maxLength',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.inkFaint,
        ),
      ),
    );
  }
}
