part of 'package:rutio/screens/home/home_screen.dart';

/// Catalog and family metadata helpers for Home.
///
/// Responsible for loading the habits catalog and resolving family labels/colors
/// used by pickers and chips in the Home flows.
extension _HomeScreenCatalogHelpers on _HomeScreenState {
  Future<Map<String, dynamic>> _loadCatalog() async {
    final raw = await rootBundle.loadString('assets/data/habits_catalog.json');
    final decoded = jsonDecode(raw);
    return (decoded as Map).cast<String, dynamic>();
  }

  Color _parseCatalogColor(dynamic v) {
    if (v is int) return Color(v);
    if (v is String) {
      var s = v.trim();
      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x')) s = s.substring(2);
      if (s.length == 6) s = 'FF$s';
      final value = int.tryParse(s, radix: 16);
      if (value != null) return Color(value);
    }
    return primaryDark;
  }

  Future<void> _primeCatalogFamilies() async {
    if (_catalogFamiliesById.isNotEmpty && _catalogHabitsById.isNotEmpty) {
      return;
    }

    try {
      final catalog = await _loadCatalog();
      final families = (catalog['families'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      for (final f in families) {
        final id = (f['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final name = (f['name'] ?? id).toString();
        final emoji = (f['emoji'] ?? '').toString();
        final color = _parseCatalogColor(
          f['color'] ?? f['hexColor'] ?? f['bgColor'],
        );

        _catalogFamiliesById[id] = {
          'name': name,
          'emoji': emoji,
          'color': color,
        };

        final habits = (f['habits'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>());

        for (final habit in habits) {
          final habitId = (habit['id'] ?? '').toString();
          if (habitId.isEmpty) continue;
          _catalogHabitsById[habitId] = habit;
        }
      }

      _applyHomeState(() {});
    } catch (_) {
      // If catalog loading fails, Home falls back to FamilyTheme/default labels.
    }
  }
}
