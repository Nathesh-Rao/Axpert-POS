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

/// The base-unit barcode of a product after a write (DEC-151). [storeId] is
/// only known for inserted products ([hasStore]); otherwise it is read.
class BarcodeChange {
  const BarcodeChange(
    this.id,
    this.barcode, {
    this.storeId,
    this.hasStore = false,
  });

  /// `products.id`.
  final String id;
  final String barcode;
  final String? storeId;
  final bool hasStore;
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
    this.barcodeChanges = const [],
  });

  final List<ProductEntriesCompanion> inserts;

  /// `(row uuid, companion)` pairs.
  final List<(String, ProductEntriesCompanion)> updates;
  final List<String> tombstones;

  /// The snapshot after this write succeeds.
  final Map<int, KnownProduct> next;

  /// `products.barcode` after the write, for the products whose
  /// base-unit barcode row in `product_barcodes` must follow the cache column
  /// (new, changed, reactivated; an empty barcode for a removed product).
  final List<BarcodeChange> barcodeChanges;

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
    final barcodeChanges = <BarcodeChange>[];
    final next = Map<int, KnownProduct>.of(known);
    final inList = <int>{};

    for (var i = 0; i < list.length; i++) {
      final p = list[i];
      inList.add(p.id);
      final row = known[p.id];
      if (row == null) {
        final id = uuid.generate();
        inserts.add(_insert(id, p, i, now, storeId));
        barcodeChanges.add(
          BarcodeChange(id, p.barcode, storeId: storeId, hasStore: true),
        );
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
      if (!row.active || row.product.barcode != p.barcode) {
        barcodeChanges.add(BarcodeChange(row.uuid, p.barcode));
      }
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
      barcodeChanges.add(BarcodeChange(row.uuid, ''));
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
      barcodeChanges: barcodeChanges,
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
    await _syncBaseBarcodes(db, plan.barcodeChanges, now);
  }

  /// Makes the live base-unit barcode row of each product equal its
  /// `products.barcode` cache (DEC-151), in batches: one read of the live
  /// rows that matter, then batched tombstones and inserts. A barcode another
  /// live row already uses in the same store scope is not written
  /// (duplicates stay in the cache column, A3); the first product wins.
  static Future<void> _syncBaseBarcodes(
    AxpertDatabase db,
    List<BarcodeChange> changes,
    int now,
  ) async {
    if (changes.isEmpty) return;
    if (changes.length > _syncChunk) {
      await _reconcileAllBarcodes(db, now);
      return;
    }
    final wanted = <String, BarcodeChange>{for (final c in changes) c.id: c};
    final ids = wanted.keys.toList();

    // The store of products the plan did not insert (edits, removals).
    final stores = <String, String?>{
      for (final c in changes)
        if (c.hasStore) c.id: c.storeId,
    };
    final unknown = [
      for (final id in ids)
        if (!stores.containsKey(id)) id,
    ];
    for (var i = 0; i < unknown.length; i += _syncChunk) {
      final part = unknown.skip(i).take(_syncChunk).toList();
      final marks = List.filled(part.length, '?').join(',');
      for (final r
          in await db
              .customSelect(
                'SELECT id, store_id FROM products WHERE id IN ($marks)',
                variables: [for (final id in part) Variable<String>(id)],
              )
              .get()) {
        stores[r.read<String>('id')] = r.read<String?>('store_id');
      }
    }

    // The live rows that matter: all of them for a big batch (one scan), the
    // rows of these products and of these barcodes for a small one.
    final codes = {
      for (final c in changes)
        if (c.barcode.isNotEmpty) c.barcode,
    }.toList();
    final List<QueryRow> rows;
    {
      final idMarks = List.filled(ids.length, '?').join(',');
      final codeMarks = List.filled(
        codes.isEmpty ? 1 : codes.length,
        '?',
      ).join(',');
      rows = await db
          .customSelect(
            'SELECT id, product_id, packaging_id, store_id, barcode FROM '
            'product_barcodes WHERE deleted_at IS NULL AND (product_id IN '
            '($idMarks) OR barcode IN ($codeMarks))',
            variables: [
              for (final id in ids) Variable<String>(id),
              for (final c in codes.isEmpty ? const [''] : codes)
                Variable<String>(c),
            ],
          )
          .get();
    }
    final live = <String, ({String row, String code})>{};
    final taken = <String>{};
    for (final r in rows) {
      final product = r.read<String>('product_id');
      final code = r.read<String>('barcode');
      final isBase = r.read<String?>('packaging_id') == null;
      if (isBase && wanted.containsKey(product)) {
        live[product] = (row: r.read<String>('id'), code: code);
      }
      taken.add('${r.read<String?>('store_id') ?? ''}\u0000$code');
    }
    final tombstones = <String>{};
    for (final id in ids) {
      final current = live[id];
      if (current != null && current.code != wanted[id]!.barcode) {
        tombstones.add(current.row);
        // Its scope frees up (the same row is not its own duplicate).
        taken.remove('${stores[id] ?? ''}\u0000${current.code}');
      }
    }
    final inserts = <(String, String, String?)>[];
    for (final id in ids) {
      final code = wanted[id]!.barcode;
      if (code.isEmpty || live[id]?.code == code) continue;
      final store = stores[id];
      if (!taken.add('${store ?? ''}\u0000$code')) continue;
      inserts.add((id, code, store));
    }
    if (tombstones.isNotEmpty) {
      await db.batch((b) {
        for (final row in tombstones) {
          b.update(
            db.barcodeEntries,
            BarcodeEntriesCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
            ),
            where: (t) => t.id.equals(row),
          );
        }
      });
    }
    // Multi-row VALUES with a SQL-side UUID: much cheaper than one Dart UUID
    // and one bound statement per row (10,000 products copy).
    const rowsPerStatement = 150;
    for (var i = 0; i < inserts.length; i += rowsPerStatement) {
      final part = inserts.skip(i).take(rowsPerStatement).toList();
      await db.customStatement(
        'INSERT INTO product_barcodes (id, product_id, packaging_id, '
        'store_id, barcode, created_at, updated_at) VALUES '
        '${List.filled(part.length, '(${AxpertDatabase.sqlUuid}, ?, NULL, ?, ?, ?, ?)').join(',')}',
        [
          for (final (id, code, store) in part) ...[id, store, code, now, now],
        ],
      );
    }
  }

  /// The big-batch form of the sync (a copy of thousands of products): two
  /// set-based statements instead of per-product work. The live base-unit
  /// barcode rows are made equal to the live products' `barcode`: stale ones
  /// are tombstoned, missing ones inserted (first product by position wins a
  /// shared barcode in its scope).
  static Future<void> _reconcileAllBarcodes(AxpertDatabase db, int now) async {
    await db.customStatement(
      'UPDATE product_barcodes SET deleted_at = ?, updated_at = ? '
      'WHERE packaging_id IS NULL AND deleted_at IS NULL AND NOT EXISTS ('
      'SELECT 1 FROM products p WHERE p.id = product_barcodes.product_id '
      'AND p.deleted_at IS NULL AND p.barcode = product_barcodes.barcode)',
      [now, now],
    );
    await db.customStatement(
      'INSERT INTO product_barcodes (id, product_id, packaging_id, store_id, '
      'barcode, created_at, updated_at) '
      'SELECT ${AxpertDatabase.sqlUuid}, id, NULL, store_id, barcode, ?, ? '
      'FROM (SELECT id, store_id, barcode, ROW_NUMBER() OVER (PARTITION BY '
      "COALESCE(store_id, ''), barcode ORDER BY position, id) AS rn "
      "FROM products WHERE deleted_at IS NULL AND barcode != '') t "
      'WHERE rn = 1 AND NOT EXISTS (SELECT 1 FROM product_barcodes b WHERE '
      'b.deleted_at IS NULL AND b.barcode = t.barcode AND '
      "COALESCE(b.store_id, '') = COALESCE(t.store_id, ''))",
      [now, now],
    );
  }

  static const int _syncChunk = 500;

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
