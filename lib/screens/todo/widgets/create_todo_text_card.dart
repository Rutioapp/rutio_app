import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rutio/screens/todo/helpers/todo_style_resolver.dart';

class CreateTodoTextCard extends StatelessWidget {
  const CreateTodoTextCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.titlePlaceholder,
    required this.descriptionPlaceholder,
  });

  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String titlePlaceholder;
  final String descriptionPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
            child: CupertinoTextField.borderless(
              controller: titleController,
              maxLines: 3,
              minLines: 3,
              placeholder: titlePlaceholder,
              style: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 20,
                color: TodoStyleResolver.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              placeholderStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 20,
                color: Color(0xFFCCBEAF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0x22CBAE88),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
            child: CupertinoTextField.borderless(
              controller: descriptionController,
              maxLines: 4,
              minLines: 4,
              placeholder: descriptionPlaceholder,
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                color: TodoStyleResolver.textPrimary.withValues(alpha: 0.92),
                fontWeight: FontWeight.w400,
              ),
              placeholderStyle: const TextStyle(
                fontFamily: 'DMSans',
                fontSize: 17,
                color: Color(0xFFCDBEAF),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
