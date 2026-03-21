part of 'user_state_store.dart';

List<DiaryEntry> _diaryEntries(UserStateStore store) {
  final root = store._state;
  if (root == null) return const <DiaryEntry>[];

  final userState = _ensureUserStateRoot(root);
  final rawEntries = _ensureDiaryEntriesRoot(userState);

  final entries = rawEntries.map(DiaryEntry.fromJson).toList();
  entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return entries;
}

Future<void> _addDiaryEntry(UserStateStore store, DiaryEntry entry) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawEntries = _ensureDiaryEntriesRoot(userState);

  rawEntries.add(entry.toJson());
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

Future<void> _updateDiaryEntry(UserStateStore store, DiaryEntry entry) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawEntries = _ensureDiaryEntriesRoot(userState);
  final index = rawEntries.indexWhere(
    (current) => (current['id'] ?? '').toString() == entry.id,
  );

  if (index >= 0) {
    rawEntries[index] = entry.toJson();
  } else {
    rawEntries.add(entry.toJson());
  }

  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}

Future<void> _deleteDiaryEntry(UserStateStore store, String id) async {
  final root = store._state;
  if (root == null) return;

  final userState = _ensureUserStateRoot(root);
  final rawEntries = _ensureDiaryEntriesRoot(userState);

  rawEntries.removeWhere((entry) => (entry['id'] ?? '').toString() == id);
  _touchLastSavedAt(userState);

  root['userState'] = userState;
  store._state = root;

  await store._repo.save(root);
  store._emitChanged();
}
