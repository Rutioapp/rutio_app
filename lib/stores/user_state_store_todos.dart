part of 'user_state_store.dart';

List<Map<String, dynamic>> _ensureTodosRoot(Map<String, dynamic> userState) {
  final todos = _list(userState['todos'])
      .whereType<Map>()
      .map((entry) => entry.cast<String, dynamic>())
      .toList();

  userState['todos'] = todos;
  return todos;
}

List<TodoItem> _todoItems(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <TodoItem>[];

  final userState = _ensureUserStateRoot(root);
  final rawTodos = _ensureTodosRoot(userState);

  return rawTodos
      .map(TodoItem.fromJson)
      .where((item) => item.id.trim().isNotEmpty)
      .toList();
}

Future<void> _upsertTodoItem(UserStateStore store, TodoItem item) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawTodos = _ensureTodosRoot(userState);
  final index = rawTodos.indexWhere(
    (current) => (current['id'] ?? '').toString() == item.id,
  );

  if (index >= 0) {
    rawTodos[index] = item.toJson();
  } else {
    rawTodos.insert(0, item.toJson());
  }

  _touchLastSavedAt(userState);
  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

Future<void> _deleteTodoItem(UserStateStore store, String id) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawTodos = _ensureTodosRoot(userState);
  rawTodos.removeWhere((entry) => (entry['id'] ?? '').toString() == id);

  _touchLastSavedAt(userState);
  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

Future<void> _setTodoCompleted(
  UserStateStore store, {
  required String todoId,
  required bool isCompleted,
}) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawTodos = _ensureTodosRoot(userState);
  final index = rawTodos.indexWhere(
    (entry) => (entry['id'] ?? '').toString() == todoId,
  );

  if (index == -1) return;

  final current = TodoItem.fromJson(rawTodos[index]);
  rawTodos[index] = current.copyWith(isCompleted: isCompleted).toJson();

  _touchLastSavedAt(userState);
  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}
