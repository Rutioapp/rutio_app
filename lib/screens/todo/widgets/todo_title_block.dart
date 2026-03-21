import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class TodoTitleBlock extends StatelessWidget {
  const TodoTitleBlock({
    super.key,
    required this.dateLabel,
  });

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // IOS-FIRST IMPROVEMENT START
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        dateLabel,
        style: TodoStyleResolver.dateStyle(context),
      ),
      // IOS-FIRST IMPROVEMENT END
    );
  }
}
