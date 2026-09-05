import 'generate_release_sql.dart' as generic;

/// Backwards-compatible entry point for the original es-ES command.
void main(List<String> args) => generic.main(args);

/// Compatibility helper retained for the original tooling test.
String joinSqlValues(Iterable<String> rows) {
  final values = rows.toList(growable: false);
  if (values.isEmpty) throw StateError('A VALUES block must contain rows.');
  return values
      .asMap()
      .entries
      .map((entry) =>
          '${entry.value}${entry.key == values.length - 1 ? '' : ','}')
      .join('\n');
}
