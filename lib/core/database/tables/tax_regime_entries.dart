import 'package:drift/drift.dart';

/// Tax regimes by region (local-only). `stores.region` selects the row.
@DataClassName('TaxRegimeEntry')
class TaxRegimeEntries extends Table {
  @override
  String get tableName => 'tax_regimes';

  TextColumn get id => text()();

  /// Region key matched against `stores.region` (`IN`, `UG`, ...).
  TextColumn get region => text().unique()();

  /// Tax name shown to the user (`GST`, `VAT`).
  TextColumn get label => text()();

  /// `exclusive` or `inclusive`.
  TextColumn get priceMode =>
      // ignore: recursive_getters
      text().check(priceMode.isIn(const ['exclusive', 'inclusive']))();

  /// Comma separated split components of the total tax (`CGST,SGST`); empty
  /// means a single line.
  TextColumn get splitParts => text().withDefault(const Constant(''))();

  TextColumn get createdAt => text()();

  TextColumn get updatedAt => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Rate slabs of a regime, in basis points.
@DataClassName('TaxSlabEntry')
class TaxSlabEntries extends Table {
  @override
  String get tableName => 'tax_slabs';

  TextColumn get id => text()();

  TextColumn get regimeId => text().references(TaxRegimeEntries, #id)();

  IntColumn get rateBp => integer()();

  TextColumn get label => text().withDefault(const Constant(''))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
