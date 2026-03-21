import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class TodoSectionLabel extends StatelessWidget {
  const TodoSectionLabel({
    super.key,
    required this.label,
    this.centered = false,
  });

  final String label;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TodoStyleResolver.sectionStyle(context),
      textAlign: centered ? TextAlign.center : TextAlign.start,
    );

    if (!centered) return text;

    return Row(
      children: <Widget>[
        const Expanded(
          child: Divider(
            color: TodoStyleResolver.divider,
            thickness: 1,
            endIndent: 16,
          ),
        ),
        text,
        const Expanded(
          child: Divider(
            color: TodoStyleResolver.divider,
            thickness: 1,
            indent: 16,
          ),
        ),
      ],
    );
  }
}
