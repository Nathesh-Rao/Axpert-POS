import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/payment/domain/entities/payment_result.dart';
import '../../../features/products/domain/entities/product.dart';
import '../../../modules/pos/models/cart.dart';
import '../../../modules/pos/models/cart_line.dart';
import '../../../modules/sales/models/sale.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/packaging/packaging_ref.dart';
import '../../services/pricing/basis_points.dart';
import '../../services/pricing/currency_registry.dart';
import '../../services/pricing/money.dart';
import '../../services/pricing/pricing_models.dart';
import '../../services/pricing/qty.dart';
import '../../services/pricing/tax_split.dart';
import '../../session/store_scope.dart';
import '../../utils/epoch_time.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';
import '../../../modules/pos/models/line_key.dart';

/// What the repository remembers about one `sales` row (the diff snapshot).
class KnownSale {
  const KnownSale({
    required this.uuid,
    required this.hasSaleId,
    required this.createdAt,
    required this.position,
    required this.sale,
    required this.active,
  });

  final String uuid;
  final bool hasSaleId;
  final int createdAt;
  final int position;

  /// What the row holds (a tombstone keeps its last values).
  final Sale sale;
  final bool active;
}

/// Non-null `saleId`s used by more than one sale: the copy stops (DEC-129).
class DuplicateSaleIdsException implements Exception {
  const DuplicateSaleIdsException(this.counts);

  final Map<String, int> counts;

  @override
  String toString() => 'DuplicateSaleIdsException($counts)';
}

/// A sale's `returned` map names a line that is not a line of the sale: the
/// copy stops (DEC-129); the app can never produce this.
class OrphanReturnedException implements Exception {
  const OrphanReturnedException(this.number, this.lineKeys);

  final String number;
  final List<LineKey> lineKeys;

  @override
  String toString() => 'OrphanReturnedException($number, $lineKeys)';
}

/// A completed sale may change only `returned`; anything else is rejected
/// before any write (DEC-129).
class SaleImmutableException implements Exception {
  const SaleImmutableException(this.number);

  final String number;

  @override
  String toString() => 'SaleImmutableException($number)';
}

class PlannedSaleInsert {
  const PlannedSaleInsert({
    required this.id,
    required this.position,
    required this.sale,
  });

  final String id;
  final int position;
  final Sale sale;
}

class PlannedSaleUpdate {
  const PlannedSaleUpdate({
    required this.known,
    required this.position,
    required this.sale,
    required this.returnedChanged,
  });

  final KnownSale known;
  final int position;
  final Sale sale;
  final bool returnedChanged;
}

/// The writes that make the table equal a list; computed in memory.
class SaleWrite {
  const SaleWrite({
    required this.inserts,
    required this.updates,
    required this.tombstones,
    required this.next,
  });

  final List<PlannedSaleInsert> inserts;
  final List<PlannedSaleUpdate> updates;

  /// UUIDs of active rows that left the list.
  final List<String> tombstones;

  /// The snapshot after a successful commit.
  final Map<String, KnownSale> next;

  bool get isEmpty => inserts.isEmpty && updates.isEmpty && tombstones.isEmpty;

  int get rowCount {
    var lines = 0;
    for (final i in inserts) {
      lines += i.sale.cart.lines.length;
    }
    return inserts.length + lines + updates.length + tombstones.length;
  }
}

/// Sale list <-> `sales` / `sale_lines` table mapping shared by the one-way
/// copy, every save, the checkout and the refund (DEC-129). Callers run
/// [write] inside `durableTransaction`.
abstract final class SaleRows {
  static const int _chunk = 500;

  /// Numbers used by more than one sale (number -> count). Reported, never
  /// fixed (KG-008).
  static Map<String, int> duplicateNumbers(List<Sale> list) {
    final counts = <String, int>{};
    for (final s in list) {
      counts[s.number] = (counts[s.number] ?? 0) + 1;
    }
    counts.removeWhere((_, n) => n < 2);
    return counts;
  }

  static Map<String, int> duplicateSaleIds(List<Sale> list) {
    final counts = <String, int>{};
    for (final s in list) {
      final id = s.saleId;
      if (id != null) counts[id] = (counts[id] ?? 0) + 1;
    }
    counts.removeWhere((_, n) => n < 2);
    return counts;
  }

  /// Throws when the list cannot be stored (see the exceptions above).
  static void validate(List<Sale> list) {
    final dups = duplicateSaleIds(list);
    if (dups.isNotEmpty) throw DuplicateSaleIdsException(dups);
    for (final s in list) {
      final lineKeys = <LineKey>{for (final l in s.cart.lines) l.key};
      final orphans = <LineKey>[
        for (final key in s.returned.keys)
          if (!lineKeys.contains(key)) key,
      ];
      if (orphans.isNotEmpty) throw OrphanReturnedException(s.number, orphans);
    }
  }

  /// Identity keys of [list] in order: `id:<saleId>` for sales with an id,
  /// `n:<number>#<k>` (k-th legacy sale with that number) for the others.
  static List<String> keysOf(List<Sale> list) {
    final seen = <String, int>{};
    return <String>[
      for (final s in list)
        if (s.saleId != null)
          'id:${s.saleId}'
        else
          'n:${s.number}#${seen[s.number] = (seen[s.number] ?? -1) + 1}',
    ];
  }

  /// Plans the writes that make the table equal [list], given what the table
  /// holds ([known]). Does not touch the database.
  static SaleWrite plan(
    List<Sale> list,
    Map<String, KnownSale> known, {
    required int now,
    required UuidGenerator uuid,
  }) {
    validate(list);
    final keys = keysOf(list);
    final inserts = <PlannedSaleInsert>[];
    final updates = <PlannedSaleUpdate>[];
    final next = Map<String, KnownSale>.of(known);
    final inList = <String>{};
    for (var i = 0; i < list.length; i++) {
      final sale = list[i];
      final key = keys[i];
      inList.add(key);
      final row = known[key];
      if (row == null) {
        final id = sale.saleId ?? uuid.generate();
        inserts.add(PlannedSaleInsert(id: id, position: i, sale: sale));
        next[key] = KnownSale(
          uuid: id,
          hasSaleId: sale.saleId != null,
          createdAt: now,
          position: i,
          sale: sale,
          active: true,
        );
        continue;
      }
      if (!identical(row.sale, sale)) {
        if (!_sameImmutable(row.sale, sale)) {
          throw SaleImmutableException(sale.number);
        }
      }
      final returnedChanged = !_sameReturned(row.sale.returned, sale.returned);
      if (row.active && row.position == i && !returnedChanged) {
        if (!identical(row.sale, sale)) {
          next[key] = KnownSale(
            uuid: row.uuid,
            hasSaleId: row.hasSaleId,
            createdAt: row.createdAt,
            position: i,
            sale: sale,
            active: true,
          );
        }
        continue;
      }
      updates.add(
        PlannedSaleUpdate(
          known: row,
          position: i,
          sale: sale,
          returnedChanged: returnedChanged,
        ),
      );
      next[key] = KnownSale(
        uuid: row.uuid,
        hasSaleId: row.hasSaleId,
        createdAt: row.createdAt,
        position: i,
        sale: sale,
        active: true,
      );
    }
    final tombstones = <String>[];
    for (final entry in known.entries) {
      final row = entry.value;
      if (!row.active || inList.contains(entry.key)) continue;
      tombstones.add(row.uuid);
      next[entry.key] = KnownSale(
        uuid: row.uuid,
        hasSaleId: row.hasSaleId,
        createdAt: row.createdAt,
        position: row.position,
        sale: row.sale,
        active: false,
      );
    }
    return SaleWrite(
      inserts: inserts,
      updates: updates,
      tombstones: tombstones,
      next: next,
    );
  }

  /// Applies [plan]. Must run inside the caller's transaction.
  static Future<void> write(
    AxpertDatabase db,
    SaleWrite plan, {
    required int now,
    required UuidGenerator uuid,
    StoreScope? scope,
  }) async {
    if (plan.inserts.isNotEmpty) {
      final links = await _links(db, [for (final i in plan.inserts) i.sale]);
      for (var i = 0; i < plan.inserts.length; i += _chunk) {
        final part = plan.inserts.skip(i).take(_chunk).toList();
        await db.batch((b) {
          b.insertAll(db.saleEntries, [
            for (final p in part) _saleRow(p, now, links, scope),
          ]);
        });
        await db.batch((b) {
          for (final p in part) {
            b.insertAll(db.saleLineEntries, [
              for (var n = 0; n < p.sale.cart.lines.length; n++)
                _lineRow(p, n, now, links, uuid),
            ]);
          }
        });
      }
    }
    for (final u in plan.updates) {
      await (db.update(
        db.saleEntries,
      )..where((t) => t.id.equals(u.known.uuid))).write(
        SaleEntriesCompanion(
          position: Value(u.position),
          returnedOrder: Value(_orderJson(u.sale)),
          updatedAt: Value(now),
          deletedAt: const Value(null),
        ),
      );
      if (u.returnedChanged) await _writeReturned(db, u.known.uuid, u.sale);
    }
    if (plan.tombstones.isNotEmpty) {
      await db.batch((b) {
        for (final id in plan.tombstones) {
          b.update(
            db.saleEntries,
            SaleEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
            where: (t) => t.id.equals(id),
          );
        }
      });
    }
  }

  /// Stores a succeeded payment of [saleId] (cash or card, DEC-123).
  static Future<void> insertPayment(
    AxpertDatabase db,
    PaymentResult payment, {
    required int occurredAt,
    required int now,
    String? methodId,
  }) => db
      .into(db.paymentEntries)
      .insert(
        PaymentEntriesCompanion.insert(
          id: payment.paymentId,
          saleId: payment.saleId,
          method: payment.method.name,
          methodId: Value(methodId),
          amountMinor: payment.amount.minor,
          currencyCode: Value(payment.amount.currency.code),
          status: payment.status.name,
          occurredAt: occurredAt,
          createdAt: now,
        ),
      );

  /// Fills the customer and product links that are still null and can be
  /// resolved now (idempotent; never overwrites a link). Run after the sales
  /// load because customers and products load in parallel with sales.
  static Future<void> resolveLinks(AxpertDatabase db) async {
    await db.customStatement(
      'UPDATE sales SET customer_id = ('
      'SELECT c.id FROM customers c WHERE c.legacy_id = sales.customer_legacy_id) '
      'WHERE customer_id IS NULL AND EXISTS ('
      'SELECT 1 FROM customers c WHERE c.legacy_id = sales.customer_legacy_id)',
    );
    await db.customStatement(
      'UPDATE sale_lines SET product_id = ('
      'SELECT p.id FROM products p WHERE p.legacy_id = sale_lines.product_legacy_id) '
      'WHERE product_id IS NULL AND EXISTS ('
      'SELECT 1 FROM products p WHERE p.legacy_id = sale_lines.product_legacy_id)',
    );
  }

  /// Every row (tombstones too) by identity key, plus the active sales in
  /// list order.
  static Future<({Map<String, KnownSale> known, List<Sale> list})> read(
    AxpertDatabase db, {
    String? storeId,
  }) async {
    final query = db.select(db.saleEntries);
    if (storeId != null) query.where((t) => t.storeId.equals(storeId));
    final rows = await (query..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    final ids = {for (final r in rows) r.id};
    final lineRows =
        await (db.select(db.saleLineEntries)..orderBy([
              (t) => OrderingTerm.asc(t.saleId),
              (t) => OrderingTerm.asc(t.lineNo),
            ]))
            .get()
            .then(
              (all) => storeId == null
                  ? all
                  : [
                      for (final l in all)
                        if (ids.contains(l.saleId)) l,
                    ],
            );
    final bySale = <String, List<SaleLineEntry>>{};
    for (final l in lineRows) {
      bySale.putIfAbsent(l.saleId, () => <SaleLineEntry>[]).add(l);
    }
    final known = <String, KnownSale>{};
    final list = <Sale>[];
    final seen = <String, int>{};
    for (final r in rows) {
      final sale = _sale(r, bySale[r.id] ?? const <SaleLineEntry>[]);
      final active = r.deletedAt == null;
      final String key;
      if (r.hasSaleId) {
        key = 'id:${r.id}';
      } else if (active) {
        key = 'n:${r.number}#${seen[r.number] = (seen[r.number] ?? -1) + 1}';
      } else {
        key = 'x:${r.id}';
      }
      known[key] = KnownSale(
        uuid: r.id,
        hasSaleId: r.hasSaleId,
        createdAt: r.createdAt,
        position: r.position,
        sale: sale,
        active: active,
      );
      if (active) list.add(sale);
    }
    return (known: known, list: list);
  }

  /// FNV-1a over the canonical JSON lines of [list], in order.
  static String checksum(List<Sale> list) =>
      fnv1a32Hex(list.map((s) => jsonEncode(s.toJson())).join('\n'));

  // ---- helpers ----

  static bool _sameReturned(Map<LineKey, Qty> a, Map<LineKey, Qty> b) {
    if (a.length != b.length) return false;
    final ai = a.entries.iterator;
    final bi = b.entries.iterator;
    while (ai.moveNext() && bi.moveNext()) {
      if (ai.current.key != bi.current.key ||
          ai.current.value != bi.current.value) {
        return false;
      }
    }
    return true;
  }

  /// Everything except `returned`.
  static bool _sameImmutable(Sale a, Sale b) {
    if (a.number != b.number ||
        a.saleId != b.saleId ||
        a.date != b.date ||
        a.store != b.store ||
        a.customer != b.customer ||
        a.mode != b.mode ||
        a.tendered != b.tendered ||
        a.change != b.change) {
      return false;
    }
    if (jsonEncode(a.totals.toJson()) != jsonEncode(b.totals.toJson())) {
      return false;
    }
    return identical(a.cart, b.cart) ||
        jsonEncode(a.cart.toJson()) == jsonEncode(b.cart.toJson());
  }

  /// Base-unit lines are stored as the plain product id (what the prototype
  /// wrote), packaged lines as `"id|packaging"` (DEC-154).
  static String? _taxPartsJson(Sale sale) => sale.taxParts.isEmpty
      ? null
      : jsonEncode(<Map<String, Object>>[
          for (final p in sale.taxParts)
            <String, Object>{'label': p.label, 'minor': p.amount.minor},
        ]);

  static List<TaxPart> _taxParts(String? json, Money Function(int) m) =>
      json == null
      ? const <TaxPart>[]
      : <TaxPart>[
          for (final p in jsonDecode(json) as List<dynamic>)
            TaxPart(
              (p as Map<String, dynamic>)['label'] as String,
              m(p['minor'] as int),
            ),
        ];

  static String _orderJson(Sale sale) => jsonEncode(<Object>[
    for (final key in sale.returned.keys) key.isBase ? key.productId : key.text,
  ]);

  /// The quantity of a returned line sits on the FIRST line with that key.
  static Map<LineKey, int> _firstLineNo(Sale sale) {
    final first = <LineKey, int>{};
    for (var n = 0; n < sale.cart.lines.length; n++) {
      first.putIfAbsent(sale.cart.lines[n].key, () => n);
    }
    return first;
  }

  static Future<void> _writeReturned(
    AxpertDatabase db,
    String saleUuid,
    Sale sale,
  ) async {
    await (db.update(db.saleLineEntries)
          ..where((t) => t.saleId.equals(saleUuid)))
        .write(const SaleLineEntriesCompanion(returnedQtyMilli: Value(0)));
    final first = _firstLineNo(sale);
    for (final e in sale.returned.entries) {
      final lineNo = first[e.key];
      if (lineNo == null) continue;
      await (db.update(db.saleLineEntries)
            ..where((t) => t.saleId.equals(saleUuid) & t.lineNo.equals(lineNo)))
          .write(
            SaleLineEntriesCompanion(returnedQtyMilli: Value(e.value.milli)),
          );
    }
  }

  static Future<({Map<String, String> customers, Map<int, String> products})>
  _links(AxpertDatabase db, List<Sale> sales) async {
    final customerIds = <String>{for (final s in sales) s.cart.customer};
    final productIds = <int>{
      for (final s in sales)
        for (final l in s.cart.lines) l.product.id,
    };
    final customers = <String, String>{};
    for (final part in _parts(customerIds.toList())) {
      final rows = await (db.select(
        db.customerEntries,
      )..where((t) => t.legacyId.isIn(part))).get();
      for (final r in rows) {
        customers[r.legacyId] = r.id;
      }
    }
    final products = <int, String>{};
    for (final part in _parts(productIds.toList())) {
      final rows = await (db.select(
        db.productEntries,
      )..where((t) => t.legacyId.isIn(part))).get();
      for (final r in rows) {
        products[r.legacyId] = r.id;
      }
    }
    return (customers: customers, products: products);
  }

  static Iterable<List<T>> _parts<T>(List<T> all) sync* {
    for (var i = 0; i < all.length; i += 500) {
      yield all.skip(i).take(500).toList();
    }
  }

  static SaleEntriesCompanion _saleRow(
    PlannedSaleInsert p,
    int now,
    ({Map<String, String> customers, Map<int, String> products}) links,
    StoreScope? scope,
  ) {
    final s = p.sale;
    final c = s.cart;
    final flat = c.billDiscount.type == BillDiscountType.flat;
    return SaleEntriesCompanion.insert(
      id: p.id,
      hasSaleId: s.saleId != null,
      number: s.number,
      position: p.position,
      occurredAt: EpochTime.parseOrZero(s.date),
      storeName: s.store,
      storeId: Value(scope?.storeId),
      counterId: Value(scope?.counterId),
      userId: Value(scope?.userId),
      userName: Value(s.cashier ?? scope?.userName),
      customerName: s.customer,
      customerLegacyId: c.customer,
      customerId: Value(links.customers[c.customer]),
      currencyCode: Value(s.totals.total.currency.code),
      mode: s.mode,
      saleType: c.saleType.json,
      billDiscountType: flat ? 'flat' : 'percent',
      billDiscountBp: c.billDiscount.percent.value,
      billDiscountMinor: c.billDiscount.flat?.minor ?? 0,
      discountReason: c.reason,
      pointsRedeemed: c.points,
      note: c.note,
      items: s.totals.items,
      qtyMilli: s.totals.qty.milli,
      valueMinor: s.totals.value.minor,
      subtotalMinor: s.totals.subtotal.minor,
      discountMinor: s.totals.discount.minor,
      taxMinor: s.totals.tax.minor,
      taxPartsJson: Value(_taxPartsJson(s)),
      pointsMinor: s.totals.points.minor,
      totalMinor: s.totals.total.minor,
      tenderedMinor: s.tendered.minor,
      changeMinor: s.change.minor,
      returnedOrder: Value(_orderJson(s)),
      createdAt: now,
      updatedAt: now,
    );
  }

  static SaleLineEntriesCompanion _lineRow(
    PlannedSaleInsert p,
    int n,
    int now,
    ({Map<String, String> customers, Map<int, String> products}) links,
    UuidGenerator uuid,
  ) {
    final line = p.sale.cart.lines[n];
    final product = line.product;
    final first = _firstLineNo(p.sale);
    final returned = first[line.key] == n
        ? (p.sale.returned[line.key]?.milli ?? 0)
        : 0;
    return SaleLineEntriesCompanion.insert(
      id: uuid.generate(),
      saleId: p.id,
      lineNo: n,
      productId: Value(links.products[product.id]),
      productLegacyId: product.id,
      productName: product.name,
      productCode: product.code,
      productBarcode: product.barcode,
      productPriceMinor: product.price.minor,
      productCategory: product.category,
      productSub: product.sub,
      productStock: product.stock,
      productGstBp: product.gst.value,
      productImage: product.image,
      productFavourite: product.favourite,
      priceMinor: line.price.minor,
      qtyMilli: line.qty.milli,
      discountBp: line.discount.value,
      offerKind: Value(line.offer?.kind),
      offerName: Value(line.offer?.name),
      offerSavingMinor: Value(line.offer?.savingMinor),
      offerUnitOffMinor: Value(line.offer?.unitOffMinor),
      isGift: Value(line.offer?.isGift ?? false),
      packagingId: Value(line.packaging?.id),
      unitName: Value(line.packaging?.unitName),
      quantityBaseMilli: Value(line.packaging?.quantityBaseMilli),
      baseQtyMilli: Value(line.packaging == null ? null : line.baseQty.milli),
      returnedQtyMilli: Value(returned),
      createdAt: now,
    );
  }

  static Sale _sale(SaleEntry r, List<SaleLineEntry> lines) {
    final currency = CurrencyRegistry.byCode(r.currencyCode);
    Money m(int minor) => Money(minor, currency);
    final cartLines = <CartLine>[
      for (final l in lines)
        CartLine(
          product: Product(
            id: l.productLegacyId,
            name: l.productName,
            code: l.productCode,
            barcode: l.productBarcode,
            price: m(l.productPriceMinor),
            category: l.productCategory,
            sub: l.productSub,
            stock: l.productStock,
            gst: Bp(l.productGstBp),
            image: l.productImage,
            favourite: l.productFavourite,
          ),
          qty: Qty(l.qtyMilli),
          price: m(l.priceMinor),
          discount: Bp(l.discountBp),
          packaging:
              l.packagingId == null ||
                  l.unitName == null ||
                  l.quantityBaseMilli == null
              ? null
              : PackagingRef(
                  id: l.packagingId!,
                  unitName: l.unitName!,
                  quantityBaseMilli: l.quantityBaseMilli!,
                ),
          offer: l.offerKind == null
              ? null
              : LineOffer(
                  kind: l.offerKind!,
                  name: l.offerName ?? '',
                  savingMinor: l.offerSavingMinor ?? 0,
                  discountBp: !l.isGift && l.offerUnitOffMinor == null
                      ? l.discountBp
                      : 0,
                  unitOffMinor: l.offerUnitOffMinor,
                  isGift: l.isGift,
                ),
        ),
    ];
    final firstQty = <LineKey, Qty>{};
    for (final l in lines) {
      firstQty.putIfAbsent(
        LineKey(l.productLegacyId, l.packagingId),
        () => Qty(l.returnedQtyMilli),
      );
    }
    final order = <LineKey>[
      for (final e in jsonDecode(r.returnedOrder) as List<dynamic>)
        e is int ? LineKey(e) : LineKey.parse(e as String),
    ];
    return Sale(
      number: r.number,
      saleId: r.hasSaleId ? r.id : null,
      cashier: r.userName,
      date: EpochTime.toIso(r.occurredAt),
      store: r.storeName,
      customer: r.customerName,
      cart: Cart(
        lines: cartLines,
        customer: r.customerLegacyId,
        saleType: SaleType.fromJson(r.saleType),
        billDiscount: r.billDiscountType == 'flat'
            ? BillDiscount.flat(m(r.billDiscountMinor))
            : BillDiscount.percent(Bp(r.billDiscountBp)),
        reason: r.discountReason,
        points: r.pointsRedeemed,
        note: r.note,
      ),
      totals: SaleTotals(
        items: r.items,
        qty: Qty(r.qtyMilli),
        value: m(r.valueMinor),
        subtotal: m(r.subtotalMinor),
        discount: m(r.discountMinor),
        tax: m(r.taxMinor),
        points: m(r.pointsMinor),
        total: m(r.totalMinor),
      ),
      mode: r.mode,
      tendered: m(r.tenderedMinor),
      change: m(r.changeMinor),
      returned: <LineKey, Qty>{
        for (final key in order) key: firstQty[key] ?? Qty.zero,
      },
      taxParts: _taxParts(r.taxPartsJson, m),
    );
  }
}
