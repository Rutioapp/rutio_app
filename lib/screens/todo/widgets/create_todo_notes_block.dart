import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';
import 'package:rutio/screens/todo/widgets/todo_section_label.dart';
import 'package:rutio/utils/app_theme.dart';

class CreateTodoNotesBlock extends StatelessWidget {
  const CreateTodoNotesBlock({
    super.key,
    required this.sectionLabel,
    required this.placeholder,
    required this.value,
    required this.onTap,
  });

  final String sectionLabel;
  final String placeholder;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    final preview = hasValue ? _buildPreview(value) : placeholder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TodoSectionLabel(label: sectionLabel),
        const SizedBox(height: 10),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: TodoStyleResolver.stroke,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: TodoStyleResolver.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.doc_text,
                      size: 18,
                      color: TodoStyleResolver.accentSoft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        preview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: hasValue
                            ? AppTextStyles.fieldInput.copyWith(
                                fontSize: 15,
                                height: 1.42,
                                color: TodoStyleResolver.textPrimary,
                              )
                            : AppTextStyles.fieldHint.copyWith(
                                fontSize: 15,
                                height: 1.42,
                                color: TodoStyleResolver.textMuted,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      CupertinoIcons.chevron_right,
                      size: 18,
                      color: TodoStyleResolver.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildPreview(String input) {
    return input
        .replaceAllMapped(
          RegExp('^- \\[(?: |x|X)\\]\\s*', multiLine: true),
          (_) => '\u2022 ',
        )
        .replaceAllMapped(
          RegExp('^[-*]\\s+', multiLine: true),
          (_) => '\u2022 ',
        )
        .replaceAll('**', '')
        .replaceAll('_', '')
        .replaceAll('~~', '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
