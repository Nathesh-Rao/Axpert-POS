import 'package:drift/drift.dart';

import '../bindings/startup_timeline.dart';
import 'migration/epoch_v11_migration.dart';
import 'tables/category_entries.dart';
import 'tables/counter_entries.dart';
import 'tables/currency_entries.dart';
import 'tables/current_cart_entries.dart';
import 'tables/customer_entries.dart';
import 'tables/device_context_entries.dart';
import 'tables/held_bill_entries.dart';
import 'tables/inventory_entries.dart';
import 'tables/migration_state_entries.dart';
import 'tables/offer_entries.dart';
import 'tables/payment_entries.dart';
import 'tables/product_entries.dart';
import 'tables/sale_entries.dart';
import 'tables/sale_line_entries.dart';
import 'tables/seed_manifest_entries.dart';
import 'tables/settings_entries.dart';
import 'tables/store_entries.dart';
import 'tables/store_forex_entries.dart';
import 'tables/tax_regime_entries.dart';
import 'tables/user_entries.dart';

part 'axpert_database.g.dart';

/// Drift database: device context metadata and device-local settings.
///
/// Schema v12 adds inventory_balance, inventory_transactions and
/// stores.allow_negative_stock (DEC-148).
/// Schema v11 stores every timestamp as integer epoch milliseconds (UTC).
/// Schema v10 adds store_forex, tax_regimes and tax_slabs.
/// Schema v3 (settings, migration_state), v4 (customers), v5 (held_bills), v6 (products), v7 (sales, sale_lines, payments)
/// v8 (current_cart) and v9 (currencies, stores, counters, users,
/// user_access, categories, offers, seed_manifest, scope columns) are provisional
/// and local-only (DEC-124); they no longer match axpert's schema.
@DriftDatabase(
  tables: [
    DeviceContextEntries,
    SettingsEntries,
    MigrationStateEntries,
    CustomerEntries,
    HeldBillEntries,
    ProductEntries,
    SaleEntries,
    SaleLineEntries,
    PaymentEntries,
    CurrentCartEntries,
    CurrencyEntries,
    StoreEntries,
    CounterEntries,
    UserEntries,
    UserAccessEntries,
    CategoryEntries,
    OfferEntries,
    SeedManifestEntries,
    StoreForexEntries,
    TaxRegimeEntries,
    TaxSlabEntries,
    InventoryBalanceEntries,
    InventoryTransactionEntries,
  ],
)
class AxpertDatabase extends _$AxpertDatabase {
  AxpertDatabase(super.executor);

  @override
  int get schemaVersion => 12;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) =>
        StartupTimeline.measure('schema create', () => migrator.createAll()),
    onUpgrade: (migrator, from, to) => StartupTimeline.measure(
      'schema upgrade v$from to v$to',
      () => _upgrade(migrator, from, to),
    ),
    beforeOpen: (_) async {
      // The database design requires SQLite foreign-key checks on each open.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _upgrade(Migrator migrator, int from, int to) async {
    if (from < 2 && to >= 2) {
      await migrator.createTable(deviceContextEntries);
    }
    if (from < 3 && to >= 3) {
      // Drift does not roll back a failed upgrade by itself; one
      // transaction keeps v3 all-or-nothing.
      await transaction(() async {
        await migrator.createTable(settingsEntries);
        await migrator.createTable(migrationStateEntries);
      });
    }
    if (from < 4 && to >= 4) {
      await transaction(() async {
        await migrator.createTable(customerEntries);
      });
    }
    if (from < 5 && to >= 5) {
      await transaction(() async {
        await migrator.createTable(heldBillEntries);
      });
    }
    if (from < 6 && to >= 6) {
      await transaction(() async {
        await migrator.createTable(productEntries);
        await migrator.createIndex(productsPosition);
      });
    }
    if (from < 7 && to >= 7) {
      await transaction(() async {
        await migrator.createTable(saleEntries);
        await migrator.createTable(saleLineEntries);
        await migrator.createTable(paymentEntries);
        await migrator.createIndex(salesPosition);
      });
    }
    if (from < 8 && to >= 8) {
      await transaction(() async {
        await migrator.createTable(currentCartEntries);
      });
    }
    if (from < 9 && to >= 9) {
      // One transaction: v9 is all-or-nothing (DEC-132).
      await transaction(() async {
        await migrator.createTable(currencyEntries);
        await migrator.createTable(storeEntries);
        await migrator.createTable(counterEntries);
        await migrator.createTable(userEntries);
        await migrator.createTable(userAccessEntries);
        await migrator.createTable(categoryEntries);
        await migrator.createTable(offerEntries);
        await migrator.createTable(seedManifestEntries);
        // Older steps create their tables from the current definitions, so a
        // column may already exist when the chain runs from before v6.
        await _addColumnIfMissing(
          migrator,
          productEntries,
          productEntries.storeId,
        );
        await _addColumnIfMissing(
          migrator,
          productEntries,
          productEntries.categoryId,
        );
        await _addColumnIfMissing(
          migrator,
          productEntries,
          productEntries.variantGroup,
        );
        await _addColumnIfMissing(
          migrator,
          productEntries,
          productEntries.variantLabel,
        );
        await _addColumnIfMissing(
          migrator,
          heldBillEntries,
          heldBillEntries.storeId,
        );
        await _addColumnIfMissing(migrator, saleEntries, saleEntries.storeId);
        await _addColumnIfMissing(migrator, saleEntries, saleEntries.counterId);
        await _addColumnIfMissing(migrator, saleEntries, saleEntries.userId);
        await _addColumnIfMissing(migrator, saleEntries, saleEntries.userName);
        await _addColumnIfMissing(
          migrator,
          saleLineEntries,
          saleLineEntries.offerKind,
        );
        await _addColumnIfMissing(
          migrator,
          saleLineEntries,
          saleLineEntries.offerName,
        );
        await _addColumnIfMissing(
          migrator,
          saleLineEntries,
          saleLineEntries.offerSavingMinor,
        );
        await _addColumnIfMissing(
          migrator,
          saleLineEntries,
          saleLineEntries.offerUnitOffMinor,
        );
        await _addColumnIfMissing(
          migrator,
          saleLineEntries,
          saleLineEntries.isGift,
        );
      });
    }
    if (from < 10 && to >= 10) {
      // One transaction: v10 is all-or-nothing.
      await transaction(() async {
        await migrator.createTable(storeForexEntries);
        await migrator.createTable(taxRegimeEntries);
        await migrator.createTable(taxSlabEntries);
      });
    }
    if (from < 11 && to >= 11) {
      // Rebuilds the tables with INTEGER stamps in one transaction (DEC-147).
      await EpochV11Migration(this).run();
    }
    if (from < 12 && to >= 12) {
      // One transaction: v12 is all-or-nothing (DEC-148).
      await transaction(() async {
        await migrator.createTable(inventoryBalanceEntries);
        await migrator.createTable(inventoryTransactionEntries);
        // Idempotent, like createTable (tests fake old versions on top of
        // the current schema).
        await customStatement(
          'CREATE INDEX IF NOT EXISTS inventory_tx_product ON '
          'inventory_transactions (store_id, product_id, created_at)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS inventory_tx_ref ON '
          'inventory_transactions (ref_type, ref_id)',
        );
        await _addColumnIfMissing(
          migrator,
          storeEntries,
          storeEntries.allowNegativeStock,
        );
        await _backfillInventory();
      });
    }
  }

  /// Opening balances from `products.stock` for the products that belong to a
  /// store (a balance needs a store). Stock 0 gets a balance row and no
  /// transaction.
  Future<void> _backfillInventory() async {
    // Only a products table of the real shape (an older chain step may have
    // created a stub in tests).
    final info = await customSelect('PRAGMA table_info(products)').get();
    final names = {for (final r in info) r.read<String>('name')};
    if (!names.containsAll(const ['stock', 'store_id', 'deleted_at'])) return;
    final existing = await customSelect(
      'SELECT count(*) AS n FROM inventory_balance',
    ).getSingle();
    if (existing.read<int>('n') != 0) return;
    const uuid =
        "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || "
        "'-4' || substr(lower(hex(randomblob(2))), 2) || '-' || "
        "substr('89ab', abs(random()) % 4 + 1, 1) || "
        "substr(lower(hex(randomblob(2))), 2) || '-' || "
        'lower(hex(randomblob(6)))';
    const now = "CAST(strftime('%s', 'now') AS INTEGER) * 1000";
    await customStatement(
      'INSERT INTO inventory_balance '
      '(store_id, product_id, quantity_milli, updated_at) '
      'SELECT store_id, id, stock * 1000, $now FROM products '
      'WHERE store_id IS NOT NULL AND deleted_at IS NULL',
    );
    await customStatement(
      'INSERT INTO inventory_transactions '
      '(id, store_id, product_id, quantity_delta_milli, reason, ref_type, '
      'created_at, note) '
      "SELECT $uuid, store_id, id, stock * 1000, 'opening', 'backfill', $now, "
      "'backfill from products.stock' FROM products "
      'WHERE store_id IS NOT NULL AND deleted_at IS NULL AND stock != 0',
    );
  }

  Future<void> _addColumnIfMissing(
    Migrator migrator,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> column,
  ) async {
    final info = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    if (info.any((row) => row.read<String>('name') == column.name)) return;
    await migrator.addColumn(table, column);
  }

  /// Runs `<body>` in a transaction and makes the commit durable on web.
  ///
  /// Drift's web (IndexedDB) storage only flushes after a statement outside a
  /// transaction, so the last committed transaction can stay in memory and be
  /// lost when the tab closes (found in D1, see DEC-125). The trailing no-op
  /// pragma is that statement; on native it is free.
  Future<T> durableTransaction<T>(Future<T> Function() body) async {
    final result = await transaction(body);
    await customStatement('PRAGMA foreign_keys = ON');
    return result;
  }
}
