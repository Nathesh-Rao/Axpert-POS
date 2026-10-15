import 'package:drift/drift.dart';

import '../bindings/startup_timeline.dart';
import 'migration/catalog_v14_migration.dart';
import 'migration/epoch_v11_migration.dart';
import 'tables/barcode_entries.dart';
import 'tables/brand_entries.dart';
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
import 'tables/packaging_entries.dart';
import 'tables/payment_entries.dart';
import 'tables/payment_method_entries.dart';
import 'tables/product_entries.dart';
import 'tables/sale_entries.dart';
import 'tables/sale_line_entries.dart';
import 'tables/seed_manifest_entries.dart';
import 'tables/settings_entries.dart';
import 'tables/store_entries.dart';
import 'tables/store_forex_entries.dart';
import 'tables/tax_regime_entries.dart';
import 'tables/unit_entries.dart';
import 'tables/user_entries.dart';

part 'axpert_database.g.dart';

/// Drift database: device context metadata and device-local settings.
///
/// Schema v14 adds units, brands, product_packagings, product_barcodes and
/// the packaging snapshot columns of sale_lines (DEC-151).
/// Schema v13 adds payment_methods and payments.method_id (DEC-149).
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
    PaymentMethodEntries,
    UnitEntries,
    BrandEntries,
    PackagingEntries,
    BarcodeEntries,
  ],
)
class AxpertDatabase extends _$AxpertDatabase {
  AxpertDatabase(super.executor);

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => StartupTimeline.measure('schema create', () async {
      await migrator.createAll();
      await CatalogV14Migration.createIndexes(this);
      await CatalogV14Migration.seedUnits(this);
    }),
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
    if (from < 13 && to >= 13) {
      // One transaction: v13 is all-or-nothing (DEC-149).
      await transaction(() async {
        await migrator.createTable(paymentMethodEntries);
        final hasPayments = await customSelect(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' "
          "AND name = 'payments'",
        ).get();
        if (hasPayments.isNotEmpty) {
          await _addColumnIfMissing(
            migrator,
            paymentEntries,
            paymentEntries.methodId,
          );
        }
        await _backfillPaymentMethods();
      });
    }
    if (from < 14 && to >= 14) {
      // One transaction: v14 is all-or-nothing (DEC-151).
      await transaction(() => CatalogV14Migration(this).run(migrator));
    }
  }

  /// The four default methods for every store, and `payments.method_id` for
  /// the payments that already exist (by the sale's store and the method
  /// text). Skipped when a table of an older chain step is only a stub.
  Future<void> _backfillPaymentMethods() async {
    Future<Set<String>> columns(String table) async => {
      for (final r in await customSelect('PRAGMA table_info($table)').get())
        r.read<String>('name'),
    };
    final stores = await columns('stores');
    if (!stores.containsAll(const ['id', 'deleted_at'])) return;
    const now = "CAST(strftime('%s', 'now') AS INTEGER) * 1000";
    await customStatement(
      'INSERT OR IGNORE INTO payment_methods (id, store_id, code, name, type, '
      'enabled, sort_order, requires_reference, created_at, updated_at) '
      'SELECT $sqlUuid, s.id, m.code, m.name, m.type, 1, m.sort_order, '
      'm.requires_reference, $now, $now FROM stores s CROSS JOIN ('
      "SELECT 'cash' AS code, 'Cash' AS name, 'cash' AS type, "
      '1 AS sort_order, 0 AS requires_reference UNION ALL '
      "SELECT 'card', 'Card', 'card', 2, 0 UNION ALL "
      "SELECT 'bank_transfer', 'Bank transfer', 'bank_transfer', 3, 1 UNION ALL "
      "SELECT 'mobile_money', 'Mobile money', 'mobile_money', 4, 1"
      ') m WHERE s.deleted_at IS NULL',
    );
    final payments = await columns('payments');
    final sales = await columns('sales');
    if (!payments.containsAll(const ['method', 'method_id', 'sale_id']) ||
        !sales.contains('store_id')) {
      return;
    }
    await customStatement(
      'UPDATE payments SET method_id = ('
      'SELECT pm.id FROM payment_methods pm JOIN sales sa '
      'ON sa.store_id = pm.store_id WHERE sa.id = payments.sale_id '
      'AND pm.code = payments.method) WHERE method_id IS NULL',
    );
  }

  /// SQL expression for a random UUID v4 text.
  static const String sqlUuid =
      "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || "
      "'-4' || substr(lower(hex(randomblob(2))), 2) || '-' || "
      "substr('89ab', abs(random()) % 4 + 1, 1) || "
      "substr(lower(hex(randomblob(2))), 2) || '-' || "
      'lower(hex(randomblob(6)))';

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
      "SELECT $sqlUuid, store_id, id, stock * 1000, 'opening', 'backfill', $now, "
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
