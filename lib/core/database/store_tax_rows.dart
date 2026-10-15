import 'package:drift/drift.dart';

import '../../features/session/domain/entities/session_entities.dart';
import '../identifiers/uuid_generator.dart';
import '../services/pricing/tax_components.dart';
import '../utils/epoch_time.dart';
import 'axpert_database.dart';

/// Reads and writes the store tax slabs and their components (v15).
abstract final class StoreTaxRows {
  /// The slabs of [storeId] in position order, with their components.
  static Future<List<TaxSlabInfo>> load(
    AxpertDatabase db,
    String storeId,
  ) async {
    final slabs =
        await (db.select(db.storeTaxSlabEntries)
              ..where((t) => t.storeId.equals(storeId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    if (slabs.isEmpty) return const <TaxSlabInfo>[];
    final ids = [for (final s in slabs) s.id];
    final comps =
        await (db.select(db.storeTaxComponentEntries)
              ..where((t) => t.slabId.isIn(ids))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return [
      for (final s in slabs)
        TaxSlabInfo.of(
          id: s.id,
          name: s.name,
          scheme: s.scheme,
          enabled: s.enabled,
          isDefault: s.isDefault,
          components: [
            for (final c in comps)
              if (c.slabId == s.id)
                TaxComponent(
                  label: c.label,
                  rateBp: c.rateBp,
                  enabled: c.enabled,
                ),
          ],
        ),
    ];
  }

  /// Replaces every slab of [storeId] (call inside a transaction).
  static Future<void> replace(
    AxpertDatabase db,
    String storeId,
    List<TaxSlabInfo> slabs,
    UuidGenerator uuid,
    DateTime now,
  ) async {
    final stamp = EpochTime.fromDateTime(now);
    final old = await (db.select(
      db.storeTaxSlabEntries,
    )..where((t) => t.storeId.equals(storeId))).get();
    final oldIds = [for (final s in old) s.id];
    if (oldIds.isNotEmpty) {
      await (db.delete(
        db.storeTaxComponentEntries,
      )..where((t) => t.slabId.isIn(oldIds))).go();
      await (db.delete(
        db.storeTaxSlabEntries,
      )..where((t) => t.storeId.equals(storeId))).go();
    }
    for (var i = 0; i < slabs.length; i++) {
      final slab = slabs[i];
      final id = slab.id.isEmpty ? uuid.generate() : slab.id;
      await db
          .into(db.storeTaxSlabEntries)
          .insert(
            StoreTaxSlabEntriesCompanion.insert(
              id: id,
              storeId: storeId,
              name: slab.label,
              scheme: Value(slab.scheme),
              enabled: Value(slab.enabled),
              isDefault: Value(slab.isDefault),
              position: Value(i),
              createdAt: stamp,
              updatedAt: stamp,
            ),
          );
      for (var j = 0; j < slab.components.length; j++) {
        final c = slab.components[j];
        await db
            .into(db.storeTaxComponentEntries)
            .insert(
              StoreTaxComponentEntriesCompanion.insert(
                id: uuid.generate(),
                slabId: id,
                label: c.label,
                rateBp: c.rateBp,
                enabled: Value(c.enabled),
                position: Value(j),
                createdAt: stamp,
                updatedAt: stamp,
              ),
            );
      }
    }
  }
}
