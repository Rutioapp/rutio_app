import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'diary_v2_styles.dart';

class DiaryV2EditorHeader extends StatelessWidget {
  const DiaryV2EditorHeader({
    super.key,
    required this.title,
    required this.saveLabel,
    required this.onClose,
    required this.onSave,
  });

  final String title;
  final String saveLabel;
  final VoidCallback onClose;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _RoundIconButton(
          icon: CupertinoIcons.xmark,
          onTap: onClose,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DiaryV2Styles.title(context).copyWith(
                fontSize: 24,
                color: DiaryV2Styles.textStrong,
                height: 1.1,
              ),
            ),
          ),
        ),
        _SavePillButton(
          label: saveLabel,
          onTap: onSave,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DiaryV2Styles.subtleButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(
              icon,
              color: DiaryV2Styles.textStrong,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavePillButton extends StatelessWidget {
  const _SavePillButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: DiaryV2Styles.subtleButtonDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DiaryV2Styles.accentDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
