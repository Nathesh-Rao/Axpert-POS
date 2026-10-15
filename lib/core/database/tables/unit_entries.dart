import 'package:drift/drift.dart';

/// Units of measure (provisional, local-only, DEC-150). Global rows, not
/// store-scoped. The eight seeded units carry FIXED ids ([SeedUnits]) so the
/// same unit has the same id on every device.
@DataClassName('UnitEntry')
class UnitEntries extends Table {
  @override
  String get tableName => 'units';

  TextColumn get id => text()();

  /// Stable key: piece, pack, carton, box, kg, g, litre, ml.
  TextColumn get code => text().unique()();

  TextColumn get name => text()();

  /// count, weight or volume.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(const ['count', 'weight', 'volume']),
  )();

  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// One seeded unit.
class SeedUnit {
  const SeedUnit(this.id, this.code, this.name, this.kind);

  final String id;
  final String code;
  final String name;
  final String kind;
}

/// The seeded units with their fixed ids.
abstract final class SeedUnits {
  static const SeedUnit piece = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000001',
    'piece',
    'Piece',
    'count',
  );
  static const SeedUnit pack = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000002',
    'pack',
    'Pack',
    'count',
  );
  static const SeedUnit carton = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000003',
    'carton',
    'Carton',
    'count',
  );
  static const SeedUnit box = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000004',
    'box',
    'Box',
    'count',
  );
  static const SeedUnit kg = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000005',
    'kg',
    'Kilogram',
    'weight',
  );
  static const SeedUnit g = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000006',
    'g',
    'Gram',
    'weight',
  );
  static const SeedUnit litre = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000007',
    'litre',
    'Litre',
    'volume',
  );
  static const SeedUnit ml = SeedUnit(
    '5a1f0001-0000-4000-8000-000000000008',
    'ml',
    'Millilitre',
    'volume',
  );

  static const List<SeedUnit> all = [
    piece,
    pack,
    carton,
    box,
    kg,
    g,
    litre,
    ml,
  ];
}
