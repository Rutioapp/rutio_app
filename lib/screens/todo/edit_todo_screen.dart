import 'package:flutter/widgets.dart';
import 'package:rutio/screens/todo/create_todo_screen.dart';
import 'package:rutio/screens/todo/models/todo_item.dart';

class EditTodoScreen extends StatelessWidget {
  const EditTodoScreen({
    super.key,
    required this.item,
  });

  final TodoItem item;

  @override
  Widget build(BuildContext context) {
    return CreateTodoScreen(
      initialItem: item,
      isEditing: true,
    );
  }
}
