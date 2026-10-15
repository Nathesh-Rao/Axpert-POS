import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/export/export_file_name.dart';
import 'package:pos_application/core/database/export/io_export_saver.dart';
import 'package:pos_application/core/database/export/logical_snapshot.dart';
import 'package:pos_application/core/database/export/native_snapshot_service.dart';
import 'package:sqlite3/common.dart' show CommonDatabase;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../support/seeded_database.dart';

/// Every user table: its rows in rowid order as one string per row.
Map<String, List<String>> _dump(CommonDatabase db) {
  final tables = db.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );
  return <String, List<String>>{
    for (final t in tables)
      t['name'] as String: <String>[
        for (final row in db.select(
          'SELECT * FROM "${t['name']}" ORDER BY rowid',
        ))
          row.values.map((v) => v is Uint8List ? 'blob:$v' : '$v').join('|'),
      ],
  };
}

Future<Map<String, List<String>>> _dumpSource(AxpertDatabase db) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  final out = <String, List<String>>{};
  for (final t in tables) {
    final name = t.read<String>('name');
    final rows = await db
        .customSelect('SELECT * FROM "$name" ORDER BY rowid')
        .get();
    out[name] = <String>[
      for (final r in rows)
        r.data.values.map((v) => v is Uint8List ? 'blob:$v' : '$v').join('|'),
    ];
  }
  return out;
}

List<String> _schema(CommonDatabase db) => <String>[
  for (final r in db.select(
    "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
    'ORDER BY type, name',
  ))
    '${r['type']}:${r['name']}',
];

void main() {
  late AxpertDatabase db;
  late Directory tmp;

  setUp(() async {
    db = await seededDatabase();
    // A BLOB, a NULL and an apostrophe in one table the app does not have.
    await db.customStatement(
      'CREATE TABLE zz_extra (id INTEGER PRIMARY KEY, b BLOB, n TEXT, t TEXT)',
    );
    await db.customStatement(
      "INSERT INTO zz_extra (b, n, t) VALUES (x'00ff10', NULL, 'it''s')",
    );
    tmp = Directory.systemTemp.createTempSync('pos_export_test');
  });

  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  void expectSameAsSource(CommonDatabase out, Map<String, List<String>> src) {
    expect(_dump(out), src); // all tables, row counts and every value
    expect(out.select('PRAGMA user_version').first.values.first, 10);
    expect(out.select('PRAGMA integrity_check').first.values.first, 'ok');
  }

  test(
    'VACUUM INTO snapshot opens standalone and matches the source',
    () async {
      final service = VacuumIntoExportService(
        provider: FixedDatabaseProvider(db),
        tempDirectory: () async => tmp,
      );
      final snapshot = await service.createSnapshot();
      expect(snapshot.schemaVersion, 10);
      expect(snapshot.tableCount, greaterThan(15));
      expect(tmp.listSync(), isEmpty, reason: 'temp file deleted');

      final file = File('${tmp.path}/out.db')..writeAsBytesSync(snapshot.bytes);
      final out = sqlite.sqlite3.open(
        file.path,
        mode: sqlite.OpenMode.readOnly,
      );
      addTearDown(out.close);
      final src = await _dumpSource(db);
      expect(src.keys, contains('zz_extra'));
      expect(snapshot.tableCount, src.length);
      expectSameAsSource(out, src);
    },
  );

  test('logical copy (web path) matches the source, with indexes', () async {
    final file = File('${tmp.path}/copy.db');
    final target = sqlite.sqlite3.open(file.path);
    final result = await copyDatabaseInto(
      source: db,
      target: target,
      batchSize: 7, // many batches
    );
    expect(result.schemaVersion, 10);
    final src = await _dumpSource(db);
    expect(result.tables, src.length);
    expectSameAsSource(target, src);
    final reference = sqlite.sqlite3.openInMemory();
    addTearDown(reference.close);
    final vacuumed = File('${tmp.path}/ref.db');
    await db.customStatement("VACUUM INTO '${vacuumed.path}'");
    final ref = sqlite.sqlite3.open(vacuumed.path);
    addTearDown(ref.close);
    expect(_schema(target), _schema(ref), reason: 'tables and indexes');
    target.close();
    final reopened = sqlite.sqlite3.open(file.path);
    addTearDown(reopened.close);
    final blob = reopened.select('SELECT b, n, t FROM zz_extra').first;
    expect(blob['b'], Uint8List.fromList(<int>[0, 255, 16]));
    expect(blob['n'], isNull);
    expect(blob['t'], "it's");
  });

  group('file name', () {
    final at = DateTime(2026, 3, 7, 9, 5);
    test('slug of the store name', () {
      expect(
        databaseExportFileName(
          storeName: 'MAISON GALAXY - OZONE',
          storeId: 'abcdef123456',
          now: at,
        ),
        'pos_MAISON_GALAXY_-_OZONE_20260307_0905.db',
      );
    });
    test('falls back to the first 8 characters of the id', () {
      expect(
        databaseExportFileName(
          storeName: '!!!',
          storeId: '1234abcd-9999',
          now: at,
        ),
        'pos_1234abcd_20260307_0905.db',
      );
    });
  });

  test('io saver writes into the folder and never overwrites', () async {
    final saver = IoExportSaver(
      downloads: () async => Directory('${tmp.path}/dl'),
      documents: () async => Directory('${tmp.path}/docs'),
    );
    final a = await saver.save('x.db', Uint8List.fromList(<int>[1]));
    final b = await saver.save('x.db', Uint8List.fromList(<int>[2]));
    expect(a.path, '${tmp.path}/dl/x.db');
    expect(b.fileName, 'x_2.db');
    expect(File(a.path!).readAsBytesSync(), <int>[1]);
  });

  test('io saver falls back to Documents', () async {
    final saver = IoExportSaver(
      downloads: () async => null,
      documents: () async => Directory(tmp.path),
    );
    final saved = await saver.save('y.db', Uint8List(3));
    expect(saved.path, '${tmp.path}/y.db');
  });
}
