import 'dart:convert';

import 'package:drift/drift.dart';

import '../../utils/epoch_time.dart';
import '../axpert_database.dart';

/// Schema v11: every `*_at` column that still holds ISO 8601 text becomes
/// INTEGER epoch milliseconds (UTC), DEC-147.
///
/// SQLite cannot change a column type, so each affected table is rebuilt with
/// the procedure from sqlite.org ("Making Other Kinds Of Table Schema
/// Changes"): foreign keys OFF outside the transaction, create `<t>_new` from
/// the table's own DDL with the column types changed, copy, drop the old
/// table, rename, re-create its indexes, `foreign_key_check`, commit. With
/// foreign keys off, dropping a parent never deletes or rejects child rows.
///
/// Values are converted in Dart first (one UPDATE per distinct text value, the
/// stamps repeat heavily) so the shapes `DateTime.parse` understands (no
/// fraction, `+05:30` offsets, 6-digit fractions) all work; the copy then
/// turns the digit text into integers through the column affinity. NULL stays
/// NULL. Only a non-null value that is no date becomes 0, and the counts are
/// written to `migration_state` (key [stateKey]).
///
/// The step only touches `*_at` columns declared TEXT, so it is idempotent and
/// harmless when an older step of the same upgrade chain already created the
/// table from the current (INTEGER) definition.
class EpochV11Migration {
  const EpochV11Migration(this.db);

  /// `migration_state` key holding the result of the step.
  static const String stateKey = 'epoch_v11';

  final AxpertDatabase db;

  Future<void> run() async {
    await db.customStatement('PRAGMA foreign_keys = OFF');
    final enabled = await db.customSelect('PRAGMA foreign_keys').getSingle();
    if (enabled.read<int>('foreign_keys') != 0) {
      throw StateError('v11 needs foreign keys off to rebuild tables');
    }
    await db.transaction(() async {
      final unparsable = <String, int>{};
      var rebuilt = 0;
      for (final table in db.allTables) {
        final name = table.actualTableName;
        final columns = await _textStampColumns(name);
        if (columns.isEmpty) continue;
        for (final column in columns) {
          final bad = await _convertValues(name, column);
          if (bad > 0) unparsable['$name.$column'] = bad;
        }
        await _rebuild(name, columns);
        rebuilt++;
      }
      final violations = await db
          .customSelect('PRAGMA foreign_key_check')
          .get();
      if (violations.isNotEmpty) {
        throw StateError(
          'v11 left ${violations.length} foreign key violation(s)',
        );
      }
      final hasState = await db
          .customSelect(
            "SELECT 1 FROM sqlite_master WHERE type = 'table' "
            "AND name = 'migration_state'",
          )
          .get();
      if (hasState.isNotEmpty) {
        await db.customStatement(
          'INSERT OR REPLACE INTO migration_state (key, value) VALUES (?, ?)',
          <Object>[
            stateKey,
            jsonEncode(<String, Object>{
              'tables': rebuilt,
              'unparsable': unparsable,
              'unparsable_total': unparsable.values.fold<int>(
                0,
                (a, b) => a + b,
              ),
            }),
          ],
        );
      }
    });
    await db.customStatement('PRAGMA foreign_keys = ON');
  }

  /// The `*_at` columns of [table] that are declared TEXT (not yet converted).
  Future<List<String>> _textStampColumns(String table) async {
    final info = await db.customSelect('PRAGMA table_info("$table")').get();
    return [
      for (final row in info)
        if (row.read<String>('name').endsWith('_at') &&
            row.read<String>('type').toUpperCase() == 'TEXT')
          row.read<String>('name'),
    ];
  }

  /// Rewrites the non-null text values of one column as epoch digits; returns
  /// how many rows held a value that is no date (set to 0).
  Future<int> _convertValues(String table, String column) async {
    final values = await db
        .customSelect(
          'SELECT DISTINCT "$column" AS v FROM "$table" '
          'WHERE "$column" IS NOT NULL AND typeof("$column") = \'text\'',
        )
        .get();
    var bad = 0;
    for (final row in values) {
      final text = row.read<String>('v');
      final ms = EpochTime.tryParse(text);
      final count = await db.customUpdate(
        'UPDATE "$table" SET "$column" = ? WHERE "$column" = ?',
        variables: [Variable<String>('${ms ?? 0}'), Variable<String>(text)],
        updateKind: UpdateKind.update,
      );
      if (ms == null) bad += count;
    }
    return bad;
  }

  Future<void> _rebuild(String table, List<String> columns) async {
    final master = await db
        .customSelect(
          "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
          variables: [Variable<String>(table)],
        )
        .getSingle();
    final indexes = [
      for (final row
          in await db
              .customSelect(
                "SELECT sql FROM sqlite_master WHERE type = 'index' "
                'AND tbl_name = ? AND sql IS NOT NULL',
                variables: [Variable<String>(table)],
              )
              .get())
        row.read<String>('sql'),
    ];
    final temp = '${table}_new';
    var ddl = master
        .read<String>('sql')
        .replaceFirst(
          RegExp(
            'CREATE TABLE\\s+(IF NOT EXISTS\\s+)?["`\\[]?$table["`\\]]?',
            caseSensitive: false,
          ),
          'CREATE TABLE "$temp"',
        );
    for (final column in columns) {
      ddl = ddl.replaceFirstMapped(
        RegExp(
          '(["`\\[]?\\b$column\\b["`\\]]?)\\s+TEXT\\b',
          caseSensitive: false,
        ),
        (m) => '${m[1]} INTEGER',
      );
    }
    await db.customStatement(ddl);
    final created = await db.customSelect('PRAGMA table_info("$temp")').get();
    for (final column in columns) {
      final type = created
          .firstWhere((r) => r.read<String>('name') == column)
          .read<String>('type');
      if (type.toUpperCase() != 'INTEGER') {
        throw StateError('v11 could not retype $table.$column');
      }
    }
    await db.customStatement('INSERT INTO "$temp" SELECT * FROM "$table"');
    await db.customStatement('DROP TABLE "$table"');
    await db.customStatement('ALTER TABLE "$temp" RENAME TO "$table"');
    for (final sql in indexes) {
      await db.customStatement(sql);
    }
  }
}
