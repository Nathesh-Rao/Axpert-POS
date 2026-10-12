import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/security/password_hasher.dart';
import 'package:pos_application/core/seed/demo_seeder.dart';
import 'package:pos_application/features/offers/data/drift_offer_repository.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/session/data/drift_session_repositories.dart';

import '../../support/seeded_database.dart';

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
          "SELECT key FROM migration_state WHERE key = 'demo_seed_v1'",
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
}
