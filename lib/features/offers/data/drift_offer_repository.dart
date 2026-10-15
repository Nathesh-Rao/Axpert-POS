import 'package:drift/drift.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/database/migration/product_rows.dart';
import '../../../core/services/pricing/basis_points.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/money.dart';
import '../domain/entities/offer.dart';
import '../domain/repositories/offer_repository.dart';

/// Offers from Drift only (no LocalStore mirror, DEC-134).
class DriftOfferRepository implements OfferRepository {
  static DateTime? _utc(int? ms) =>
      ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

  DriftOfferRepository(this._provider);

  final DatabaseProvider _provider;

  @override
  Future<List<Offer>> load({required String? storeId}) async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.offerEntries)
              ..where(
                (t) =>
                    t.active.equals(true) &
                    t.deletedAt.isNull() &
                    (storeId == null
                        ? const Constant(true)
                        : t.storeId.isNull() | t.storeId.equals(storeId)),
              )
              ..orderBy([
                (t) => OrderingTerm.desc(t.priority),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    if (rows.isEmpty) return const <Offer>[];
    final productIds = <String>{
      for (final r in rows) ...[
        if (r.productId != null) r.productId!,
        if (r.giftProductId != null) r.giftProductId!,
      ],
    };
    final products = await (db.select(
      db.productEntries,
    )..where((t) => t.id.isIn(productIds) & t.deletedAt.isNull())).get();
    final byUuid = {for (final p in products) p.id: p};
    final offers = <Offer>[];
    for (final r in rows) {
      final product = r.productId == null ? null : byUuid[r.productId];
      final giftRow = r.giftProductId == null ? null : byUuid[r.giftProductId];
      final kind = OfferKind.parse(r.kind);
      if (kind != OfferKind.giftTier && product == null) continue;
      if (kind == OfferKind.giftTier && giftRow == null) continue;
      final currency = r.currencyCode == null
          ? null
          : CurrencyRegistry.byCode(r.currencyCode!);
      offers.add(
        Offer(
          id: r.id,
          kind: kind,
          name: r.name,
          storeId: r.storeId,
          productId: product?.legacyId,
          percent: r.percentBp == null ? null : Bp(r.percentBp!),
          fixedOff: r.fixedAmountMinor == null || currency == null
              ? null
              : Money(r.fixedAmountMinor!, currency),
          minCart: r.minCartMinor == null || currency == null
              ? null
              : Money(r.minCartMinor!, currency),
          gift: giftRow == null
              ? null
              : ProductRows.toProduct(
                  giftRow,
                ).inCurrency(CurrencyRegistry.byCode(giftRow.currencyCode)),
          startsAt: _utc(r.startsAt),
          endsAt: _utc(r.endsAt),
          priority: r.priority,
        ),
      );
    }
    return offers;
  }
}

/// Fixed offers for tests and for sessions without a database.
class InMemoryOfferRepository implements OfferRepository {
  InMemoryOfferRepository([this.offers = const <Offer>[]]);

  final List<Offer> offers;

  @override
  Future<List<Offer>> load({required String? storeId}) async => [
    for (final o in offers)
      if (o.storeId == null || o.storeId == storeId) o,
  ];
}
