// Shared family/habit helpers so radar, progress bars and calculations all
// use the same keys and order.

String normalizeFamilyId(String id) => id.trim().toLowerCase();

const List<String> kCanonicalFamilyOrder = <String>[
  'mind',
  'body',
  'spirit',
  'emotional',
  'social',
  'discipline',
  'professional',
];

String habitId(dynamic habit) {
  if (habit is Map) {
    final id = habit['id'] ?? habit['habitId'] ?? habit['uuid'];
    if (id != null) return id.toString().trim();
  }
  return '';
}

String habitFamilyId(dynamic habit) {
  if (habit is Map) {
    final family = habit['family'] ??
        habit['familyId'] ??
        habit['family_id'] ??
        habit['category'];
    if (family != null) return normalizeFamilyId(family.toString());
  }
  return '';
}

List<String> resolveFamilyOrder(
  List<dynamic> habits, {
  Iterable<String>? extraFamilyIds,
}) {
  final present = <String>{};

  if (extraFamilyIds != null) {
    for (final id in extraFamilyIds) {
      final value = normalizeFamilyId(id);
      if (value.isNotEmpty) present.add(value);
    }
  }

  for (final habit in habits) {
    final id = habitFamilyId(habit);
    if (id.isNotEmpty) present.add(id);
  }

  final order = <String>[];

  for (final familyId in kCanonicalFamilyOrder) {
    if (present.contains(familyId)) order.add(familyId);
  }

  final extras = present.difference(kCanonicalFamilyOrder.toSet()).toList()
    ..sort();
  order.addAll(extras);

  return order;
}
