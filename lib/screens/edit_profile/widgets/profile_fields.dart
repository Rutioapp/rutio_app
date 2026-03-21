import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

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
    return Column(
      children: [
        _NameField(controller: nameCtrl, onChanged: onAnyFieldChanged),
        const SizedBox(height: 16),
        _BioField(controller: bioCtrl, onChanged: onAnyFieldChanged),
      ],
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
    return _GoalField(controller: goalCtrl, onChanged: onChanged);
  }
}

class _NameField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NameField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      maxLength: 50,
      decoration: InputDecoration(
        labelText: context.l10n.editProfileNameLabel,
        hintText: context.l10n.editProfileNameHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.badge_outlined),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return context.l10n.editProfileNameRequired;
        }
        if (v.trim().length < 2) return context.l10n.editProfileNameMinLength;
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}

class _BioField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _BioField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      maxLength: 150,
      decoration: InputDecoration(
        labelText: context.l10n.editProfileBioLabel,
        hintText: context.l10n.editProfileBioHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Icon(Icons.article_outlined),
        ),
        alignLabelWithHint: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _GoalField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      maxLength: 100,
      decoration: InputDecoration(
        labelText: context.l10n.editProfileGoalLabel,
        hintText: context.l10n.editProfileGoalHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Icon(Icons.emoji_events_outlined),
        ),
        alignLabelWithHint: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
