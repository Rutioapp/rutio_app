import 'dart:convert';
import 'dart:io';

const _structuralFields = <String>[
  'id',
  'category',
  'tone',
  'sourceType',
  'requiredTokens',
  'weight',
];

void main(List<String> args) {
  final esPath = args.isEmpty
      ? 'supabase/catalog/completed_day_phrase/es-ES.v1.json'
      : args[0];
  final enPath = args.length < 2
      ? 'supabase/catalog/completed_day_phrase/en-US.v1.json'
      : args[1];
  final es = _read(esPath);
  final en = _read(enPath);
  final esPhrases = _phrases(es);
  final enPhrases = _phrases(en);
  if (esPhrases.length != enPhrases.length) {
    _fail('catalog sizes differ: ${esPhrases.length}/${enPhrases.length}');
  }
  for (var index = 0; index < esPhrases.length; index++) {
    final left = esPhrases[index];
    final right = enPhrases[index];
    for (final field in _structuralFields) {
      if (!_jsonEquals(left[field], right[field])) {
        _fail('structural mismatch index=$index field=$field');
      }
    }
  }
  if (es['locale'] == en['locale']) _fail('locales must differ');
  stdout.writeln(
    'STRUCTURE_MATCH es=${es['locale']} en=${en['locale']} entries=${esPhrases.length}',
  );
}

Map<String, dynamic> _read(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

List<Map<String, dynamic>> _phrases(Map<String, dynamic> catalog) {
  final raw = catalog['phrases'];
  if (raw is! List) _fail('phrases must be an array');
  return raw
      .cast<Object?>()
      .map((value) =>
          Map<String, dynamic>.from((value as Map).cast<String, dynamic>()))
      .toList(growable: false);
}

bool _jsonEquals(Object? left, Object? right) {
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (!_jsonEquals(left[index], right[index])) return false;
    }
    return true;
  }
  return left == right;
}

Never _fail(String message) {
  stderr.writeln('MISMATCH $message');
  exitCode = 1;
  throw StateError(message);
}
