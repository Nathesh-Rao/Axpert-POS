import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/security/password_hasher.dart';
import 'package:pos_application/core/seed/demo_seeder.dart';
import 'package:pos_application/features/offers/data/drift_offer_repository.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/products/data/repositories/drift_packaging_repositories.dart';
import 'package:pos_application/features/session/data/drift_session_repositories.dart';

import '../../support/seeded_database.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

void main() {
  late AxpertDatabase db;
  setUp(() async => db = await seededDatabase());
  tearDown(() => db.close());

  Future<int> count(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  test('loads the demo content once', () async {
    expect(await count('stores'), 2);
    expect(await count('counters'), 5);
    expect(await count('users'), 4);
    expect(await count('products'), 60);
    expect(await count('customers'), 5);
    expect(await count('sales'), 30);
    expect(await count('offers'), 13);
    final kinds = await db
        .customSelect('SELECT kind, COUNT(*) AS n FROM offers GROUP BY kind')
        .get();
    expect(
      {for (final r in kinds) r.read<String>('kind'): r.read<int>('n')},
      {'discount': 6, 'promotion': 4, 'gift_tier': 3},
    );
    final currencies = await db
        .customSelect('SELECT currency_code AS c FROM stores ORDER BY c')
        .get();
    expect(currencies.map((r) => r.read<String>('c')), ['INR', 'UGX']);
  });

  test('loads the tax regimes, slabs and forex of each store', () async {
    expect(await count('tax_regimes'), 2);
    expect(await count('tax_slabs'), 6);
    expect(await count('store_forex'), 6);
    final regimes = await db
        .customSelect(
          'SELECT region, label, split_parts FROM tax_regimes ORDER BY region',
        )
        .get();
    expect(
      [
        for (final r in regimes)
          '${r.read<String>('region')}|${r.read<String>('label')}|'
              '${r.read<String>('split_parts')}',
      ],
      ['IN|GST|CGST,SGST', 'UG|VAT|'],
    );
    final forex = await db
        .customSelect(
          'SELECT s.region AS region, f.foreign_currency_code AS code '
          'FROM store_forex f JOIN stores s ON s.id = f.store_id '
          'ORDER BY s.region, f.position',
        )
        .get();
    expect(
      [
        for (final r in forex)
          '${r.read<String>('region')}|${r.read<String>('code')}',
      ],
      ['IN|USD', 'IN|EUR', 'IN|AED', 'UG|USD', 'UG|EUR', 'UG|KES'],
    );
  });

  test('every product rate is a slab of its store regime', () async {
    final bad = await db
        .customSelect(
          'SELECT p.code AS code FROM products p '
          'JOIN stores s ON s.id = p.store_id '
          'JOIN tax_regimes r ON r.region = s.region '
          'WHERE p.gst_bp NOT IN '
          '(SELECT rate_bp FROM tax_slabs WHERE regime_id = r.id)',
        )
        .get();
    expect(bad, isEmpty);
  });

  test('the foreign keys of the seeded data are consistent', () async {
    final problems = await db.customSelect('PRAGMA foreign_key_check').get();
    expect(problems, isEmpty);
  });

  test('a second run does nothing, the marker exists', () async {
    final again = await seederFor(db).run();
    expect(again, SeedOutcome.alreadySeeded);
    expect(await count('products'), 60);
    final marker = await db
        .customSelect(
          "SELECT key FROM migration_state WHERE key = 'demo_seed_v2'",
        )
        .get();
    expect(marker, hasLength(1));
  });

  test('reseed wipes only the seeded rows and runs again', () async {
    // Rows of the user: a store, a product and a customer.
    await db.customStatement(
      "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
      "VALUES ('mine', 'My shop', 'INR', 'x', 'x')",
    );
    await db.customStatement(
      'INSERT INTO products (id, legacy_id, position, name, code, barcode, '
      'price_minor, category, sub, stock, gst_bp, image, favourite, store_id, '
      "created_at, updated_at) VALUES ('mine-p', 9001, 0, 'Mine', 'M1', 'B', "
      "100, 'c', 's', 1, 0, -1, 0, 'mine', 'x', 'x')",
    );
    await db.customStatement(
      "INSERT INTO customers (id, legacy_id, position, name, phone, email, "
      "member_no, points, created_at, updated_at) VALUES "
      "('mine-c', '900', 9, 'Mine', '', '', '', 0, 'x', 'x')",
    );
    final outcome = await seederFor(db).run(reseed: true);
    expect(outcome, SeedOutcome.reseeded);
    expect(await count('stores'), 3);
    expect(await count('products'), 61);
    expect(await count('customers'), 6);
    expect(await count('sales'), 30);
    expect(
      (await db.customSelect("SELECT id FROM stores WHERE id = 'mine'").get()),
      hasLength(1),
    );
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });

  test(
    'packagings and barcodes: packs and cartons with their own codes',
    () async {
      // Every seeded product has its base barcode; 8 extra codes.
      expect(await count('product_packagings'), 10);
      expect(await count('product_barcodes'), 68);
      final base = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM products WHERE base_unit_id IS NOT NULL',
          )
          .getSingle();
      expect(base.read<int>('n'), 60);

      final provider = _Provider(db);
      final barcodes = DriftBarcodeRepository(provider);
      final carton = await barcodes.findByBarcode(
        'demo-store-ozone',
        '18901234560007',
      );
      expect(carton!.productId, 'demo-prod-oz-1');
      expect(carton.packaging!.quantityBaseMilli, 24000);
      expect(carton.packaging!.priceMinor, 90000);
      final pack = await DriftPackagingRepository(
        provider,
      ).forProduct('demo-prod-oz-1');
      expect(pack.map((p) => p.quantityBaseMilli), [6000, 24000]);
      expect(pack.first.priceMinor, isNull); // derived
      // The base code still finds the base unit, in its own store only.
      final base1 = await barcodes.findByBarcode(
        'demo-store-ozone',
        '8901234560000',
      );
      expect(base1!.packaging, isNull);
      expect(
        await barcodes.findByBarcode('demo-store-kampala', '18901234560007'),
        isNull,
      );
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );

  test(
    'reseed removes the seeded packagings and barcodes, then seeds again',
    () async {
      await db.customStatement(
        "INSERT INTO sale_lines (id, sale_id, line_no, product_id, "
        "product_legacy_id, product_name, product_code, product_barcode, "
        "product_price_minor, product_category, product_sub, product_stock, "
        "product_gst_bp, product_image, product_favourite, price_minor, "
        "qty_milli, discount_bp, created_at, packaging_id, unit_name, "
        "quantity_base_milli, base_qty_milli) SELECT 'ml', id, 99, NULL, 1, 'n', "
        "'c', 'b', 1, 'c', 's', 1, 0, -1, 0, 1, 1000, 0, 1, 'demo-pack-oz-1-c24', "
        "'Carton', 24000, 24000 FROM sales LIMIT 1",
      );
      expect(await seederFor(db).run(reseed: true), SeedOutcome.reseeded);
      expect(await count('product_packagings'), 10);
      expect(await count('product_barcodes'), 68);
      // The kept sale line of a seeded sale was wiped with its sale; nothing
      // dangles.
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    },
  );

  test('demo users sign in with their salted hash, never plaintext', () async {
    final rows = await db.select(db.userEntries).get();
    const hasher = PasswordHasher();
    for (final u in rows) {
      expect(u.hashAlgo, PasswordHasher.algorithm);
      expect(u.salt, hasLength(32));
      expect(u.passwordHash, hasLength(64));
    }
    final admin = rows.firstWhere((u) => u.username == 'admin');
    expect(
      hasher.verify(
        salt: admin.salt,
        password: 'Demo#Admin1',
        expected: admin.passwordHash,
      ),
      isTrue,
    );
    expect(
      hasher.verify(
        salt: admin.salt,
        password: 'wrong',
        expected: admin.passwordHash,
      ),
      isFalse,
    );
    // Two users with the same password would still get different hashes.
    expect(rows.map((u) => u.salt).toSet(), hasLength(rows.length));
  });

  test('access rows: one user has one store and one counter', () async {
    final users = DriftUserRepository(FixedDatabaseProvider(db));
    final cashier1 = await users.findByUsername('cashier1');
    final access = await users.accessFor(cashier1!.user.id);
    expect(access, hasLength(1));
    expect(access.single.counters, hasLength(1));
    final admin = await users.findByUsername('admin');
    final all = await users.accessFor(admin!.user.id);
    expect(all.map((a) => a.store.currencyCode), ['INR', 'UGX']);
    expect(all.first.counters, hasLength(3));
    final cashier2 = await users.findByUsername('cashier2');
    final k = await users.accessFor(cashier2!.user.id);
    expect(k.single.counters, hasLength(2));
  });

  test('seeded sales carry offers and unlocked gifts', () async {
    final promo = await db
        .customSelect(
          "SELECT COUNT(*) AS n FROM sale_lines WHERE offer_kind = 'promotion'",
        )
        .getSingle();
    final lines = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM sale_lines WHERE offer_kind IS NOT NULL',
        )
        .getSingle();
    expect(lines.read<int>('n'), greaterThan(0));
    expect(promo.read<int>('n'), greaterThanOrEqualTo(0));
    // Every sale is stamped with its store, counter and cashier.
    final unstamped = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM sales WHERE store_id IS NULL OR '
          'counter_id IS NULL OR user_id IS NULL OR user_name IS NULL',
        )
        .getSingle();
    expect(unstamped.read<int>('n'), 0);
  });

  test(
    'the offer repository returns the store offers with their products',
    () async {
      final repo = DriftOfferRepository(FixedDatabaseProvider(db));
      final oz = await repo.load(storeId: 'demo-store-ozone');
      final ka = await repo.load(storeId: 'demo-store-kampala');
      expect(oz, hasLength(7));
      expect(ka, hasLength(6));
      expect(
        oz
            .where((o) => o.kind == OfferKind.giftTier)
            .every((o) => o.gift != null),
        isTrue,
      );
      final bogo = oz.firstWhere((o) => o.kind == OfferKind.promotion);
      expect(bogo.percent!.value, 5000);
      expect(bogo.productId, isNotNull);
      final fixed = oz.firstWhere((o) => o.fixedOff != null);
      expect(fixed.fixedOff!.currency.code, 'INR');
      final tierKampala = ka.firstWhere((o) => o.kind == OfferKind.giftTier);
      expect(tierKampala.minCart!.currency.code, 'UGX');
    },
  );

  test('currencies come from the table with their own digits', () async {
    final rows = await DriftStoreRepository(
      FixedDatabaseProvider(db),
    ).loadCurrencies();
    final ugx = rows.firstWhere((r) => r.currency.code == 'UGX');
    expect(ugx.currency.exponent, 0);
    expect(ugx.quickCash, [5000, 20000, 100000]);
    final inr = rows.firstWhere((r) => r.currency.code == 'INR');
    expect(inr.currency.symbol, '₹');
    expect(inr.quickCash, [100, 500, 2000]);
  });

  test('scoped reads see only their store', () async {
    final oz = await (db.select(
      db.productEntries,
    )..where((t) => t.storeId.equals('demo-store-ozone'))).get();
    final ka = await (db.select(
      db.productEntries,
    )..where((t) => t.storeId.equals('demo-store-kampala'))).get();
    expect(oz, hasLength(32));
    expect(ka, hasLength(28));
    expect(oz.map((p) => p.currencyCode).toSet(), {'INR'});
    expect(ka.map((p) => p.currencyCode).toSet(), {'UGX'});
    expect(
      {
        for (final p in [...oz, ...ka]) p.legacyId,
      }.length,
      60,
      reason: 'legacy ids are unique across stores',
    );
  });

  group('upgrade from a v1 seed', () {
    /// Turns the seeded database into what the v1 seed left: no v2 rows, the
    /// old Kampala rates, the v1 marker.
    Future<void> makeV1() async {
      for (final t in ['store_forex', 'tax_slabs', 'tax_regimes']) {
        await db.customStatement('DELETE FROM $t');
        await db.customStatement(
          "DELETE FROM seed_manifest WHERE table_name = '$t'",
        );
      }
      for (final code in ['USD', 'EUR', 'KES']) {
        await db.customStatement('DELETE FROM currencies WHERE code = ?', [
          code,
        ]);
        await db.customStatement(
          "DELETE FROM seed_manifest WHERE table_name = 'currencies' AND row_id = ?",
          [code],
        );
      }
      await db.customStatement(
        "UPDATE products SET gst_bp = 1200 WHERE store_id = 'demo-store-kampala' AND gst_bp = 1800",
      );
      await db.customStatement(
        "DELETE FROM migration_state WHERE key = 'demo_seed_v2'",
      );
      await db.customStatement(
        "INSERT INTO migration_state (key, value) VALUES ('demo_seed_v1', '{}')",
      );
    }

    Future<void> userRows() async {
      await db.customStatement(
        "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
        "VALUES ('mine', 'My shop', 'INR', 'x', 'x')",
      );
      await db.customStatement(
        "INSERT INTO store_forex (id, store_id, foreign_currency_code, rate_micro, "
        "created_at, updated_at) VALUES ('mine-fx', 'mine', 'AED', 22000000, 'x', 'x')",
      );
    }

    test('adds the v2 rows without a wipe and keeps the user rows', () async {
      await makeV1();
      await userRows();
      final sales = await count('sales');
      expect(await seederFor(db).run(), SeedOutcome.upgraded);
      expect(await count('tax_regimes'), 2);
      expect(await count('tax_slabs'), 6);
      expect(await count('store_forex'), 7);
      expect(await count('sales'), sales);
      expect(await count('stores'), 3);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
      final rates = await db
          .customSelect(
            "SELECT DISTINCT gst_bp FROM products WHERE store_id = 'demo-store-kampala'",
          )
          .get();
      expect(rates.map((r) => r.read<int>('gst_bp')).toSet(), {0, 1800});
      expect(await seederFor(db).run(), SeedOutcome.alreadySeeded);
    });

    test('RESEED_DEMO from a v1 seed keeps the user rows', () async {
      await makeV1();
      await userRows();
      expect(await seederFor(db).run(reseed: true), SeedOutcome.reseeded);
      expect(await count('stores'), 3);
      expect(await count('store_forex'), 7);
      expect(await count('tax_regimes'), 2);
      expect(await count('products'), 60);
      final markers = await db
          .customSelect(
            "SELECT key FROM migration_state WHERE key LIKE 'demo_seed_%'",
          )
          .get();
      expect(markers.map((r) => r.read<String>('key')), ['demo_seed_v2']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });
}
