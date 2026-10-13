import 'package:drift/drift.dart';

import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/services/pricing/currency.dart';
import '../domain/entities/session_entities.dart';
import '../domain/repositories/session_repositories.dart';

/// Users, stores and counters from Drift. Drift-only: no LocalStore mirror.
class DriftUserRepository implements UserRepository {
  DriftUserRepository(this._provider);

  final DatabaseProvider _provider;

  @override
  Future<bool> hasUsers() async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.userEntries)
              ..where((t) => t.active.equals(true) & t.deletedAt.isNull())
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  @override
  Future<UserCredential?> findByUsername(String username) async {
    final db = await _provider.open();
    final row =
        await (db.select(db.userEntries)..where(
              (t) =>
                  t.username.equals(username) &
                  t.active.equals(true) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row == null ? null : _credential(row);
  }

  @override
  Future<UserCredential?> firstActive() async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.userEntries)
              ..where((t) => t.active.equals(true) & t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.username),
              ])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : _credential(rows.first);
  }

  @override
  Future<List<StoreAccess>> accessFor(String userId) async {
    final db = await _provider.open();
    final access = await (db.select(
      db.userAccessEntries,
    )..where((t) => t.userId.equals(userId))).get();
    final stores =
        await (db.select(db.storeEntries)
              ..where((t) => t.active.equals(true) & t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.createdAt),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    final counters =
        await (db.select(db.counterEntries)
              ..where((t) => t.active.equals(true) & t.deletedAt.isNull())
              ..orderBy([(t) => OrderingTerm.asc(t.name)]))
            .get();
    final result = <StoreAccess>[];
    for (final store in stores) {
      final grants = access.where((a) => a.storeId == store.id).toList();
      if (grants.isEmpty) continue;
      final any = grants.any((g) => g.counterId == null);
      final allowed = grants
          .map((g) => g.counterId)
          .whereType<String>()
          .toSet();
      result.add(
        StoreAccess(
          store: _store(store),
          counters: [
            for (final c in counters)
              if (c.storeId == store.id && (any || allowed.contains(c.id)))
                CounterInfo(id: c.id, storeId: c.storeId, name: c.name),
          ],
        ),
      );
    }
    return result;
  }

  UserCredential _credential(UserEntry r) => UserCredential(
    user: AppUser(
      id: r.id,
      username: r.username,
      displayName: r.displayName,
      role: r.role,
    ),
    salt: r.salt,
    passwordHash: r.passwordHash,
    hashAlgo: r.hashAlgo,
  );

  StoreInfo _store(StoreEntry r) => StoreInfo(
    id: r.id,
    name: r.name,
    currencyCode: r.currencyCode,
    address: r.address,
    phone: r.phone,
    taxId: r.taxId,
    receiptHeader: r.receiptHeader,
    receiptFooter: r.receiptFooter,
    region: r.region,
  );
}

class DriftStoreRepository implements StoreRepository {
  DriftStoreRepository(this._provider, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DatabaseProvider _provider;
  final DateTime Function() _now;

  @override
  Future<bool> hasStores() async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.storeEntries)
              ..where((t) => t.deletedAt.isNull())
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  @override
  Future<List<CurrencyRow>> loadCurrencies() async {
    final db = await _provider.open();
    final rows = await db.select(db.currencyEntries).get();
    return [
      for (final r in rows)
        CurrencyRow(
          currency: Currency(
            code: r.code,
            symbol: r.symbol,
            exponent: r.exponent,
            grouping: r.grouping == 'lakh'
                ? DigitGrouping.lakh
                : DigitGrouping.thousands,
          ),
          quickCash: [
            for (final part in r.quickCash.split(','))
              if (int.tryParse(part.trim()) != null) int.parse(part.trim()),
          ],
        ),
    ];
  }

  @override
  Future<List<ForexRate>> loadForex(String storeId) async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.storeForexEntries)
              ..where((t) => t.storeId.equals(storeId) & t.active.equals(true))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final r in rows)
        ForexRate(code: r.foreignCurrencyCode, rateMicro: r.rateMicro),
    ];
  }

  @override
  Future<TaxRegimeInfo?> loadTaxRegime(String region) async {
    if (region.isEmpty) return null;
    final db = await _provider.open();
    final regime = await (db.select(
      db.taxRegimeEntries,
    )..where((t) => t.region.equals(region))).getSingleOrNull();
    if (regime == null) return null;
    final slabs =
        await (db.select(db.taxSlabEntries)
              ..where((t) => t.regimeId.equals(regime.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return TaxRegimeInfo(
      region: regime.region,
      label: regime.label,
      inclusive: regime.priceMode == 'inclusive',
      splitParts: [
        for (final p in regime.splitParts.split(','))
          if (p.trim().isNotEmpty) p.trim(),
      ],
      slabs: [
        for (final s in slabs) TaxSlabInfo(rateBp: s.rateBp, label: s.label),
      ],
    );
  }

  @override
  Future<void> renameCounter(String counterId, String name) async {
    final db = await _provider.open();
    await (db.update(
      db.counterEntries,
    )..where((t) => t.id.equals(counterId))).write(
      CounterEntriesCompanion(
        name: Value(name),
        updatedAt: Value(_now().toUtc().toIso8601String()),
      ),
    );
  }
}
