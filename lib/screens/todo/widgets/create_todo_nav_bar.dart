import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/utils/app_theme.dart';

class CreateTodoNavBar extends StatelessWidget {
  const CreateTodoNavBar({
    super.key,
    required this.title,
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    required this.isSaveEnabled,
  });

  final String title;
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isSaveEnabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0xFFD9CFC0),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            _NavActionButton(
              label: cancelLabel,
              onTap: onCancel,
              variant: _NavActionVariant.secondary,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.authTitle.copyWith(
                  fontSize: 20,
                  color: TodoStyleResolver.textPrimary,
                ),
              ),
            ),
            _NavActionButton(
              label: saveLabel,
              onTap: isSaveEnabled ? onSave : null,
              isEnabled: isSaveEnabled,
              variant: isSaveEnabled
                  ? _NavActionVariant.primary
                  : _NavActionVariant.secondaryMuted,
            ),
          ],
        ),
      ],
    );
  }
}

class _NavActionButton extends StatelessWidget {
  const _NavActionButton({
    required this.label,
    required this.onTap,
    this.isEnabled = true,
    this.variant = _NavActionVariant.secondary,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isEnabled;
  final _NavActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final bool isPrimary = variant == _NavActionVariant.primary;
    final Color background = switch (variant) {
      _NavActionVariant.primary => TodoStyleResolver.accent,
      _NavActionVariant.secondary => Colors.white.withValues(alpha: 0.44),
      _NavActionVariant.secondaryMuted => Colors.white.withValues(alpha: 0.34),
    };
    final Color border = switch (variant) {
      _NavActionVariant.primary => TodoStyleResolver.accent,
      _NavActionVariant.secondary => Colors.white.withValues(alpha: 0.54),
      _NavActionVariant.secondaryMuted => Colors.white.withValues(alpha: 0.40),
    };
    final Color textColor = switch (variant) {
      _NavActionVariant.primary => Colors.white,
      _NavActionVariant.secondary => TodoStyleResolver.accentSoft,
      _NavActionVariant.secondaryMuted => const Color(0xFFD8CCBC),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 90),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: border,
          ),
          boxShadow: isPrimary
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.fieldInput.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isEnabled ? textColor : const Color(0xFFD8CCBC),
          ),
        ),
      ),
    );
  }
}

enum _NavActionVariant {
  primary,
  secondary,
  secondaryMuted,
}
