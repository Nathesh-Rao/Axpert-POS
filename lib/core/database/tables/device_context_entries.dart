import 'package:drift/drift.dart';

/// One local row holding non-secret device and assignment metadata.
class DeviceContextEntries extends Table {
  IntColumn get singletonId => integer().withDefault(const Constant(1))();

  TextColumn get deviceId => text()();

  TextColumn get outletId => text().nullable()();

  TextColumn get registerId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {singletonId};
}
