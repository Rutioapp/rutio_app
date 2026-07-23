import 'dart:io';

import 'shop_catalog_contract.dart';

class ShopCatalogSqlParseException implements Exception {
  ShopCatalogSqlParseException(
    this.filePath,
    this.message, {
    this.offset,
    this.line,
    this.column,
  });

  final String filePath;
  final String message;
  final int? offset;
  final int? line;
  final int? column;

  @override
  String toString() {
    final position =
        line == null || column == null ? '' : ' (line $line, column $column)';
    return 'ShopCatalogSqlParseException: $filePath$position: $message';
  }
}

class ShopCatalogSqlSeedParser {
  const ShopCatalogSqlSeedParser();

  ShopCatalogContractSnapshot parseFiles(List<String> filePaths) {
    final items = <ShopCatalogContractItem>[];
    final bundles = <ShopCatalogContractBundle>[];
    final bundleItemsById = <String, Map<String, String>>{};
    final bundleMetaById = <String, _SqlBundleMeta>{};

    for (final filePath in filePaths) {
      final source = File(filePath).readAsStringSync();
      items.addAll(_parseItems(filePath: filePath, source: source));
      final parsedBundles = _parseBundles(filePath: filePath, source: source);
      for (final bundle in parsedBundles.$1.items) {
        bundleMetaById[bundle.id] = bundle;
      }
      for (final bundleItem in parsedBundles.$2.items) {
        bundleItemsById.putIfAbsent(
            bundleItem.bundleId, () => <String, String>{});
        bundleItemsById[bundleItem.bundleId]![bundleItem.slot] =
            bundleItem.itemId;
      }
    }

    for (final entry in bundleMetaById.entries) {
      bundles.add(
        ShopCatalogContractBundle(
          id: entry.key,
          familyId: entry.value.familyId,
          rarity: entry.value.rarity,
          priceCoins: entry.value.priceCoins,
          originalPriceCoins: entry.value.originalPriceCoins,
          isActive: entry.value.isActive,
          sortOrder: entry.value.sortOrder,
          catalogVersion: entry.value.catalogVersion,
          itemIdsBySlot: Map<String, String>.unmodifiable(
            bundleItemsById[entry.key] ?? const <String, String>{},
          ),
        ),
      );
    }

    bundles.sort((left, right) => left.id.compareTo(right.id));
    items.sort((left, right) => left.id.compareTo(right.id));
    return ShopCatalogContractSnapshot(items: items, bundles: bundles);
  }

  List<ShopCatalogContractItem> _parseItems({
    required String filePath,
    required String source,
  }) {
    final statement = _extractInsertStatement(
      filePath: filePath,
      source: source,
      tableName: 'public.shop_items',
    );
    if (statement == null) {
      return const <ShopCatalogContractItem>[];
    }

    final tuples = _extractTuples(statement.valuesChunk);
    final items = <ShopCatalogContractItem>[];
    for (var index = 0; index < tuples.length; index++) {
      final values = _parseTuple(
        filePath: filePath,
        source: source,
        tuple: tuples[index],
        tupleIndex: index,
      );
      if (values.length != 14) {
        throw ShopCatalogSqlParseException(
          filePath,
          'Expected 14 values in shop_items tuple, found ${values.length}.',
          offset: statement.valuesOffset,
          line: statement.line,
          column: statement.column,
        );
      }
      items.add(
        shopCatalogContractItemFromSql(
          id: _requireString(filePath, values[0], 'id'),
          category: _requireString(filePath, values[1], 'category'),
          subtype: _nullableString(values[2]),
          rarity: _nullableString(values[3]),
          priceCoins: _requireInt(filePath, values[4], 'price_coins'),
          isConsumable: _requireBool(filePath, values[5], 'is_consumable'),
          isStackable: _requireBool(filePath, values[6], 'is_stackable'),
          maxQuantity: _nullableInt(values[7]),
          equipSlot: _nullableString(values[8]),
          assetKey: _requireString(filePath, values[9], 'asset_key'),
          localizationKey:
              _requireString(filePath, values[10], 'localization_key'),
          isActive: _requireBool(filePath, values[11], 'is_active'),
          catalogVersion: _requireInt(filePath, values[13], 'catalog_version'),
        ),
      );
    }
    return items;
  }

  (_SqlBundleMetaList, _SqlBundleItemList) _parseBundles({
    required String filePath,
    required String source,
  }) {
    final bundleStatement = _extractInsertStatement(
      filePath: filePath,
      source: source,
      tableName: 'public.shop_bundles',
    );
    final itemStatement = _extractInsertStatement(
      filePath: filePath,
      source: source,
      tableName: 'public.shop_bundle_items',
    );

    final bundles = <_SqlBundleMeta>[];
    final bundleItems = <_SqlBundleItemRow>[];

    if (bundleStatement != null) {
      final tuples = _extractTuples(bundleStatement.valuesChunk);
      for (var index = 0; index < tuples.length; index++) {
        final values = _parseTuple(
          filePath: filePath,
          source: source,
          tuple: tuples[index],
          tupleIndex: index,
        );
        if (values.length != 8 && values.length != 11) {
          throw ShopCatalogSqlParseException(
            filePath,
            'Expected 8 or 11 values in bundle seed tuple, found ${values.length}.',
            offset: bundleStatement.valuesOffset,
            line: bundleStatement.line,
            column: bundleStatement.column,
          );
        }
        final originalPriceIndex = values.length == 8 ? 4 : 4;
        final isActiveIndex = values.length == 8 ? 5 : 5;
        final sortOrderIndex = values.length == 8 ? 6 : 6;
        final catalogVersionIndex = values.length == 8 ? 7 : 7;
        bundles.add(
          _SqlBundleMeta(
            id: _requireString(filePath, values[0], 'id'),
            familyId: _requireString(filePath, values[1], 'family_id'),
            rarity: _requireString(filePath, values[2], 'rarity'),
            priceCoins: _requireInt(filePath, values[3], 'price_coins'),
            originalPriceCoins: _requireInt(
                filePath, values[originalPriceIndex], 'original_price_coins'),
            isActive:
                _requireBool(filePath, values[isActiveIndex], 'is_active'),
            sortOrder:
                _requireInt(filePath, values[sortOrderIndex], 'sort_order'),
            catalogVersion: _requireInt(
                filePath, values[catalogVersionIndex], 'catalog_version'),
          ),
        );
      }
    }

    if (itemStatement != null) {
      final tuples = _extractTuples(itemStatement.valuesChunk);
      for (var index = 0; index < tuples.length; index++) {
        final values = _parseTuple(
          filePath: filePath,
          source: source,
          tuple: tuples[index],
          tupleIndex: index,
        );
        if (values.length != 4) {
          throw ShopCatalogSqlParseException(
            filePath,
            'Expected 3 values in shop_bundle_items tuple, found ${values.length}.',
            offset: itemStatement.valuesOffset,
            line: itemStatement.line,
            column: itemStatement.column,
          );
        }
        final bundleId = _requireString(filePath, values[0], 'bundle_id');
        bundleItems.add(
          _SqlBundleItemRow(
            bundleId: bundleId,
            itemId: _requireString(filePath, values[1], 'wallpaper_item_id'),
            slot: 'screen_background',
          ),
        );
        bundleItems.add(
          _SqlBundleItemRow(
            bundleId: bundleId,
            itemId: _requireString(filePath, values[2], 'habit_card_item_id'),
            slot: 'habit_card_background',
          ),
        );
        bundleItems.add(
          _SqlBundleItemRow(
            bundleId: bundleId,
            itemId: _requireString(filePath, values[3], 'user_card_item_id'),
            slot: 'user_card_background',
          ),
        );
      }
    }

    return (_SqlBundleMetaList(bundles), _SqlBundleItemList(bundleItems));
  }
}

class _SqlBundleMeta {
  const _SqlBundleMeta({
    required this.id,
    required this.familyId,
    required this.rarity,
    required this.priceCoins,
    required this.originalPriceCoins,
    required this.isActive,
    required this.sortOrder,
    required this.catalogVersion,
  });

  final String id;
  final String familyId;
  final String rarity;
  final int priceCoins;
  final int originalPriceCoins;
  final bool isActive;
  final int sortOrder;
  final int catalogVersion;
}

class _SqlBundleItemRow {
  const _SqlBundleItemRow({
    required this.bundleId,
    required this.itemId,
    required this.slot,
  });

  final String bundleId;
  final String itemId;
  final String slot;
}

class _SqlBundleMetaList {
  const _SqlBundleMetaList(this.items);

  final List<_SqlBundleMeta> items;
}

class _SqlBundleItemList {
  const _SqlBundleItemList(this.items);

  final List<_SqlBundleItemRow> items;
}

class _InsertStatement {
  const _InsertStatement({
    required this.valuesChunk,
    required this.valuesOffset,
    required this.line,
    required this.column,
  });

  final String valuesChunk;
  final int valuesOffset;
  final int line;
  final int column;
}

_InsertStatement? _extractInsertStatement({
  required String filePath,
  required String source,
  required String tableName,
}) {
  final lower = source.toLowerCase();
  final needle = 'insert into $tableName';
  final start = lower.indexOf(needle);
  if (start < 0) {
    return null;
  }
  final valuesBeforeInsert = lower.lastIndexOf('values', start);
  if (valuesBeforeInsert >= 0) {
    final valuesStart = valuesBeforeInsert + 'values'.length;
    final valuesChunk = source.substring(valuesStart, start);
    final position = _lineAndColumn(source, valuesStart);
    return _InsertStatement(
      valuesChunk: valuesChunk,
      valuesOffset: valuesStart,
      line: position.line,
      column: position.column,
    );
  }

  final valuesAfterInsert = lower.indexOf('values', start);
  if (valuesAfterInsert < 0) {
    throw ShopCatalogSqlParseException(
      filePath,
      'Missing VALUES block for $tableName.',
      offset: start,
      line: _lineAndColumn(source, start).line,
      column: _lineAndColumn(source, start).column,
    );
  }
  final statementEnd = _findStatementEnd(filePath, source, valuesAfterInsert);
  final valuesStart = valuesAfterInsert + 'values'.length;
  final valuesChunk = source.substring(valuesStart, statementEnd);
  final position = _lineAndColumn(source, valuesStart);
  return _InsertStatement(
    valuesChunk: valuesChunk,
    valuesOffset: valuesStart,
    line: position.line,
    column: position.column,
  );
}

List<String> _extractTuples(String input) {
  final tuples = <String>[];
  var buffer = StringBuffer();
  var inString = false;
  var depth = 0;
  for (var index = 0; index < input.length; index++) {
    final char = input[index];
    if (inString) {
      buffer.write(char);
      if (char == "'") {
        final nextIndex = index + 1;
        if (nextIndex < input.length && input[nextIndex] == "'") {
          buffer.write("'");
          index++;
        } else {
          inString = false;
        }
      }
      continue;
    }

    if (char == "'") {
      buffer.write(char);
      inString = true;
      continue;
    }

    if (char == '(') {
      if (depth > 0) {
        buffer.write(char);
      }
      depth++;
      continue;
    }

    if (char == ')') {
      if (depth == 0) {
        continue;
      }
      depth--;
      if (depth > 0) {
        buffer.write(char);
      } else {
        tuples.add(buffer.toString());
        buffer = StringBuffer();
      }
      continue;
    }

    if (depth > 0) {
      buffer.write(char);
    }
  }
  return tuples;
}

List<String> _splitTupleValues(String tuple) {
  final values = <String>[];
  var buffer = StringBuffer();
  var inString = false;
  var depth = 0;
  for (var index = 0; index < tuple.length; index++) {
    final char = tuple[index];
    if (inString) {
      buffer.write(char);
      if (char == "'") {
        final nextIndex = index + 1;
        if (nextIndex < tuple.length && tuple[nextIndex] == "'") {
          buffer.write("'");
          index++;
        } else {
          inString = false;
        }
      }
      continue;
    }

    if (char == "'") {
      buffer.write(char);
      inString = true;
      continue;
    }

    if (char == '(') {
      depth++;
      buffer.write(char);
      continue;
    }

    if (char == ')') {
      if (depth == 0) {
        continue;
      }
      depth--;
      buffer.write(char);
      continue;
    }

    if (char == ',' && depth == 0) {
      values.add(buffer.toString());
      buffer = StringBuffer();
      continue;
    }

    buffer.write(char);
  }
  values.add(buffer.toString());
  return values;
}

List<Object?> _parseTuple({
  required String filePath,
  required String source,
  required String tuple,
  required int tupleIndex,
}) {
  final rawValues = _splitTupleValues(tuple);
  if (rawValues.isEmpty) {
    throw ShopCatalogSqlParseException(
      filePath,
      'Empty tuple in SQL seed at row ${tupleIndex + 1}.',
      line: _lineAndColumn(source, source.indexOf(tuple)).line,
      column: _lineAndColumn(source, source.indexOf(tuple)).column,
    );
  }
  return rawValues.map(_parseSqlValue).toList(growable: false);
}

Object? _parseSqlValue(String token) {
  var normalized = token.trim();
  normalized = _stripTypeCast(normalized);
  if (normalized.toLowerCase() == 'null') {
    return null;
  }
  if (normalized == 'true') {
    return true;
  }
  if (normalized == 'false') {
    return false;
  }
  if (normalized.startsWith("'") && normalized.endsWith("'")) {
    return _unescapeSqlString(normalized.substring(1, normalized.length - 1));
  }
  final intValue = int.tryParse(normalized);
  if (intValue != null) {
    return intValue;
  }
  throw FormatException('Unsupported SQL literal: $token');
}

String _stripTypeCast(String token) {
  var inString = false;
  for (var index = 0; index < token.length - 1; index++) {
    final char = token[index];
    if (char == "'") {
      if (inString && index + 1 < token.length && token[index + 1] == "'") {
        index++;
        continue;
      }
      inString = !inString;
      continue;
    }
    if (!inString && char == ':' && token[index + 1] == ':') {
      return token.substring(0, index).trim();
    }
  }
  return token.trim();
}

String _unescapeSqlString(String value) {
  return value.replaceAll("''", "'");
}

int _findStatementEnd(String filePath, String source, int start) {
  var inString = false;
  var depth = 0;
  for (var index = start; index < source.length; index++) {
    final char = source[index];
    if (inString) {
      if (char == "'") {
        final nextIndex = index + 1;
        if (nextIndex < source.length && source[nextIndex] == "'") {
          index++;
        } else {
          inString = false;
        }
      }
      continue;
    }
    if (char == "'") {
      inString = true;
      continue;
    }
    if (char == '(') {
      depth++;
      continue;
    }
    if (char == ')') {
      if (depth > 0) {
        depth--;
      }
      continue;
    }
    if (char == ';' && depth == 0) {
      return index;
    }
  }
  throw ShopCatalogSqlParseException(
    filePath,
    'Unterminated SQL statement.',
    offset: start,
  );
}

({int line, int column}) _lineAndColumn(String source, int offset) {
  var line = 1;
  var column = 1;
  final safeOffset = offset.clamp(0, source.length);
  for (var index = 0; index < safeOffset; index++) {
    if (source[index] == '\n') {
      line++;
      column = 1;
    } else {
      column++;
    }
  }
  return (line: line, column: column);
}

String? _nullableString(Object? value) {
  final normalized = (value ?? '').toString().trim();
  return normalized.isEmpty ? null : normalized;
}

int _requireInt(String filePath, Object? value, String field) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  final parsed = int.tryParse((value ?? '').toString().trim());
  if (parsed != null) {
    return parsed;
  }
  throw ShopCatalogSqlParseException(
    filePath,
    'Invalid integer for $field: $value',
  );
}

bool _requireBool(String filePath, Object? value, String field) {
  if (value is bool) {
    return value;
  }
  final normalized = (value ?? '').toString().trim().toLowerCase();
  if (normalized == 'true') {
    return true;
  }
  if (normalized == 'false') {
    return false;
  }
  throw ShopCatalogSqlParseException(
    filePath,
    'Invalid boolean for $field: $value',
  );
}

String _requireString(String filePath, Object? value, String field) {
  final normalized = (value ?? '').toString().trim();
  if (normalized.isEmpty) {
    throw ShopCatalogSqlParseException(
      filePath,
      'Missing value for $field.',
    );
  }
  return normalized;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString().trim());
}
