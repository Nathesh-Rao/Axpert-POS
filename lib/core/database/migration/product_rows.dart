import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/products/domain/entities/product.dart';
import '../../identifiers/uuid_generator.dart';
import '../../services/pricing/basis_points.dart';
import '../../services/pricing/currency_registry.dart';
import '../../services/pricing/money.dart';
import '../axpert_database.dart';
import 'fnv1a.dart';

/// What the repository remembers about one table row (the diff snapshot).
class KnownProduct {
  const KnownProduct({
    required this.uuid,
    required this.createdAt,
    required this.position,
    required this.product,
    required this.active,
  });

  final String uuid;
  final int createdAt;
  final int position;

  /// What the row holds (a tombstone keeps its last values).
  final Product product;
  final bool active;
}

/// Product ids that appear more than once (the copy stops, KG-191 / DEC-128).
class DuplicateProductIdsException implements Exception {
  const DuplicateProductIdsException(this.counts);

  /// id -> how many times it appears.
  final Map<int, int> counts;

  Map<String, Object?> toJson() => {
    'duplicate_ids': {for (final e in counts.entries) '${e.key}': e.value},
  };

  @override
  String toString() =>
      'DuplicateProductIdsException(product ids used more than once: '
      '${counts.entries.map((e) => '${e.key} x${e.value}').join(', ')})';
}

/// What a save will write: computed in memory, applied in one transaction,
/// and only then committed to the repository's snapshot (a failed write
/// leaves the snapshot unchanged, so the next save re-sends the changes).
class ProductWrite {
  const ProductWrite({
    required this.inserts,
    required this.updates,
    required this.tombstones,
    required this.next,
  });

  final List<ProductEntriesCompanion> inserts;

  /// `(row uuid, companion)` pairs.
  final List<(String, ProductEntriesCompanion)> updates;
  final List<String> tombstones;

  /// The snapshot after this write succeeds.
  final Map<int, KnownProduct> next;

  int get rowCount => inserts.length + updates.length + tombstones.length;

  bool get isEmpty => rowCount == 0;
}

/// Product list <-> `products` table mapping shared by the one-way copy and
/// every save (DEC-128). Callers wrap [write] in `durableTransaction`.
abstract final class ProductRows {
  static const int _chunk = 1000;

  /// Ids used by more than one product (id -> count).
  static Map<int, int> duplicateIds(List<Product> list) {
    final counts = <int, int>{};
    for (final p in list) {
      counts[p.id] = (counts[p.id] ?? 0) + 1;
    }
    counts.removeWhere((_, n) => n < 2);
    return counts;
  }

  /// Codes (lowercase, as `byCode` indexes them) used by more than one
  /// product (code -> ids). Reported only.
  static Map<String, List<int>> duplicateCodes(List<Product> list) =>
      _duplicates(list, (p) => p.code.toLowerCase());

  /// Barcodes used by more than one product (barcode -> ids). Reported only.
  static Map<String, List<int>> duplicateBarcodes(List<Product> list) =>
      _duplicates(list, (p) => p.barcode);

  static Map<String, List<int>> _duplicates(
    List<Product> list,
    String Function(Product) key,
  ) {
    final byKey = <String, List<int>>{};
    for (final p in list) {
      byKey.putIfAbsent(key(p), () => <int>[]).add(p.id);
    }
    byKey.removeWhere((_, ids) => ids.length < 2);
    return byKey;
  }

  /// Plans the writes that make the table equal [list], given what the table
  /// holds ([known], by legacy id). Matches by legacy id, keeps UUID and
  /// `created_at` of known rows (a returning tombstone is reactivated),
  /// inserts new ids with a new UUID, tombstones active rows that left the
  /// list (never DELETE) and sets `position` to the list index. Rows that do
  /// not change are not written. Does not touch the database.
  static ProductWrite plan(
    List<Product> list,
    Map<int, KnownProduct> known, {
    required int now,
    required UuidGenerator uuid,
    String? storeId,
  }) {
    final dups = duplicateIds(list);
    if (dups.isNotEmpty) throw DuplicateProductIdsException(dups);

    final inserts = <ProductEntriesCompanion>[];
    final updates = <(String, ProductEntriesCompanion)>[];
    final tombstones = <String>[];
    final next = Map<int, KnownProduct>.of(known);
    final inList = <int>{};

    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      inList.add(p.id);
      final row = known[p.id];
      if (row == null) {
        final id = uuid.generate();
        inserts.add(_insert(id, p, i, now, storeId));
        next[p.id] = KnownProduct(
          uuid: id,
          createdAt: now,
          position: i,
          product: p,
          active: true,
        );
        continue;
      }
      if (row.active && row.position == i && row.product == p) continue;
      updates.add((row.uuid, _update(p, i, now)));
      next[p.id] = KnownProduct(
        uuid: row.uuid,
        createdAt: row.createdAt,
        position: i,
        product: p,
        active: true,
      );
    }
    for (final entry in known.entries) {
      final row = entry.value;
      if (!row.active || inList.contains(entry.key)) continue;
      tombstones.add(row.uuid);
      next[entry.key] = KnownProduct(
        uuid: row.uuid,
        createdAt: row.createdAt,
        position: row.position,
        product: row.product,
        active: false,
      );
    }
    return ProductWrite(
      inserts: inserts,
      updates: updates,
      tombstones: tombstones,
      next: next,
    );
  }

  /// Applies [plan] (batched, in chunks so each web worker message stays
  /// small). Must run inside the caller's transaction.
  static Future<void> write(
    AxpertDatabase db,
    ProductWrite plan, {
    required int now,
  }) async {
    for (var i = 0; i < plan.inserts.length; i += _chunk) {
      final part = plan.inserts.skip(i).take(_chunk).toList();
      await db.batch((b) => b.insertAll(db.productEntries, part));
    }
    for (var i = 0; i < plan.updates.length; i += _chunk) {
      final part = plan.updates.skip(i).take(_chunk).toList();
      await db.batch((b) {
        for (final (id, companion) in part) {
          b.update(db.productEntries, companion, where: (t) => t.id.equals(id));
        }
      });
    }
    if (plan.tombstones.isNotEmpty) {
      await db.batch((b) {
        for (final id in plan.tombstones) {
          b.update(
            db.productEntries,
            ProductEntriesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
            where: (t) => t.id.equals(id),
          );
        }
      });
    }
  }

  /// Every row (tombstones too) by legacy id, for the diff snapshot, plus the
  /// active products in list order.
  static Future<({Map<int, KnownProduct> known, List<Product> list})> read(
    AxpertDatabase db, {
    String? storeId,
  }) async {
    final query = db.select(db.productEntries);
    if (storeId != null) query.where((t) => t.storeId.equals(storeId));
    final rows = await (query..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .get();
    final known = <int, KnownProduct>{};
    final list = <Product>[];
    for (final r in rows) {
      final product = _product(r);
      final active = r.deletedAt == null;
      known[r.legacyId] = KnownProduct(
        uuid: r.id,
        createdAt: r.createdAt,
        position: r.position,
        product: product,
        active: active,
      );
      if (active) list.add(product);
    }
    return (known: known, list: list);
  }

  /// FNV-1a over the canonical JSON lines of [list], in order.
  static String checksum(List<Product> list) =>
      fnv1a32Hex(list.map((p) => jsonEncode(p.toJson())).join('\n'));

  /// A product row as the app's [Product] (also used to build the gift of an
  /// offer).
  static Product toProduct(ProductEntry r) => _product(r);

  static Product _product(ProductEntry r) => Product(
    id: r.legacyId,
    name: r.name,
    code: r.code,
    barcode: r.barcode,
    price: Money(r.priceMinor, CurrencyRegistry.byCode(r.currencyCode)),
    category: r.category,
    sub: r.sub,
    stock: r.stock,
    gst: Bp(r.gstBp),
    image: r.image,
    favourite: r.favourite,
  );

  static ProductEntriesCompanion _insert(
    String id,
    Product p,
    int position,
    int now,
    String? storeId,
  ) => ProductEntriesCompanion.insert(
    id: id,
    legacyId: p.id,
    position: position,
    name: p.name,
    code: p.code,
    barcode: p.barcode,
    priceMinor: p.price.minor,
    currencyCode: Value(p.price.currency.code),
    category: p.category,
    sub: p.sub,
    stock: p.stock,
    gstBp: p.gst.value,
    image: p.image,
    favourite: p.favourite,
    storeId: Value(storeId),
    createdAt: now,
    updatedAt: now,
  );

  static ProductEntriesCompanion _update(Product p, int position, int now) =>
      ProductEntriesCompanion(
        position: Value(position),
        name: Value(p.name),
        code: Value(p.code),
        barcode: Value(p.barcode),
        priceMinor: Value(p.price.minor),
        currencyCode: Value(p.price.currency.code),
        category: Value(p.category),
        sub: Value(p.sub),
        stock: Value(p.stock),
        gstBp: Value(p.gst.value),
        image: Value(p.image),
        favourite: Value(p.favourite),
        updatedAt: Value(now),
        deletedAt: const Value(null),
      );
}
