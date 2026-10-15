import 'package:drift/drift.dart';

import '../../../core/database/axpert_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/store_tax_rows.dart';
import '../../../core/identifiers/uuid_generator.dart';
import '../../../core/services/pricing/currency_registry.dart';
import '../../../core/services/pricing/currency.dart';
import '../../../core/utils/epoch_time.dart';
import '../../session/domain/entities/session_entities.dart';
import '../domain/entities/store_config.dart';
import '../domain/repositories/store_config_repository.dart';
import '../domain/services/legacy_slabs.dart';

class DriftStoreConfigRepository implements StoreConfigRepository {
  DriftStoreConfigRepository(
    this._provider,
    this._uuid, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DatabaseProvider _provider;
  final UuidGenerator _uuid;
  final DateTime Function() _now;

  @override
  Future<StoreConfig> load(String storeId) async {
    final db = await _provider.open();
    final store = await (db.select(
      db.storeEntries,
    )..where((t) => t.id.equals(storeId))).getSingle();
    final forex =
        await (db.select(db.storeForexEntries)
              ..where((t) => t.storeId.equals(storeId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final regime = await (db.select(
      db.taxRegimeEntries,
    )..where((t) => t.region.equals(store.region))).getSingleOrNull();
    var slabs = await StoreTaxRows.load(db, storeId);
    if (slabs.isEmpty && regime != null) {
      final legacySlabs =
          await (db.select(db.taxSlabEntries)
                ..where((t) => t.regimeId.equals(regime.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      slabs = LegacySlabs.from(
        TaxRegimeInfo(
          region: regime.region,
          label: regime.label,
          inclusive: regime.priceMode == 'inclusive',
          splitParts: [
            for (final p in regime.splitParts.split(','))
              if (p.trim().isNotEmpty) p.trim(),
          ],
          slabs: [
            for (final s in legacySlabs)
              TaxSlabInfo(rateBp: s.rateBp, label: s.label),
          ],
        ),
      );
    }
    return StoreConfig(
      storeId: store.id,
      name: store.name,
      countryCode: store.region,
      stateCode: store.stateCode ?? '',
      currencyCode: store.currencyCode,
      inclusive: regime?.priceMode == 'inclusive',
      forex: [
        for (final f in forex)
          ForexRow(
            code: f.foreignCurrencyCode,
            rateMicro: f.rateMicro,
            active: f.active,
            updatedAtMs: f.updatedAt,
          ),
      ],
      slabs: slabs,
    );
  }

  @override
  Future<void> save(StoreConfig config) async {
    final db = await _provider.open();
    final now = _now();
    final stamp = EpochTime.fromDateTime(now);
    await db.transaction(() async {
      await _ensureCurrency(db, config.currencyCode, stamp);
      for (final f in config.forex) {
        await _ensureCurrency(db, f.code, stamp);
      }
      await (db.update(
        db.storeEntries,
      )..where((t) => t.id.equals(config.storeId))).write(
        StoreEntriesCompanion(
          name: Value(config.name.trim()),
          region: Value(config.countryCode),
          currencyCode: Value(config.currencyCode),
          stateCode: Value(config.stateCode.isEmpty ? null : config.stateCode),
          updatedAt: Value(stamp),
        ),
      );
      await _saveForex(db, config, stamp);
      await StoreTaxRows.replace(db, config.storeId, config.slabs, _uuid, now);
    });
  }

  Future<void> _saveForex(
    AxpertDatabase db,
    StoreConfig config,
    int stamp,
  ) async {
    final old = await (db.select(
      db.storeForexEntries,
    )..where((t) => t.storeId.equals(config.storeId))).get();
    final byCode = {for (final o in old) o.foreignCurrencyCode: o};
    final keep = {for (final f in config.forex) f.code};
    for (final o in old) {
      if (!keep.contains(o.foreignCurrencyCode)) {
        await (db.delete(
          db.storeForexEntries,
        )..where((t) => t.id.equals(o.id))).go();
      }
    }
    for (var i = 0; i < config.forex.length; i++) {
      final f = config.forex[i];
      final existing = byCode[f.code];
      if (existing == null) {
        await db
            .into(db.storeForexEntries)
            .insert(
              StoreForexEntriesCompanion.insert(
                id: _uuid.generate(),
                storeId: config.storeId,
                foreignCurrencyCode: f.code,
                rateMicro: f.rateMicro,
                active: Value(f.active),
                position: Value(i),
                createdAt: stamp,
                updatedAt: stamp,
              ),
            );
      } else if (existing.rateMicro != f.rateMicro ||
          existing.active != f.active ||
          existing.position != i) {
        // The effective date moves only when the row changed.
        await (db.update(
          db.storeForexEntries,
        )..where((t) => t.id.equals(existing.id))).write(
          StoreForexEntriesCompanion(
            rateMicro: Value(f.rateMicro),
            active: Value(f.active),
            position: Value(i),
            updatedAt:
                existing.rateMicro != f.rateMicro || existing.active != f.active
                ? Value(stamp)
                : const Value.absent(),
          ),
        );
      }
    }
  }

  /// The `currencies` table is the FK target: a registry currency the demo
  /// seed did not insert gets its row on first use.
  Future<void> _ensureCurrency(
    AxpertDatabase db,
    String code,
    int stamp,
  ) async {
    final row = await (db.select(
      db.currencyEntries,
    )..where((t) => t.code.equals(code))).getSingleOrNull();
    if (row != null) return;
    final c = CurrencyRegistry.byCode(code);
    await db
        .into(db.currencyEntries)
        .insert(
          CurrencyEntriesCompanion.insert(
            code: c.code,
            name: c.code,
            symbol: c.symbol,
            exponent: c.exponent,
            grouping: c.grouping == DigitGrouping.lakh ? 'lakh' : 'thousands',
            createdAt: stamp,
            updatedAt: stamp,
          ),
        );
  }

  @override
  Future<bool> storeHasSales(String storeId) async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.saleEntries)
              ..where((t) => t.storeId.equals(storeId))
              ..limit(1))
            .get();
    return rows.isNotEmpty;
  }

  @override
  Future<Map<int, int>> productCountsByRate(String storeId) async {
    final db = await _provider.open();
    final rows = await db
        .customSelect(
          'SELECT gst_bp, count(*) AS n FROM products '
          'WHERE store_id = ? AND deleted_at IS NULL GROUP BY gst_bp',
          variables: [Variable.withString(storeId)],
        )
        .get();
    return {for (final r in rows) r.read<int>('gst_bp'): r.read<int>('n')};
  }
}
