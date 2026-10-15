import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' as sqlite;

import '../axpert_database.dart';

/// Result of [copyDatabaseInto].
class LogicalCopyResult {
  const LogicalCopyResult({required this.schemaVersion, required this.tables});

  final int schemaVersion;
  final int tables;
}

/// Copies schema and data of [source] into the empty [target] database: used
/// where `VACUUM INTO` cannot be read back (the web database lives in the
/// Drift worker, so the page builds the file itself).
///
/// Foreign keys are off on the target, rows keep their rowid, BLOB and NULL
/// values are bound as they are, indexes, triggers and views are recreated
/// after the data and `user_version` is carried over. Rows are read inside
/// one transaction of the source, so the copy is a single point in time, and
/// in batches, so the event loop keeps running.
Future<LogicalCopyResult> copyDatabaseInto({
  required AxpertDatabase source,
  required sqlite.CommonDatabase target,
  int batchSize = 500,
}) {
  return source.transaction(() async {
    final master = await source
        .customSelect(
          'SELECT type, name, sql FROM sqlite_master '
          "WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' "
          'ORDER BY rowid',
        )
        .get();
    final version =
        (await source.customSelect('PRAGMA user_version').getSingle())
                .data
                .values
                .first!
            as int;
    final tables = <String>[
      for (final r in master)
        if (r.read<String>('type') == 'table') r.read<String>('name'),
    ];

    target.execute('PRAGMA foreign_keys = OFF');
    target.execute('BEGIN');
    try {
      for (final r in master) {
        if (r.read<String>('type') == 'table') {
          target.execute(r.read<String>('sql'));
        }
      }
      for (final table in tables) {
        await _copyTable(source, target, table, batchSize);
      }
      final hasSequence =
          (await source
                  .customSelect(
                    "SELECT 1 FROM sqlite_master WHERE name = 'sqlite_sequence'",
                  )
                  .get())
              .isNotEmpty;
      if (hasSequence) {
        for (final r
            in await source
                .customSelect('SELECT name, seq FROM sqlite_sequence')
                .get()) {
          target.execute(
            'INSERT OR REPLACE INTO sqlite_sequence (name, seq) VALUES (?, ?)',
            <Object?>[r.read<String>('name'), r.read<int>('seq')],
          );
        }
      }
      for (final r in master) {
        if (r.read<String>('type') != 'table') {
          target.execute(r.read<String>('sql'));
        }
      }
      target.execute('PRAGMA user_version = $version');
      target.execute('COMMIT');
    } on Object {
      target.execute('ROLLBACK');
      rethrow;
    }
    return LogicalCopyResult(schemaVersion: version, tables: tables.length);
  });
}

String _quote(String name) => '"${name.replaceAll('"', '""')}"';

Future<void> _copyTable(
  AxpertDatabase source,
  sqlite.CommonDatabase target,
  String table,
  int batchSize,
) async {
  final columns = <String>[
    for (final r
        in await source
            .customSelect('PRAGMA table_info(${_quote(table)})')
            .get())
      r.read<String>('name'),
  ];
  final columnList = columns.map(_quote).join(', ');
  final insert = target.prepare(
    'INSERT INTO ${_quote(table)} (rowid, $columnList) '
    'VALUES (?, ${List<String>.filled(columns.length, '?').join(', ')})',
  );
  try {
    var lastRowId = -1 << 62;
    while (true) {
      final rows = await source
          .customSelect(
            'SELECT rowid AS __rowid, $columnList FROM ${_quote(table)} '
            'WHERE rowid > ? ORDER BY rowid LIMIT ?',
            variables: <Variable>[
              Variable<int>(lastRowId),
              Variable<int>(batchSize),
            ],
          )
          .get();
      for (final row in rows) {
        lastRowId = row.read<int>('__rowid');
        insert.execute(<Object?>[
          lastRowId,
          for (final c in columns) row.data[c],
        ]);
      }
      if (rows.length < batchSize) break;
    }
  } finally {
    insert.close();
  }
}
