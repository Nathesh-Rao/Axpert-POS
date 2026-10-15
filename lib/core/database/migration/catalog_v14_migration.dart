import 'dart:convert';

import 'package:drift/drift.dart';

import '../axpert_database.dart';
import '../tables/unit_entries.dart';

/// Schema v14: units, brands, product packagings and barcodes (DEC-150).
/// Runs inside ONE transaction opened by the caller.
///
/// New tables only, plus nullable columns on `products` and `sale_lines`
/// (SQLite cannot add a non-null FK column, and a rebuild of the two big
/// tables is not needed). Foreign keys stay on; nothing cascades.
class CatalogV14Migration {
  const CatalogV14Migration(this.db);

  /// `migration_state` key listing the barcodes the backfill had to skip.
  static const String duplicatesKey = 'barcode_backfill_duplicates_v14';

  final AxpertDatabase db;

  static const String _now = "CAST(strftime('%s', 'now') AS INTEGER) * 1000";

  Future<void> run(Migrator migrator) async {
    await migrator.createTable(db.unitEntries);
    await migrator.createTable(db.brandEntries);
    await migrator.createTable(db.packagingEntries);
    await migrator.createTable(db.barcodeEntries);
    if (await _hasTable('products')) {
      await _addColumn(
        migrator,
        db.productEntries,
        db.productEntries.baseUnitId,
      );
      await _addColumn(migrator, db.productEntries, db.productEntries.brandId);
    }
    if (await _hasTable('sale_lines')) {
      final lines = db.saleLineEntries;
      await _addColumn(migrator, lines, lines.packagingId);
      await _addColumn(migrator, lines, lines.unitName);
      await _addColumn(migrator, lines, lines.quantityBaseMilli);
      await _addColumn(migrator, lines, lines.baseQtyMilli);
    }
    await createIndexes(db);
    await seedUnits(db);
    await _backfill();
  }

  /// The partial unique indexes (Drift cannot declare a WHERE clause) and
  /// the lookup indexes.
  static Future<void> createIndexes(AxpertDatabase db) async {
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS product_packagings_unique ON '
      'product_packagings (product_id, unit_id) WHERE deleted_at IS NULL',
    );
    await db.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS product_barcodes_unique ON '
      "product_barcodes (COALESCE(store_id, ''), barcode) "
      'WHERE deleted_at IS NULL',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS product_barcodes_product ON '
      'product_barcodes (product_id)',
    );
    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS product_packagings_product ON '
      'product_packagings (product_id)',
    );
  }

  /// The eight standard units with their fixed ids (idempotent).
  static Future<void> seedUnits(AxpertDatabase db) async {
    for (final u in SeedUnits.all) {
      await db.customStatement(
        'INSERT OR IGNORE INTO units (id, code, name, kind, created_at, '
        'updated_at) VALUES (?, ?, ?, ?, $_now, $_now)',
        [u.id, u.code, u.name, u.kind],
      );
    }
  }

  Future<void> _backfill() async {
    final names = await _columns('products');
    if (!names.containsAll(const [
      'id',
      'barcode',
      'code',
      'name',
      'position',
      'store_id',
      'deleted_at',
      'base_unit_id',
    ])) {
      return;
    }
    await db.customStatement(
      'UPDATE products SET base_unit_id = ? WHERE base_unit_id IS NULL',
      [SeedUnits.piece.id],
    );
    final rows = await db
        .customSelect(
          'SELECT id, store_id, barcode, code, name FROM products '
          "WHERE deleted_at IS NULL AND trim(barcode) != '' "
          'ORDER BY position, id',
        )
        .get();
    final kept = <String, Map<String, Object?>>{};
    final skipped = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      final store = r.read<String?>('store_id');
      final barcode = r.read<String>('barcode');
      final who = <String, Object?>{
        'id': r.read<String>('id'),
        'code': r.read<String>('code'),
        'name': r.read<String>('name'),
      };
      final key = '${store ?? ''}\u0000$barcode';
      if (kept.containsKey(key)) {
        skipped.putIfAbsent(key, () => []).add(who);
        continue;
      }
      kept[key] = {...who, 'store_id': store, 'barcode': barcode};
      await db.customStatement(
        'INSERT INTO product_barcodes (id, product_id, packaging_id, '
        'store_id, barcode, created_at, updated_at) '
        'VALUES (${AxpertDatabase.sqlUuid}, ?, NULL, ?, ?, $_now, $_now)',
        [who['id'], store, barcode],
      );
    }
    if (skipped.isEmpty) return;
    // The exact list for a later clean-up: barcode, kept product, skipped
    // products. The old products.barcode values stay untouched.
    final report = [
      for (final e in skipped.entries)
        {
          'barcode': kept[e.key]!['barcode'],
          'store_id': kept[e.key]!['store_id'],
          'kept': {
            for (final f in const ['id', 'code', 'name']) f: kept[e.key]![f],
          },
          'skipped': e.value,
        },
    ];
    await db.customStatement(
      'INSERT OR REPLACE INTO migration_state (key, value) VALUES (?, ?)',
      [duplicatesKey, jsonEncode(report)],
    );
  }

  Future<bool> _hasTable(String name) async =>
      (await db
              .customSelect(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
                variables: [Variable<String>(name)],
              )
              .get())
          .isNotEmpty;

  Future<Set<String>> _columns(String table) async => {
    for (final r in await db.customSelect('PRAGMA table_info($table)').get())
      r.read<String>('name'),
  };

  Future<void> _addColumn(
    Migrator migrator,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    if ((await _columns(table.actualTableName)).contains(column.name)) return;
    await migrator.addColumn(table, column);
  }
}
