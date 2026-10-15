import 'dart:convert';
import '../../modules/pos/models/line_key.dart';

import 'package:drift/drift.dart';

import '../../features/offers/domain/entities/offer.dart';
import '../../features/offers/domain/services/offer_engine.dart';
import '../../features/products/domain/entities/product.dart';
import '../../modules/pos/models/cart.dart';
import '../../modules/pos/models/cart_line.dart';
import '../../modules/pos/services/offer_cart_builder.dart';
import '../../modules/sales/models/sale.dart';
import '../database/axpert_database.dart';
import '../database/migration/sale_rows.dart';
import '../database/tables/unit_entries.dart';
import '../identifiers/uuid_generator.dart';
import '../security/password_hasher.dart';
import '../services/pricing/basis_points.dart';
import '../services/pricing/currency.dart';
import '../services/pricing/currency_registry.dart';
import '../services/pricing/money.dart';
import '../services/pricing/pricing_models.dart';
import '../services/pricing/pricing_service.dart';
import '../services/pricing/qty.dart';
import '../services/pricing/tax_config.dart';
import '../session/store_scope.dart';
import '../utils/epoch_time.dart';
import '../../features/payment/data/repositories/drift_payment_method_repository.dart';

/// Compile-time switches (`--dart-define=DEMO_SEED=true`, `RESEED_DEMO=true`).
abstract final class DemoSeedConfig {
  static const bool enabled = bool.fromEnvironment('DEMO_SEED');
  static const bool reseed = bool.fromEnvironment('RESEED_DEMO');
}

enum SeedOutcome { seeded, reseeded, upgraded, alreadySeeded }

/// Reads one seed asset (JSON text) by file name, e.g. `products.json`.
typedef SeedAssetLoader = Future<String> Function(String name);

/// The only place in `lib/` that knows demo data (DEC-135): loads the JSON
/// assets of `assets/seed/` once, in one transaction, and records every row it
/// inserted in `seed_manifest` so a reseed deletes only those rows.
class DemoSeeder {
  DemoSeeder({
    required this.db,
    required this.loadAsset,
    required this.uuid,
    PasswordHasher hasher = const PasswordHasher(),
    DateTime Function()? now,
  }) : _hasher = hasher,
       _now = now ?? DateTime.now;

  static const String marker = 'demo_seed_v2';

  /// Marker of the first seed (no forex, regimes or slabs yet): a database
  /// that has it is upgraded additively to v2.
  static const String legacyMarker = 'demo_seed_v1';

  /// The copy markers the legacy LocalStore migrators check: set by the seeder
  /// so they never copy an (empty) LocalStore over the seeded rows.
  static const List<String> _migrationMarkers = <String>[
    'products_copy_v1',
    'customers_copy_v1',
    'sales_copy_v1',
    'held_copy_v1',
    'cart_copy_v1',
  ];

  final AxpertDatabase db;
  final SeedAssetLoader loadAsset;
  final UuidGenerator uuid;
  final PasswordHasher _hasher;
  final DateTime Function() _now;

  Future<SeedOutcome> run({bool reseed = false}) async {
    final current = await _marker(marker);
    final legacy = await _marker(legacyMarker);
    if (current != null && !reseed) return SeedOutcome.alreadySeeded;
    final data = await _SeedData.load(loadAsset);
    final seededBefore = current != null || legacy != null;
    await db.durableTransaction(() async {
      if (seededBefore && (reseed || current != null)) {
        // User rows (products, categories) may point at seeded stores and
        // categories whose ids come back with the re-insert: check the
        // foreign keys at commit, not row by row (DEC-152).
        await db.customStatement('PRAGMA defer_foreign_keys = ON');
        await _wipe();
        await _insert(data);
      } else if (legacy != null) {
        await _upgradeV1(data);
      } else {
        await _insert(data);
      }
    });
    if (!seededBefore) return SeedOutcome.seeded;
    return reseed ? SeedOutcome.reseeded : SeedOutcome.upgraded;
  }

  Future<MigrationStateEntry?> _marker(String key) => (db.select(
    db.migrationStateEntries,
  )..where((t) => t.key.equals(key))).getSingleOrNull();

  /// v1 to v2 without a wipe: adds the rows v2 introduced (currencies, tax
  /// regimes, slabs, forex), moves seeded product rates that are no slab of
  /// their store's regime onto the seed value, and sets the new marker. Rows
  /// the user made are never touched.
  Future<void> _upgradeV1(_SeedData d) async {
    final now = _stamp;
    await _insertCurrencies(d, now);
    await _insertRegimes(d, now);
    await _insertForex(d, now);
    final storeRegion = {
      for (final st in d.stores) st['id'] as String: st['region'] as String,
    };
    final slabsByRegion = {
      for (final r in d.regimes)
        r['region'] as String: {
          for (final sl in (r['slabs'] as List).cast<Map<String, dynamic>>())
            sl['rateBp'] as int,
        },
    };
    final seeded = await _ids('products');
    for (final p in d.products) {
      final id = p['id'] as String;
      if (!seeded.contains(id)) continue;
      final slabs = slabsByRegion[storeRegion[p['store']]];
      if (slabs == null) continue;
      final row = await (db.select(
        db.productEntries,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null || slabs.contains(row.gstBp)) continue;
      await (db.update(db.productEntries)..where((t) => t.id.equals(id))).write(
        ProductEntriesCompanion(
          gstBp: Value(p['gstBp'] as int),
          updatedAt: Value(now),
        ),
      );
    }
    await _writeMarker(now);
  }

  Future<void> _writeMarker(int now) => db
      .into(db.migrationStateEntries)
      .insert(
        MigrationStateEntriesCompanion.insert(
          key: marker,
          value: jsonEncode(<String, Object>{
            'seeded_at': EpochTime.toIso(now),
          }),
        ),
        mode: InsertMode.insertOrReplace,
      );

  // ---------------------------------------------------------------- insert

  int get _stamp => EpochTime.fromDateTime(_now());

  /// Opening stock of a demo product: its balance and one `opening`
  /// transaction (DEC-148).
  Future<void> _openingStock(
    Map<String, dynamic> p,
    String store,
    int now,
  ) async {
    final id = p['id'] as String;
    final stock = p['stock'] as int;
    await db
        .into(db.inventoryBalanceEntries)
        .insert(
          InventoryBalanceEntriesCompanion.insert(
            storeId: store,
            productId: id,
            quantityMilli: stock * 1000,
            updatedAt: now,
          ),
        );
    if (stock == 0) return;
    await db
        .into(db.inventoryTransactionEntries)
        .insert(
          InventoryTransactionEntriesCompanion.insert(
            id: uuid.generate(),
            storeId: store,
            productId: id,
            quantityDeltaMilli: stock * 1000,
            reason: 'opening',
            refType: const Value('seed'),
            createdAt: now,
            note: const Value('demo opening stock'),
          ),
        );
  }

  Future<void> _barcode({
    required String id,
    required String productId,
    required String? storeId,
    required String barcode,
    String? packagingId,
    required int now,
  }) async {
    await db
        .into(db.barcodeEntries)
        .insert(
          BarcodeEntriesCompanion.insert(
            id: id,
            productId: productId,
            packagingId: Value(packagingId),
            storeId: Value(storeId),
            barcode: barcode,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await _track('product_barcodes', id);
  }

  /// Packs, cartons and boxes of some demo products with their own barcodes
  /// (DEC-151). Prices are derived unless the seed sets one.
  Future<void> _packagings(_SeedData d, int now) async {
    final storeOf = {
      for (final p in d.products) p['id'] as String: p['store'] as String,
    };
    final unitIds = {for (final u in SeedUnits.all) u.code: u.id};
    for (final k in d.packagings) {
      await db
          .into(db.packagingEntries)
          .insert(
            PackagingEntriesCompanion.insert(
              id: k['id'] as String,
              productId: k['product'] as String,
              unitId: unitIds[k['unit'] as String]!,
              name: k['name'] as String,
              quantityBaseMilli: k['quantityBaseMilli'] as int,
              sku: Value(k['sku'] as String?),
              priceMinor: Value(k['priceMinor'] as int?),
              sortOrder: Value(k['sortOrder'] as int? ?? 0),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _track('product_packagings', k['id'] as String);
    }
    for (final b in d.extraBarcodes) {
      await _barcode(
        id: b['id'] as String,
        productId: b['product'] as String,
        storeId: storeOf[b['product'] as String],
        barcode: b['barcode'] as String,
        packagingId: b['packaging'] as String?,
        now: now,
      );
    }
  }

  /// Cash, card, bank transfer and mobile money for a demo store (DEC-149).
  Future<void> _paymentMethods(String storeId, int now) async {
    for (final (i, m) in MockPaymentMethodRepository.defaults.indexed) {
      await db
          .into(db.paymentMethodEntries)
          .insert(
            PaymentMethodEntriesCompanion.insert(
              id: uuid.generate(),
              storeId: storeId,
              code: m.$1,
              name: m.$2,
              methodType: m.$3,
              sortOrder: Value(i + 1),
              requiresReference: Value(m.$4),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  Future<void> _track(String table, String id) => db
      .into(db.seedManifestEntries)
      .insert(
        SeedManifestEntriesCompanion.insert(tableNameValue: table, rowId: id),
        mode: InsertMode.insertOrIgnore,
      );

  Future<void> _insert(_SeedData d) async {
    final now = _stamp;
    await _insertCurrencies(d, now);
    await _insertRegimes(d, now);
    var storeIndex = 0;
    for (final s in d.stores) {
      // Stores sort by creation time: keep the file order.
      final storeStamp = _stamp + storeIndex++;
      await db
          .into(db.storeEntries)
          .insert(
            StoreEntriesCompanion.insert(
              id: s['id'] as String,
              name: s['name'] as String,
              address: Value(s['address'] as String? ?? ''),
              phone: Value(s['phone'] as String? ?? ''),
              taxId: Value(s['taxId'] as String? ?? ''),
              receiptHeader: Value(s['receiptHeader'] as String? ?? ''),
              receiptFooter: Value(s['receiptFooter'] as String? ?? ''),
              currencyCode: s['currencyCode'] as String,
              region: Value(s['region'] as String? ?? ''),
              createdAt: storeStamp,
              updatedAt: storeStamp,
            ),
          );
      await _track('stores', s['id'] as String);
      await _paymentMethods(s['id'] as String, now);
      for (final c in (s['counters'] as List).cast<Map<String, dynamic>>()) {
        await db
            .into(db.counterEntries)
            .insert(
              CounterEntriesCompanion.insert(
                id: c['id'] as String,
                storeId: s['id'] as String,
                name: c['name'] as String,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await _track('counters', c['id'] as String);
      }
    }
    await _insertForex(d, now);
    for (final u in d.users) {
      final salt = _hasher.newSalt();
      await db
          .into(db.userEntries)
          .insert(
            UserEntriesCompanion.insert(
              id: u['id'] as String,
              username: u['username'] as String,
              displayName: u['displayName'] as String,
              role: u['role'] as String,
              salt: salt,
              passwordHash: _hasher.hash(salt, u['demoPassword'] as String),
              hashAlgo: PasswordHasher.algorithm,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _track('users', u['id'] as String);
      var n = 0;
      for (final a in (u['access'] as List).cast<Map<String, dynamic>>()) {
        final id = '${u['id']}-access-${++n}';
        await db
            .into(db.userAccessEntries)
            .insert(
              UserAccessEntriesCompanion.insert(
                id: id,
                userId: u['id'] as String,
                storeId: a['store'] as String,
                counterId: Value(a['counter'] as String?),
              ),
            );
        await _track('user_access', id);
      }
    }
    for (final c in d.categories) {
      await db
          .into(db.categoryEntries)
          .insert(
            CategoryEntriesCompanion.insert(
              id: c['id'] as String,
              name: c['name'] as String,
              parentId: Value(c['parent'] as String?),
              iconKey: Value(c['icon'] as String? ?? ''),
              position: Value(c['position'] as int? ?? 0),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _track('categories', c['id'] as String);
    }
    var position = <String, int>{};
    for (final p in d.products) {
      final store = p['store'] as String;
      final index = position[store] = (position[store] ?? -1) + 1;
      await db
          .into(db.productEntries)
          .insert(
            ProductEntriesCompanion.insert(
              id: p['id'] as String,
              legacyId: p['legacyId'] as int,
              position: index,
              name: p['name'] as String,
              code: p['code'] as String,
              barcode: p['barcode'] as String,
              priceMinor: p['priceMinor'] as int,
              currencyCode: Value(p['currencyCode'] as String),
              category: p['category'] as String,
              sub: p['sub'] as String,
              stock: p['stock'] as int,
              gstBp: p['gstBp'] as int,
              image: p['image'] as int,
              favourite: p['favourite'] as bool,
              storeId: Value(store),
              categoryId: Value(p['categoryId'] as String?),
              baseUnitId: Value(SeedUnits.piece.id),
              variantGroup: Value(p['variantGroup'] as String?),
              variantLabel: Value(p['variantLabel'] as String?),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _track('products', p['id'] as String);
      await _openingStock(p, store, now);
      await _barcode(
        id: uuid.generate(),
        productId: p['id'] as String,
        storeId: store,
        barcode: p['barcode'] as String,
        now: now,
      );
    }
    await _packagings(d, now);
    position = <String, int>{};
    var customerIndex = 0;
    for (final c in d.customers) {
      final id = 'demo-customer-${c['legacyId']}';
      final inserted = await db
          .into(db.customerEntries)
          .insert(
            CustomerEntriesCompanion.insert(
              id: id,
              legacyId: c['legacyId'] as String,
              position: customerIndex++,
              name: c['name'] as String,
              phone: c['phone'] as String,
              email: c['email'] as String,
              memberNo: c['member'] as String,
              points: c['points'] as int,
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // 0 = ignored (a customer with that id already exists): not ours.
      if (inserted != 0) await _track('customers', id);
    }
    final products = d.productEntities();
    final offers = d.offers(products);
    for (final o in d.offerRows) {
      await db
          .into(db.offerEntries)
          .insert(
            OfferEntriesCompanion.insert(
              id: o['id'] as String,
              kind: o['kind'] as String,
              name: o['name'] as String,
              storeId: Value(o['store'] as String?),
              productId: Value(o['product'] as String?),
              percentBp: Value(o['percentBp'] as int?),
              fixedAmountMinor: Value(o['fixedMinor'] as int?),
              currencyCode: Value(o['currency'] as String?),
              minCartMinor: Value(o['minCartMinor'] as int?),
              giftProductId: Value(o['gift'] as String?),
              startsAt: Value(_relative(o['startsDaysAgo'], -1)),
              endsAt: Value(_relative(o['endsInDays'], 1)),
              priority: Value(o['priority'] as int? ?? 0),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _track('offers', o['id'] as String);
    }
    await _insertSales(d, products, offers);
    for (final key in _migrationMarkers) {
      final present = await (db.select(
        db.migrationStateEntries,
      )..where((t) => t.key.equals(key))).getSingleOrNull();
      if (present != null) continue;
      await db
          .into(db.migrationStateEntries)
          .insert(
            MigrationStateEntriesCompanion.insert(
              key: key,
              value: jsonEncode(<String, Object>{'seeded': true}),
            ),
          );
      await _track('migration_state', key);
    }
    await _writeMarker(now);
  }

  Future<void> _insertCurrencies(_SeedData d, int now) async {
    for (final c in d.currencies) {
      final inserted = await db
          .into(db.currencyEntries)
          .insert(
            CurrencyEntriesCompanion.insert(
              code: c['code'] as String,
              name: c['name'] as String,
              symbol: c['symbol'] as String,
              exponent: c['exponent'] as int,
              grouping: c['grouping'] as String,
              quickCash: Value((c['quickCash'] as List).join(',')),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      if (inserted != 0) await _track('currencies', c['code'] as String);
    }
  }

  Future<void> _insertRegimes(_SeedData d, int now) async {
    for (final r in d.regimes) {
      final id = r['id'] as String;
      final inserted = await db
          .into(db.taxRegimeEntries)
          .insert(
            TaxRegimeEntriesCompanion.insert(
              id: id,
              region: r['region'] as String,
              label: r['label'] as String,
              priceMode: r['priceMode'] as String,
              splitParts: Value((r['splitParts'] as List).join(',')),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // 0 = a regime of that region exists already (the user's): not ours.
      if (inserted == 0) continue;
      await _track('tax_regimes', id);
      var n = 0;
      for (final sl in (r['slabs'] as List).cast<Map<String, dynamic>>()) {
        final slabId = '$id-slab-$n';
        await db
            .into(db.taxSlabEntries)
            .insert(
              TaxSlabEntriesCompanion.insert(
                id: slabId,
                regimeId: id,
                rateBp: sl['rateBp'] as int,
                label: Value(sl['label'] as String? ?? ''),
                position: Value(n++),
              ),
            );
        await _track('tax_slabs', slabId);
      }
    }
  }

  Future<void> _insertForex(_SeedData d, int now) async {
    for (final f in d.forex) {
      final id = f['id'] as String;
      final inserted = await db
          .into(db.storeForexEntries)
          .insert(
            StoreForexEntriesCompanion.insert(
              id: id,
              storeId: f['store'] as String,
              foreignCurrencyCode: f['code'] as String,
              rateMicro: f['rateMicro'] as int,
              position: Value(f['position'] as int? ?? 0),
              createdAt: now,
              updatedAt: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      if (inserted != 0) await _track('store_forex', id);
    }
  }

  int? _relative(Object? days, int direction) => days == null
      ? null
      : EpochTime.fromDateTime(
          _now().toUtc().add(Duration(days: (days as int) * direction)),
        );

  Future<void> _insertSales(
    _SeedData d,
    Map<String, Product> products,
    List<Offer> offers,
  ) async {
    const engine = OfferEngine();
    final byStore = <String, List<Map<String, dynamic>>>{};
    for (final s in d.sales) {
      byStore.putIfAbsent(s['store'] as String, () => []).add(s);
    }
    final names = {
      for (final u in d.users) u['id'] as String: u['displayName'] as String,
    };
    final customerNames = {
      for (final c in d.customers) c['legacyId'] as String: c['name'] as String,
    };
    final productByStoreCode = <String, Product>{
      for (final p in d.products)
        '${p['store']}|${p['code']}': products[p['id']]!,
    };
    for (final store in d.stores) {
      final storeId = store['id'] as String;
      final list = byStore[storeId] ?? const <Map<String, dynamic>>[];
      if (list.isEmpty) continue;
      final currency = CurrencyRegistry.byCode(store['currencyCode'] as String);
      final pricing = PricingService(
        config: d
            .taxConfig(store['region'] as String)
            .copyWith(currency: currency),
      );
      final built = <Sale>[];
      for (final spec in list) {
        final when = _now().toUtc().subtract(
          Duration(days: spec['daysAgo'] as int),
        );
        final at = DateTime.utc(
          when.year,
          when.month,
          when.day,
          spec['hour'] as int,
          spec['minute'] as int,
        );
        var cart = Cart(
          lines: <CartLine>[
            for (final l
                in (spec['lines'] as List).cast<Map<String, dynamic>>())
              CartLine.of(
                productByStoreCode['$storeId|${l['code']}']!,
              ).copyWith(qty: Qty.parse('${l['qty']}')),
          ],
          customer: spec['customer'] as String,
          billDiscount: (spec['billDiscountPercent'] as int) > 0
              ? BillDiscount.percent(
                  Bp((spec['billDiscountPercent'] as int) * 100),
                )
              : const BillDiscount.none(),
        );
        final res = engine.resolve(
          lines: <OfferLine>[
            for (final l in cart.lines)
              OfferLine(
                productId: l.product.id,
                qty: l.qty,
                price: l.price,
                manualDiscount: l.discount,
              ),
          ],
          offers: offers,
          now: at,
          currency: currency,
          storeId: storeId,
        );
        final totals = pricing.calculate(
          CartInput(
            lines: <LineInput>[
              for (var i = 0; i < cart.lines.length; i++)
                LineInput(
                  qty: cart.lines[i].qty,
                  price: cart.lines[i].price,
                  taxRate: pricing.config.rateFor(cart.lines[i].product.gst),
                  discount: res.lines[i]?.discount ?? cart.lines[i].discount,
                  unitOff: res.lines[i]?.unitOff,
                ),
            ],
            billDiscount: cart.billDiscount,
          ),
        );
        cart = OfferCartBuilder.asSold(cart, res, currency);
        final mode = spec['mode'] as String;
        final total = totals.total;
        final unit = _roundTo(currency);
        final tendered = mode == 'Cash'
            ? Money(((total.minor + unit - 1) ~/ unit) * unit, currency)
            : total;
        built.add(
          Sale(
            saleId: spec['id'] as String,
            cashier: names[spec['user'] as String],
            number: 'AX${(built.length + 1).toString().padLeft(6, '0')}',
            date: EpochTime.nowIso(at),
            store: store['name'] as String,
            customer: customerNames[spec['customer'] as String] ?? '',
            cart: cart,
            totals: SaleTotals(
              items: totals.items,
              qty: totals.qty,
              value: totals.value,
              subtotal: totals.subtotal,
              discount: totals.discount,
              tax: totals.tax,
              points: totals.points,
              total: totals.total,
            ),
            mode: mode,
            tendered: tendered,
            change: tendered - total,
            returned: const <LineKey, Qty>{},
          ),
        );
      }
      // One store at a time: the rows are stamped with that store's session.
      final scope = StoreScope()
        ..set(storeId: storeId, userName: null, currency: currency);
      final plan = SaleRows.plan(
        built,
        const <String, KnownSale>{},
        now: _stamp,
        uuid: uuid,
      );
      await SaleRows.write(db, plan, now: _stamp, uuid: uuid, scope: scope);
      for (var i = 0; i < built.length; i++) {
        final spec = list[i];
        final id = spec['id'] as String;
        await (db.update(db.saleEntries)..where((t) => t.id.equals(id))).write(
          SaleEntriesCompanion(
            counterId: Value(spec['counter'] as String),
            userId: Value(spec['user'] as String),
          ),
        );
        await _track('sales', id);
      }
    }
  }

  /// Cash is tendered in round amounts (10 currency units, 1,000 when the
  /// currency has no minor unit).
  int _roundTo(Currency currency) {
    var unit = 1;
    for (var i = 0; i < currency.exponent; i++) {
      unit *= 10;
    }
    return currency.exponent == 0 ? 1000 : unit * 10;
  }

  // ------------------------------------------------------------------ wipe

  Future<Set<String>> _ids(String table) async {
    final rows = await (db.select(
      db.seedManifestEntries,
    )..where((t) => t.tableNameValue.equals(table))).get();
    return {for (final r in rows) r.rowId};
  }

  Future<void> _wipe() async {
    final sales = await _ids('sales');
    final offers = await _ids('offers');
    final products = await _ids('products');
    final categories = await _ids('categories');
    final access = await _ids('user_access');
    final users = await _ids('users');
    final counters = await _ids('counters');
    final stores = await _ids('stores');
    final currencies = await _ids('currencies');
    final customers = await _ids('customers');
    final markers = await _ids('migration_state');
    final regimes = await _ids('tax_regimes');

    // Seeded sales and their lines and payments.
    await (db.delete(
      db.paymentEntries,
    )..where((t) => t.saleId.isIn(sales))).go();
    await (db.delete(
      db.saleLineEntries,
    )..where((t) => t.saleId.isIn(sales))).go();
    await (db.delete(db.saleEntries)..where((t) => t.id.isIn(sales))).go();
    // Rows of the user that point at seeded rows lose the link, not the row.
    await (db.update(db.saleLineEntries)
          ..where((t) => t.productId.isIn(products)))
        .write(const SaleLineEntriesCompanion(productId: Value(null)));
    await (db.update(db.saleEntries)..where((t) => t.storeId.isIn(stores)))
        .write(const SaleEntriesCompanion(storeId: Value(null)));
    await (db.update(db.saleEntries)..where((t) => t.counterId.isIn(counters)))
        .write(const SaleEntriesCompanion(counterId: Value(null)));
    await (db.update(db.saleEntries)..where((t) => t.userId.isIn(users))).write(
      const SaleEntriesCompanion(userId: Value(null)),
    );
    await (db.update(db.saleEntries)
          ..where((t) => t.customerId.isIn(customers)))
        .write(const SaleEntriesCompanion(customerId: Value(null)));
    await (db.update(db.heldBillEntries)..where((t) => t.storeId.isIn(stores)))
        .write(const HeldBillEntriesCompanion(storeId: Value(null)));
    // Stock rows of seeded products go with them.
    await (db.delete(
      db.inventoryTransactionEntries,
    )..where((t) => t.productId.isIn(products))).go();
    await (db.delete(
      db.inventoryBalanceEntries,
    )..where((t) => t.productId.isIn(products))).go();
    // Packagings and barcodes of seeded products (children first). Sale
    // lines of the user lose the packaging link, not the row.
    final seededPackagings = db.selectOnly(db.packagingEntries)
      ..addColumns([db.packagingEntries.id])
      ..where(db.packagingEntries.productId.isIn(products));
    await (db.update(db.saleLineEntries)
          ..where((t) => t.packagingId.isInQuery(seededPackagings)))
        .write(const SaleLineEntriesCompanion(packagingId: Value(null)));
    await (db.delete(
      db.barcodeEntries,
    )..where((t) => t.productId.isIn(products))).go();
    await (db.delete(
      db.packagingEntries,
    )..where((t) => t.productId.isIn(products))).go();
    // Offers of the user that use a seeded product go with it.
    await (db.delete(db.offerEntries)..where(
          (t) =>
              t.id.isIn(offers) |
              t.productId.isIn(products) |
              t.giftProductId.isIn(products),
        ))
        .go();
    await (db.delete(
      db.productEntries,
    )..where((t) => t.id.isIn(products))).go();
    await (db.delete(
      db.categoryEntries,
    )..where((t) => t.id.isIn(categories))).go();
    await (db.delete(
      db.userAccessEntries,
    )..where((t) => t.id.isIn(access))).go();
    await (db.delete(db.userEntries)..where((t) => t.id.isIn(users))).go();
    await (db.delete(
      db.counterEntries,
    )..where((t) => t.id.isIn(counters))).go();
    // Forex rows belong to their store; the regime rows and slabs are ours.
    await (db.delete(
      db.storeForexEntries,
    )..where((t) => t.storeId.isIn(stores))).go();
    await (db.update(db.paymentEntries)..where(
          (t) => t.methodId.isInQuery(
            db.selectOnly(db.paymentMethodEntries)
              ..addColumns([db.paymentMethodEntries.id])
              ..where(db.paymentMethodEntries.storeId.isIn(stores)),
          ),
        ))
        .write(const PaymentEntriesCompanion(methodId: Value(null)));
    await (db.delete(
      db.paymentMethodEntries,
    )..where((t) => t.storeId.isIn(stores))).go();
    await (db.delete(db.storeEntries)..where((t) => t.id.isIn(stores))).go();
    await (db.delete(
      db.taxSlabEntries,
    )..where((t) => t.regimeId.isIn(regimes))).go();
    await (db.delete(
      db.taxRegimeEntries,
    )..where((t) => t.id.isIn(regimes))).go();
    await (db.delete(db.currencyEntries)..where(
          (t) =>
              t.code.isIn(currencies) &
              t.code.isNotInQuery(
                db.selectOnly(db.storeEntries)
                  ..addColumns([db.storeEntries.currencyCode]),
              ) &
              t.code.isNotInQuery(
                db.selectOnly(db.storeForexEntries)
                  ..addColumns([db.storeForexEntries.foreignCurrencyCode]),
              ),
        ))
        .go();
    await (db.delete(
      db.customerEntries,
    )..where((t) => t.id.isIn(customers))).go();
    await (db.delete(db.migrationStateEntries)..where(
          (t) =>
              t.key.isIn(markers) |
              t.key.equals(marker) |
              t.key.equals(legacyMarker),
        ))
        .go();
    await db.delete(db.seedManifestEntries).go();
  }
}

/// The parsed seed assets.
class _SeedData {
  _SeedData({
    required this.currencies,
    required this.regimes,
    required this.forex,
    required this.stores,
    required this.users,
    required this.categories,
    required this.products,
    required this.customers,
    required this.offerRows,
    required this.sales,
    this.packagings = const <Map<String, dynamic>>[],
    this.extraBarcodes = const <Map<String, dynamic>>[],
  });

  static Future<_SeedData> load(SeedAssetLoader load) async {
    Future<List<Map<String, dynamic>>> list(String name) async =>
        (jsonDecode(await load('$name.json')) as List)
            .cast<Map<String, dynamic>>();
    // Packagings and extra barcodes (DEC-151); a loader without the file
    // seeds none.
    var packagings = const <Map<String, dynamic>>[];
    var barcodes = const <Map<String, dynamic>>[];
    try {
      final extra =
          jsonDecode(await load('packagings.json')) as Map<String, dynamic>;
      packagings = (extra['packagings'] as List).cast<Map<String, dynamic>>();
      barcodes = (extra['barcodes'] as List).cast<Map<String, dynamic>>();
    } on Object {
      // No packaging seed in this asset set.
    }
    return _SeedData(
      packagings: packagings,
      extraBarcodes: barcodes,
      currencies: await list('currencies'),
      regimes: await list('tax_regimes'),
      forex: await list('store_forex'),
      stores: await list('stores'),
      users: await list('users'),
      categories: await list('categories'),
      products: await list('products'),
      customers: await list('customers'),
      offerRows: await list('offers'),
      sales: await list('sales'),
    );
  }

  final List<Map<String, dynamic>> currencies;
  final List<Map<String, dynamic>> regimes;
  final List<Map<String, dynamic>> forex;
  final List<Map<String, dynamic>> stores;
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> offerRows;
  final List<Map<String, dynamic>> sales;
  final List<Map<String, dynamic>> packagings;
  final List<Map<String, dynamic>> extraBarcodes;

  /// Currency-less tax setup of the seed regime of [region] (zero tax when
  /// the seed has none).
  TaxConfig taxConfig(String region) {
    final r = regimes.where((r) => r['region'] == region).firstOrNull;
    if (r == null) return TaxConfig.none;
    return TaxConfig(
      country: region,
      currency: TaxConfig.none.currency,
      label: r['label'] as String,
      mode: r['priceMode'] == 'inclusive'
          ? TaxMode.inclusive
          : TaxMode.exclusive,
      slabsBp: <Bp>[
        for (final sl in (r['slabs'] as List).cast<Map<String, dynamic>>())
          Bp(sl['rateBp'] as int),
      ],
      splitParts: (r['splitParts'] as List).cast<String>(),
    );
  }

  /// Product entities by seed id (price in the product's currency).
  Map<String, Product> productEntities() => <String, Product>{
    for (final p in products)
      p['id'] as String: Product(
        id: p['legacyId'] as int,
        name: p['name'] as String,
        code: p['code'] as String,
        barcode: p['barcode'] as String,
        price: Money(
          p['priceMinor'] as int,
          CurrencyRegistry.byCode(p['currencyCode'] as String),
        ),
        category: p['category'] as String,
        sub: p['sub'] as String,
        stock: p['stock'] as int,
        gst: Bp(p['gstBp'] as int),
        image: p['image'] as int,
        favourite: p['favourite'] as bool,
      ),
  };

  /// The offers as the engine sees them, for the seeded past sales.
  List<Offer> offers(Map<String, Product> byId) {
    final now = DateTime.now().toUtc();
    return <Offer>[
      for (final o in offerRows)
        Offer(
          id: o['id'] as String,
          kind: OfferKind.parse(o['kind'] as String),
          name: o['name'] as String,
          storeId: o['store'] as String?,
          productId: o['product'] == null ? null : byId[o['product']]!.id,
          percent: o['percentBp'] == null ? null : Bp(o['percentBp'] as int),
          fixedOff: o['fixedMinor'] == null
              ? null
              : Money(
                  o['fixedMinor'] as int,
                  CurrencyRegistry.byCode(o['currency'] as String),
                ),
          minCart: o['minCartMinor'] == null
              ? null
              : Money(
                  o['minCartMinor'] as int,
                  CurrencyRegistry.byCode(o['currency'] as String),
                ),
          gift: o['gift'] == null ? null : byId[o['gift']],
          startsAt: o['startsDaysAgo'] == null
              ? null
              : now.subtract(Duration(days: o['startsDaysAgo'] as int)),
          endsAt: o['endsInDays'] == null
              ? null
              : now.add(Duration(days: o['endsInDays'] as int)),
          priority: o['priority'] as int? ?? 0,
        ),
    ];
  }
}
