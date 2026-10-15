import 'package:drift/drift.dart';

import 'store_entries.dart';

/// A named bundle of tax components of one store (v15): "GST 18%" is CGST 9%
/// plus SGST 9%. The slab total is the sum of its enabled components. `scheme`
/// `standard` is what bills use; `inter_state` holds the IGST style slabs.
@DataClassName('StoreTaxSlabEntry')
@TableIndex(name: 'store_tax_slabs_store', columns: {#storeId})
class StoreTaxSlabEntries extends Table {
  @override
  String get tableName => 'store_tax_slabs';

  TextColumn get id => text()();

  TextColumn get storeId => text().references(StoreEntries, #id)();

  TextColumn get name => text()();

  TextColumn get scheme => text()
      .withDefault(const Constant('standard'))
      // ignore: recursive_getters
      .check(scheme.isIn(const ['standard', 'inter_state']))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One component of a store slab: a label and a rate in basis points.
@DataClassName('StoreTaxComponentEntry')
class StoreTaxComponentEntries extends Table {
  @override
  String get tableName => 'store_tax_components';

  TextColumn get id => text()();

  TextColumn get slabId => text().references(StoreTaxSlabEntries, #id)();

  TextColumn get label => text()();

  IntColumn get rateBp =>
      // ignore: recursive_getters
      integer().check(rateBp.isBetweenValues(0, 10000))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
