part of 'package:rutio/screens/home/home_screen.dart';

/// ===============================
/// Helpers compartidos para Home
/// ===============================

DateTime _onlyDate(DateTime d) => DateTime(d.year, d.month, d.day);

Map<String, dynamic> _map(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _listMap(dynamic v) {
  if (v is List) {
    return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
  return const [];
}

/// Lectura segura de int en rutas tipo:
/// _readInt(root, ['user', 'xp'])
int _readInt(
  Map<String, dynamic> root,
  List<String> path, {
  int fallback = 0,
}) {
  dynamic cur = root;

  for (final key in path) {
    if (cur is Map && cur.containsKey(key)) {
      cur = cur[key];
    } else {
      return fallback;
    }
  }

  if (cur is int) return cur;
  if (cur is num) return cur.toInt();
  return fallback;
}

/// Lectura segura de num (int/double/String)
/// Evita errores tipo: "type 'String' is not a subtype of type 'num'"
num _readNum(dynamic v, {num fallback = 0}) {
  if (v is num) return v;

  final s = (v ?? '').toString().trim();
  if (s.isEmpty) return fallback;

  // Soporta coma o punto decimal
  return num.tryParse(s.replaceAll(',', '.')) ?? fallback;
}

String _dateKey(DateTime d) {
  final x = _onlyDate(d);
  final y = x.year.toString().padLeft(4, '0');
  final m = x.month.toString().padLeft(2, '0');
  final day = x.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
