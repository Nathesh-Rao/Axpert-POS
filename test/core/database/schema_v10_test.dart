import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/sqlite3.dart' show sqlite3;

void main() {
  const v10Tables = <String>['store_forex', 'tax_regimes', 'tax_slabs'];

  test('a fresh database has the v10 tables', () async {
    final db = AxpertDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    expect(db.schemaVersion, 11);
    expect(await db.select(db.storeForexEntries).get(), isEmpty);
    expect(await db.select(db.taxRegimeEntries).get(), isEmpty);
    expect(await db.select(db.taxSlabEntries).get(), isEmpty);
  });

  test('v9 database upgrades to v10 intact', () async {
    final dir = await Directory.systemTemp.createTemp('v10_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final seed = AxpertDatabase(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    await seed.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "quick_cash, created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, "
      "'lakh', '', 0, 0)",
    );
    await seed.customStatement(
      "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
      "VALUES ('s1', 'Shop', 'INR', 0, 0)",
    );
    for (final t in v10Tables.reversed) {
      await seed.customStatement('DROP TABLE $t');
    }
    await seed.customStatement('PRAGMA user_version = 9');
    await seed.close();

    final db = AxpertDatabase(NativeDatabase(file));
    addTearDown(db.close);
    final v = await db.customSelect('PRAGMA user_version').getSingle();
    expect(v.read<int>('user_version'), 11);
    final names = {
      for (final r
          in await db
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'table'",
              )
              .get())
        r.read<String>('name'),
    };
    expect(names, containsAll(v10Tables));
    final store = await db.select(db.storeEntries).getSingle();
    expect(store.name, 'Shop');
    expect(await db.select(db.currencyEntries).get(), hasLength(1));
  });

  test('a failed v10 step rolls back and leaves v9 data intact', () async {
    final dir = await Directory.systemTemp.createTemp('v10_fail_');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    final seed = AxpertDatabase(NativeDatabase(file));
    await seed.customSelect('SELECT 1').get();
    await seed.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "quick_cash, created_at, updated_at) VALUES ('INR', 'Rupee', 'R', 2, "
      "'lakh', '', 0, 0)",
    );
    for (final t in v10Tables.reversed) {
      await seed.customStatement('DROP TABLE $t');
    }
    // `tax_slabs` is created last in the step: a clashing index of that name
    // makes it fail after store_forex and tax_regimes were created.
    await seed.customStatement('CREATE INDEX tax_slabs ON currencies (name)');
    await seed.customStatement('PRAGMA user_version = 9');
    await seed.close();

    final db = AxpertDatabase(NativeDatabase(file));
    await expectLater(
      db.customSelect('SELECT 1').getSingle(),
      throwsA(anything),
    );
    try {
      await db.close();
    } on Object {
      // The migration failed on purpose.
    }

    final raw = sqlite3.open(file.path);
    addTearDown(raw.close);
    expect(raw.select('PRAGMA user_version').single['user_version'], 9);
    final names = {
      for (final r in raw.select(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      ))
        r['name'] as String,
    };
    expect(names, isNot(contains('store_forex')));
    expect(names, isNot(contains('tax_regimes')));
    expect(raw.select('SELECT code FROM currencies').single['code'], 'INR');
  });
}
