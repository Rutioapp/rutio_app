import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final catalog = args.isEmpty
      ? 'supabase/catalog/completed_day_phrase/es-ES.v1.json'
      : args[0];
  final locale = _catalogLocale(catalog);
  final slug = locale.toLowerCase().replaceAll('-', '_');
  final seed = args.length < 2
      ? 'supabase/seeds/completed_day_phrase_${slug}_v1.sql'
      : args[1];
  final migration = args.length < 3 ? seed : args[2];
  final temporary = Directory.systemTemp.createTempSync(
    'completed_day_phrase_artifact_check_',
  );
  final generated =
      File('${temporary.path}${Platform.pathSeparator}generated.sql');
  try {
    final validator = Process.runSync(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'tool/completed_day_phrase/validate_catalog.dart',
        catalog
      ],
      workingDirectory: Directory.current.path,
    );
    if (validator.exitCode != 0) {
      stderr.write(validator.stdout);
      stderr.write(validator.stderr);
      throw StateError('Canonical catalog validation failed.');
    }
    final generator = Process.runSync(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'tool/completed_day_phrase/generate_release_sql.dart',
        catalog,
        generated.path,
      ],
      workingDirectory: Directory.current.path,
    );
    if (generator.exitCode != 0) {
      stderr.write(generator.stdout);
      stderr.write(generator.stderr);
      throw StateError('SQL generation failed.');
    }
    final expected = generated.readAsStringSync();
    _compare('seed', expected, File(seed).readAsStringSync());
    _compare('migration', expected, File(migration).readAsStringSync());
    stdout
        .writeln('VALID source -> SQL -> migration drift=false locale=$locale');
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

String _catalogLocale(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map || decoded['locale'] is! String) {
    throw FormatException('Catalog locale not found.');
  }
  return decoded['locale'] as String;
}

void _compare(String label, String expected, String actual) {
  if (expected == actual) return;
  var index = 0;
  final limit =
      expected.length < actual.length ? expected.length : actual.length;
  while (
      index < limit && expected.codeUnitAt(index) == actual.codeUnitAt(index)) {
    index++;
  }
  throw StateError(
    '$label drift detected at character $index '
    '(expected length ${expected.length}, actual length ${actual.length}).',
  );
}
