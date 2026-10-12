import 'package:drift/drift.dart';

import 'tables/device_context_entries.dart';

part 'axpert_database.g.dart';

/// Drift database with non-secret device context metadata only.
@DriftDatabase(tables: [DeviceContextEntries])
class AxpertDatabase extends _$AxpertDatabase {
  AxpertDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2 && to >= 2) {
        await migrator.createTable(deviceContextEntries);
      }
    },
    beforeOpen: (_) async {
      // The database design requires SQLite foreign-key checks on each open.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
