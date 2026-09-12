import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

typedef _Table = ({String schema, String name});

final _word = RegExp(r'[A-Za-z_][A-Za-z0-9_$]*');
final _identifier = RegExp(r'^[a-z_][a-z0-9_$]*$');
final _dollarDelimiter = RegExp(r'\$(?:[A-Za-z_][A-Za-z0-9_]*)?\$');

void main() {
  test('table declarations ignore comments and string literals', () {
    final tables = _createdTables(r'''
      -- CREATE TABLE public.line_comment (id int);
      /* CREATE TABLE public.block_comment (id int);
         /* nested comment */ still inside the outer comment */
      SELECT 'it''s -- CREATE TABLE public.string_literal (id int);';
      SELECT E'escaped\'quote /* CREATE TABLE public.escape_literal (id int);';
      SELECT "create table public.quoted_identifier";
      CREATE /* separated keywords */ UNLOGGED TABLE IF NOT EXISTS
        public.real_table (id int);
      DO $migration$
      BEGIN
        IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = 'conditional') THEN
          CREATE TABLE public."conditional" (id int);
        END IF;
        EXECUTE 'CREATE TABLE public.dynamic_string (id int)';
      END
      $migration$;
      CREATE TABLE "Custom"."Quoted""Name" (id int);
    ''');

    expect(tables, [
      (schema: 'public', name: 'real_table'),
      (schema: 'public', name: 'conditional'),
      (schema: 'Custom', name: 'Quoted"Name'),
    ]);
  });

  test('layout guard rejects bundled, misnamed and duplicate migrations', () {
    expect(
      _layoutErrors({
        '20260101000000_bundle.sql': '''
          CREATE TABLE public.first_table (id int);
          CREATE TABLE public.second_table (id int);
        ''',
        '20260101000000_alias.sql': r'''
          DO $$ BEGIN
            CREATE TABLE IF NOT EXISTS public.first_table (id int);
          END $$;
        ''',
      }),
      containsAll([
        '20260101000000_bundle.sql declares multiple tables: '
            'public.first_table, public.second_table.',
        '20260101000000_alias.sql shares migration version 20260101000000 '
            'with 20260101000000_bundle.sql.',
        '20260101000000_alias.sql declares first_table; '
            'its filename must end with _first_table.sql.',
        'public.first_table is declared in both '
            '20260101000000_bundle.sql and 20260101000000_alias.sql.',
      ]),
    );
  });

  test('each migration owns one table and has a unique version', () {
    // The override lets this same guard validate historical snapshots without
    // replacing the working migrations directory.
    final directory = Directory(
      Platform.environment['MIGRATION_LAYOUT_DIRECTORY'] ??
          'supabase/migrations',
    );
    expect(directory.existsSync(), isTrue, reason: directory.path);
    final files =
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.sql'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty, reason: 'No SQL migrations were found.');

    final errors = _layoutErrors({
      for (final file in files)
        file.uri.pathSegments.last: file.readAsStringSync(),
    });
    expect(errors, isEmpty, reason: errors.join('\n'));
  });
}

List<String> _layoutErrors(Map<String, String> migrations) {
  final errors = <String>[];
  final versions = <String, String>{};
  final owners = <_Table, String>{};
  final filenamePattern = RegExp(r'^(\d{14})_(.+)\.sql$');

  for (final entry in migrations.entries) {
    final filename = entry.key;
    final match = filenamePattern.firstMatch(filename);
    if (match == null) {
      errors.add('$filename must have a 14-digit migration version and name.');
    } else {
      final version = match.group(1)!;
      final previous = versions.putIfAbsent(version, () => filename);
      if (previous != filename) {
        errors.add(
          '$filename shares migration version $version with $previous.',
        );
      }
    }

    final tables = _createdTables(entry.value);
    if (tables.length > 1) {
      errors.add(
        '$filename declares multiple tables: '
        '${tables.map((table) => '${table.schema}.${table.name}').join(', ')}.',
      );
    } else if (tables.length == 1 && match?.group(2) != tables.single.name) {
      final table = tables.single.name;
      errors.add(
        '$filename declares $table; its filename must end with _$table.sql.',
      );
    }

    for (final table in tables) {
      final previous = owners[table];
      if (previous != null) {
        errors.add(
          '${table.schema}.${table.name} is declared in both '
          '$previous and $filename.',
        );
      } else {
        owners[table] = filename;
      }
    }
  }
  return errors;
}

List<_Table> _createdTables(String sql) {
  final tokens = _sqlTokens(sql).toList();
  final tables = <_Table>[];
  for (var i = 0; i < tokens.length; i++) {
    if (tokens[i] != 'create') continue;
    var cursor = i + 1;
    if (cursor < tokens.length &&
        const ['global', 'local'].contains(tokens[cursor])) {
      cursor++;
    }
    if (cursor < tokens.length &&
        const ['temporary', 'temp', 'unlogged'].contains(tokens[cursor])) {
      cursor++;
    }
    if (cursor >= tokens.length || tokens[cursor++] != 'table') continue;
    if (cursor + 2 < tokens.length &&
        tokens[cursor] == 'if' &&
        tokens[cursor + 1] == 'not' &&
        tokens[cursor + 2] == 'exists') {
      cursor += 3;
    }
    if (cursor >= tokens.length) continue;
    final first = _identifierName(tokens[cursor++]);
    if (first == null) continue;
    if (cursor + 1 < tokens.length && tokens[cursor] == '.') {
      final name = _identifierName(tokens[cursor + 1]);
      if (name != null) tables.add((schema: first, name: name));
    } else {
      tables.add((schema: 'public', name: first));
    }
  }
  return tables;
}

String? _identifierName(String token) {
  if (token.startsWith('"') && token.endsWith('"')) {
    return token.substring(1, token.length - 1).replaceAll('""', '"');
  }
  return _identifier.hasMatch(token) ? token : null;
}

/// Tokenize SQL while discarding comments and ordinary string literals.
/// Dollar delimiters are skipped but their bodies remain visible: conditional
/// DDL inside DO blocks still declares a table, while quoted EXECUTE text does
/// not. Quoted identifiers remain distinct from executable SQL keywords.
Iterable<String> _sqlTokens(String sql) sync* {
  var i = 0;
  while (i < sql.length) {
    if (sql.startsWith('--', i)) {
      final newline = sql.indexOf('\n', i + 2);
      i = newline < 0 ? sql.length : newline + 1;
      continue;
    }
    if (sql.startsWith('/*', i)) {
      var depth = 1;
      i += 2;
      while (i < sql.length && depth > 0) {
        if (sql.startsWith('/*', i)) {
          depth++;
          i += 2;
        } else if (sql.startsWith('*/', i)) {
          depth--;
          i += 2;
        } else {
          i++;
        }
      }
      continue;
    }
    if (sql[i] == "'") {
      final escaped =
          i > 0 &&
          (sql[i - 1] == 'e' || sql[i - 1] == 'E') &&
          (i == 1 || !RegExp(r'[A-Za-z0-9_$]').hasMatch(sql[i - 2]));
      i++;
      while (i < sql.length) {
        if (escaped && sql[i] == r'\') {
          i += 2;
        } else if (sql.startsWith("''", i)) {
          i += 2;
        } else if (sql[i++] == "'") {
          break;
        }
      }
      continue;
    }
    if (sql[i] == '"') {
      final start = i++;
      while (i < sql.length) {
        if (sql.startsWith('""', i)) {
          i += 2;
        } else if (sql[i++] == '"') {
          break;
        }
      }
      yield sql.substring(start, i);
      continue;
    }
    final delimiter = _dollarDelimiter.matchAsPrefix(sql, i);
    if (delimiter != null) {
      i = delimiter.end;
      continue;
    }
    final word = _word.matchAsPrefix(sql, i);
    if (word != null) {
      yield word.group(0)!.toLowerCase();
      i = word.end;
      continue;
    }
    if (sql[i].trim().isNotEmpty) yield sql[i];
    i++;
  }
}
