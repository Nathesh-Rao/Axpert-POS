import 'package:drift/drift.dart';
import 'package:sqlite3/common.dart' show SqliteException;

import '../../../../core/database/axpert_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/database/migration/product_rows.dart';
import '../../../../core/identifiers/uuid_generator.dart';
import '../../../../core/services/inventory/inventory_service.dart';
import '../../../../core/services/pricing/currency_registry.dart';
import '../../../../core/session/store_scope.dart';
import '../../../../core/utils/serial_queue.dart';
import '../../../inventory/data/drift_inventory_repository.dart';
import '../../../offers/domain/entities/offer.dart';
import '../../../offers/domain/entities/offer_draft.dart';
import '../../../offers/domain/services/offer_draft_rules.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../../domain/repositories/product_admin_repository.dart';
import '../../domain/services/product_draft_validator.dart';
import 'drift_packaging_repositories.dart';

int _systemNow() => DateTime.now().millisecondsSinceEpoch;

int _floorUnits(int milli) => (milli / 1000).floor();

/// Product management in Drift (DEC-152). Runs on the shared write queue so a
/// save cannot interleave with a sale, a refund or a favourite toggle, and
/// inside one `durableTransaction` per call.
class DriftProductAdminRepository implements ProductAdminRepository {
  DriftProductAdminRepository({
    required DatabaseProvider provider,
    required UuidGenerator uuid,
    required StoreScope scope,
    required DriftInventoryRepository inventory,
    SerialQueue? queue,
    int Function()? now,
    this.validator = const ProductDraftValidator(),
  }) : _provider = provider,
       _uuid = uuid,
       _scope = scope,
       _inventory = inventory,
       _queue = queue ?? SerialQueue(),
       _now = now ?? _systemNow;

  final DatabaseProvider _provider;
  final UuidGenerator _uuid;
  final StoreScope _scope;
  final DriftInventoryRepository _inventory;
  final SerialQueue _queue;
  final int Function() _now;
  final ProductDraftValidator validator;

  @override
  Future<String> create(ProductDraft draft) => _queue.run(() async {
    _check(draft);
    final db = await _provider.open();
    final id = _uuid.generate();
    final now = _now();
    await db.durableTransaction(() async {
      final top = await db
          .customSelect(
            'SELECT COALESCE(MAX(legacy_id), 0) AS l, '
            'COALESCE(MAX(position), -1) AS p FROM products',
          )
          .getSingle();
      final legacyId = top.read<int>('l') + 1;
      final storeId = _scope.storeId;
      await db
          .into(db.productEntries)
          .insert(
            ProductEntriesCompanion.insert(
              id: id,
              legacyId: legacyId,
              position: top.read<int>('p') + 1,
              name: draft.name.trim(),
              code: draft.code.trim(),
              barcode: _firstBarcode(draft),
              priceMinor: draft.priceMinor,
              currencyCode: Value(_currency(draft)),
              category: draft.category,
              sub: draft.sub,
              stock: _floorUnits(draft.openingMilli),
              gstBp: draft.gstBp,
              image: -1,
              favourite: false,
              storeId: Value(storeId),
              categoryId: Value(draft.categoryId),
              baseUnitId: Value(draft.baseUnitId),
              brandId: Value(draft.brandId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _writeChildren(db, id, storeId, draft, now);
      await _writeOffers(db, id, storeId, draft, now);
      if (storeId != null) {
        if (draft.openingMilli > 0) {
          await db
              .into(db.inventoryTransactionEntries)
              .insert(
                InventoryTransactionEntriesCompanion.insert(
                  id: _uuid.generate(),
                  storeId: storeId,
                  productId: id,
                  quantityDeltaMilli: draft.openingMilli,
                  reason: StockReason.opening.code,
                  userId: Value(_scope.userId),
                  createdAt: now,
                  note: const Value('opening stock'),
                ),
              );
        }
        await db
            .into(db.inventoryBalanceEntries)
            .insertOnConflictUpdate(
              InventoryBalanceEntriesCompanion.insert(
                storeId: storeId,
                productId: id,
                quantityMilli: draft.openingMilli,
                updatedAt: now,
              ),
            );
      }
    });
    return id;
  });

  @override
  Future<void> update(String uuid, ProductDraft draft) => _queue.run(() async {
    _check(draft);
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      final row = await _live(db, uuid);
      await (db.update(
        db.productEntries,
      )..where((t) => t.id.equals(uuid))).write(
        ProductEntriesCompanion(
          name: Value(draft.name.trim()),
          code: Value(draft.code.trim()),
          barcode: Value(_firstBarcode(draft)),
          priceMinor: Value(draft.priceMinor),
          currencyCode: Value(_currency(draft, row.currencyCode)),
          category: Value(draft.category),
          sub: Value(draft.sub),
          gstBp: Value(draft.gstBp),
          categoryId: Value(draft.categoryId),
          baseUnitId: Value(draft.baseUnitId),
          brandId: Value(draft.brandId),
          updatedAt: Value(now),
        ),
      );
      await _writeChildren(db, uuid, row.storeId, draft, now);
      await _writeOffers(db, uuid, row.storeId, draft, now);
    });
  });

  @override
  Future<void> deactivate(String uuid) => _queue.run(() async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      await _live(db, uuid);
      await (db.update(
        db.productEntries,
      )..where((t) => t.id.equals(uuid))).write(
        ProductEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
      // The barcodes go with it (same stamp) so the codes can be reused;
      // reactivate brings back exactly these rows.
      await (db.update(
        db.barcodeEntries,
      )..where((t) => t.productId.equals(uuid) & t.deletedAt.isNull())).write(
        BarcodeEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    });
  });

  @override
  Future<void> reactivate(String uuid) => _queue.run(() async {
    final db = await _provider.open();
    final now = _now();
    await db.durableTransaction(() async {
      final row = await (db.select(
        db.productEntries,
      )..where((t) => t.id.equals(uuid))).getSingle();
      final stamp = row.deletedAt;
      if (stamp == null) return;
      final codes =
          await (db.select(db.barcodeEntries)..where(
                (t) => t.productId.equals(uuid) & t.deletedAt.equals(stamp),
              ))
              .get();
      for (final code in codes) {
        await _ensureFree(db, code.barcode, row.storeId, code.id);
      }
      await (db.update(
        db.productEntries,
      )..where((t) => t.id.equals(uuid))).write(
        ProductEntriesCompanion(
          deletedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );
      try {
        await (db.update(db.barcodeEntries)..where(
              (t) => t.productId.equals(uuid) & t.deletedAt.equals(stamp),
            ))
            .write(
              BarcodeEntriesCompanion(
                deletedAt: const Value(null),
                updatedAt: Value(now),
              ),
            );
      } on SqliteException {
        throw DuplicateBarcodeException(
          codes.isEmpty ? '' : codes.first.barcode,
        );
      }
    });
  });

  @override
  Future<void> adjustStock({
    required String uuid,
    required int deltaMilli,
    required AdjustmentReason reason,
    required String note,
    String? userId,
  }) => _queue.run(() async {
    final db = await _provider.open();
    final storeId = _scope.storeId;
    if (storeId == null) throw StateError('No store: stock needs a store');
    final now = _now();
    await db.durableTransaction(() async {
      final row = await _live(db, uuid);
      final plan = await _inventory.applyWithin(
        db,
        storeId: storeId,
        userId: userId ?? _scope.userId,
        now: now,
        movements: [
          StockMovement(
            productId: uuid,
            deltaMilli: deltaMilli,
            reason: switch (reason) {
              AdjustmentReason.damage => StockReason.damage,
              AdjustmentReason.received => StockReason.purchase,
              _ => StockReason.adjustment,
            },
            refType: 'stock_adjustment',
            note: note,
          ),
        ],
        stockUnits: {uuid: row.stock},
      );
      if (plan.isBlocked) {
        throw AdjustmentBlockedException(plan.blocked.first.availableMilli);
      }
      await (db.update(
        db.productEntries,
      )..where((t) => t.id.equals(uuid))).write(
        ProductEntriesCompanion(
          stock: Value(_floorUnits(plan.balances[uuid]!)),
          updatedAt: Value(now),
        ),
      );
    });
  });

  // ---- reads ----

  @override
  Future<ProductDetail?> detail(int legacyId) async {
    final db = await _provider.open();
    final row = await (db.select(
      db.productEntries,
    )..where((t) => t.legacyId.equals(legacyId))).getSingleOrNull();
    if (row == null) return null;
    final packagings = await DriftPackagingRepository.forProductWithin(
      db,
      row.id,
    );
    final all =
        await (db.select(db.barcodeEntries)
              ..where((t) => t.productId.equals(row.id) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    final codes = [
      for (final c in all)
        if (c.packagingId == null) c,
    ];
    final storeId = _scope.storeId;
    final balance = storeId == null
        ? null
        : await (db.select(db.inventoryBalanceEntries)..where(
                (t) => t.storeId.equals(storeId) & t.productId.equals(row.id),
              ))
              .getSingleOrNull();
    return ProductDetail(
      uuid: row.id,
      product: ProductRows.toProduct(row),
      baseUnitId: row.baseUnitId ?? await _pieceId(db),
      brandId: row.brandId,
      categoryId: row.categoryId,
      barcodes: [for (final c in codes) c.barcode],
      packagings: packagings,
      offers: await _offersOf(db, row.id),
      packagingBarcodes: {
        for (final c in all)
          if (c.packagingId != null) c.packagingId!: c.barcode,
      },
      balanceMilli: balance?.quantityMilli ?? row.stock * 1000,
      active: row.deletedAt == null,
    );
  }

  @override
  Future<List<CatalogRow>> catalog() async {
    final db = await _provider.open();
    final query = db.select(db.productEntries);
    final storeId = _scope.storeId;
    if (storeId != null) query.where((t) => t.storeId.equals(storeId));
    query.orderBy([(t) => OrderingTerm.asc(t.position)]);
    return [
      for (final r in await query.get())
        CatalogRow(
          product: ProductRows.toProduct(r),
          active: r.deletedAt == null,
        ),
    ];
  }

  @override
  Future<Map<int, StockView>> stockViews() async {
    final db = await _provider.open();
    final storeId = _scope.storeId;
    final products = db.select(db.productEntries)
      ..where((t) => t.deletedAt.isNull());
    if (storeId != null) products.where((t) => t.storeId.equals(storeId));
    final rows = await products.get();
    final balances = storeId == null
        ? const <String, int>{}
        : await _inventory.balances(storeId);
    final units = {
      for (final u in await db.select(db.unitEntries).get()) u.id: u.name,
    };
    final levels = <String, List<({String name, int quantityBaseMilli})>>{};
    final packagings =
        await (db.select(db.packagingEntries)
              ..where((t) => t.deletedAt.isNull() & t.enabled.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.quantityBaseMilli)]))
            .get();
    for (final p in packagings) {
      levels.putIfAbsent(p.productId, () => []).add((
        name: p.name,
        quantityBaseMilli: p.quantityBaseMilli,
      ));
    }
    return {
      for (final r in rows)
        r.legacyId: StockView(
          balanceMilli: balances[r.id] ?? r.stock * 1000,
          baseUnitName: units[r.baseUnitId] ?? 'Piece',
          levels: levels[r.id] ?? const [],
        ),
    };
  }

  @override
  Future<List<CategoryInfo>> categories() async {
    final db = await _provider.open();
    final storeId = _scope.storeId;
    final rows =
        await (db.select(db.categoryEntries)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    (storeId == null
                        ? const Constant(true)
                        : t.storeId.isNull() | t.storeId.equals(storeId)),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        CategoryInfo(id: r.id, name: r.name, parentId: r.parentId),
    ];
  }

  @override
  Future<CategoryInfo> createCategory(String name, {String? parentId}) =>
      _queue.run(() async {
        final db = await _provider.open();
        final now = _now();
        final id = _uuid.generate();
        await db.durableTransaction(() async {
          final next = await db
              .customSelect(
                'SELECT COALESCE(MAX(position), -1) + 1 AS p FROM categories',
              )
              .getSingle();
          await db
              .into(db.categoryEntries)
              .insert(
                CategoryEntriesCompanion.insert(
                  id: id,
                  storeId: Value(_scope.storeId),
                  name: name.trim(),
                  parentId: Value(parentId),
                  position: Value(next.read<int>('p')),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        });
        return CategoryInfo(id: id, name: name.trim(), parentId: parentId);
      });

  // ---- shared write steps ----

  void _check(ProductDraft draft) {
    final problems = validator.validate(draft);
    if (problems.isNotEmpty) throw InvalidProductException(problems);
    for (var i = 0; i < draft.offers.length; i++) {
      final issues = const OfferDraftRules().validate(draft.offers[i]);
      if (issues.isNotEmpty) throw InvalidOfferException(i, issues);
    }
  }

  String _firstBarcode(ProductDraft draft) =>
      draft.barcodes.firstWhere((b) => b.isNotEmpty, orElse: () => '');

  String _currency(ProductDraft draft, [String? current]) =>
      _scope.currency?.code ?? current ?? CurrencyRegistry.inr.code;

  Future<ProductEntry> _live(AxpertDatabase db, String uuid) async {
    final row = await (db.select(
      db.productEntries,
    )..where((t) => t.id.equals(uuid) & t.deletedAt.isNull())).getSingle();
    return row;
  }

  Future<String> _pieceId(AxpertDatabase db) async => (await (db.select(
    db.unitEntries,
  )..where((t) => t.code.equals('piece'))).getSingle()).id;

  /// Packagings and barcodes of [productId] to match [draft]: unchanged rows
  /// stay, removed ones get a tombstone, new ones are inserted.
  Future<void> _writeChildren(
    AxpertDatabase db,
    String productId,
    String? storeId,
    ProductDraft draft,
    int now,
  ) async {
    final existing = await DriftPackagingRepository.forProductWithin(
      db,
      productId,
    );
    final keep = {
      for (final p in draft.packagings)
        if (p.id != null) p.id!,
    };
    for (final old in existing) {
      if (keep.contains(old.id)) continue;
      await (db.update(
        db.packagingEntries,
      )..where((t) => t.id.equals(old.id))).write(
        PackagingEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    }
    final ids = <String?>[];
    for (var i = 0; i < draft.packagings.length; i++) {
      final p = draft.packagings[i];
      final id = p.id ?? _uuid.generate();
      ids.add(id);
      final sku = (p.sku == null || p.sku!.trim().isEmpty)
          ? null
          : p.sku!.trim();
      try {
        final updated = p.id == null
            ? 0
            : await (db.update(
                db.packagingEntries,
              )..where((t) => t.id.equals(id))).write(
                PackagingEntriesCompanion(
                  unitId: Value(p.unitId),
                  name: Value(p.name),
                  quantityBaseMilli: Value(p.quantityBaseMilli),
                  sku: Value(sku),
                  priceMinor: Value(p.priceMinor),
                  sortOrder: Value(i),
                  enabled: Value(p.enabled),
                  updatedAt: Value(now),
                  deletedAt: const Value(null),
                ),
              );
        if (updated == 0) {
          await db
              .into(db.packagingEntries)
              .insert(
                PackagingEntriesCompanion.insert(
                  id: id,
                  productId: productId,
                  unitId: p.unitId,
                  name: p.name,
                  quantityBaseMilli: p.quantityBaseMilli,
                  sku: Value(sku),
                  priceMinor: Value(p.priceMinor),
                  sortOrder: Value(i),
                  enabled: Value(p.enabled),
                  createdAt: now,
                  updatedAt: now,
                ),
              );
        }
      } on SqliteException {
        throw DuplicatePackagingException(productId, p.unitId);
      }
    }

    // Barcodes: (code, packaging) pairs.
    final wanted = <(String, String?)>[
      for (final b in draft.barcodes)
        if (b.isNotEmpty) (b, null),
      for (var i = 0; i < draft.packagings.length; i++)
        if ((draft.packagings[i].barcode ?? '').isNotEmpty)
          (draft.packagings[i].barcode!, ids[i]),
    ];
    final live =
        await (db.select(db.barcodeEntries)..where(
              (t) => t.productId.equals(productId) & t.deletedAt.isNull(),
            ))
            .get();
    final matched = <String>{};
    final missing = <(String, String?)>[];
    for (final w in wanted) {
      final hit = live.where(
        (r) =>
            r.barcode == w.$1 &&
            r.packagingId == w.$2 &&
            !matched.contains(r.id),
      );
      if (hit.isEmpty) {
        missing.add(w);
      } else {
        matched.add(hit.first.id);
      }
    }
    for (final r in live) {
      if (matched.contains(r.id)) continue;
      await (db.update(
        db.barcodeEntries,
      )..where((t) => t.id.equals(r.id))).write(
        BarcodeEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    }
    for (final (code, packagingId) in missing) {
      await _ensureFree(db, code, storeId, null);
      try {
        await db
            .into(db.barcodeEntries)
            .insert(
              BarcodeEntriesCompanion.insert(
                id: _uuid.generate(),
                productId: productId,
                packagingId: Value(packagingId),
                storeId: Value(storeId),
                barcode: code,
                createdAt: now,
                updatedAt: now,
              ),
            );
      } on SqliteException {
        throw DuplicateBarcodeException(code);
      }
    }
  }

  /// The product's offers match [draft]: edited ones update, removed ones get
  /// a tombstone, new ones are inserted. A discount or promotion belongs to
  /// the product; a free-item tier has the product as its gift.
  Future<void> _writeOffers(
    AxpertDatabase db,
    String productId,
    String? storeId,
    ProductDraft draft,
    int now,
  ) async {
    final existing =
        await (db.select(db.offerEntries)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  (t.productId.equals(productId) |
                      t.giftProductId.equals(productId)),
            ))
            .get();
    final keep = {
      for (final o in draft.offers)
        if (o.id != null) o.id!,
    };
    for (final old in existing) {
      if (keep.contains(old.id)) continue;
      await (db.update(
        db.offerEntries,
      )..where((t) => t.id.equals(old.id))).write(
        OfferEntriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
      );
    }
    final known = {for (final o in existing) o.id};
    final currency = _currency(draft);
    for (final o in draft.offers) {
      final gift = o.kind == OfferKind.giftTier;
      final fixed = o.kind == OfferKind.discount && o.fixedMinor != null;
      final id = o.id ?? _uuid.generate();
      final values = OfferEntriesCompanion(
        kind: Value(o.kind.code),
        name: Value(o.name.trim()),
        storeId: Value(storeId),
        productId: Value(gift ? null : productId),
        giftProductId: Value(gift ? productId : null),
        percentBp: Value(gift || fixed ? null : o.percentBp),
        fixedAmountMinor: Value(fixed ? o.fixedMinor : null),
        currencyCode: Value(gift || fixed ? currency : null),
        minCartMinor: Value(gift ? o.minCartMinor : null),
        startsAt: Value(o.startsAt?.toUtc().millisecondsSinceEpoch),
        endsAt: Value(o.endsAt?.toUtc().millisecondsSinceEpoch),
        active: Value(o.active),
        priority: Value(o.priority),
        updatedAt: Value(now),
      );
      if (o.id != null && known.contains(o.id)) {
        await (db.update(
          db.offerEntries,
        )..where((t) => t.id.equals(id))).write(values);
      } else {
        await db
            .into(db.offerEntries)
            .insert(values.copyWith(id: Value(id), createdAt: Value(now)));
      }
    }
  }

  Future<List<OfferDraft>> _offersOf(
    AxpertDatabase db,
    String productId,
  ) async {
    final rows =
        await (db.select(db.offerEntries)
              ..where(
                (t) =>
                    t.deletedAt.isNull() &
                    (t.productId.equals(productId) |
                        t.giftProductId.equals(productId)),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.priority),
                (t) => OrderingTerm.asc(t.createdAt),
              ]))
            .get();
    DateTime? utc(int? ms) => ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    return [
      for (final r in rows)
        OfferDraft(
          id: r.id,
          kind: OfferKind.parse(r.kind),
          name: r.name,
          percentBp: r.percentBp,
          fixedMinor: r.fixedAmountMinor,
          minCartMinor: r.minCartMinor,
          startsAt: utc(r.startsAt),
          endsAt: utc(r.endsAt),
          active: r.active,
          priority: r.priority,
        ),
    ];
  }

  /// Throws [DuplicateBarcodeException] when another live row of the same
  /// store scope has [code] (the partial unique index would refuse it too).
  Future<void> _ensureFree(
    AxpertDatabase db,
    String code,
    String? storeId,
    String? exceptRow,
  ) async {
    final clash = await db
        .customSelect(
          'SELECT 1 FROM product_barcodes WHERE barcode = ? AND id != ? '
          "AND deleted_at IS NULL AND COALESCE(store_id, '') = ?",
          variables: [
            Variable<String>(code),
            Variable<String>(exceptRow ?? ''),
            Variable<String>(storeId ?? ''),
          ],
        )
        .get();
    if (clash.isNotEmpty) throw DuplicateBarcodeException(code);
  }
}
