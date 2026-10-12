import 'package:drift/drift.dart';

import 'tables/device_context_entries.dart';
import 'tables/migration_state_entries.dart';
import 'tables/settings_entries.dart';

part 'axpert_database.g.dart';

/// Drift database: device context metadata and device-local settings.
///
/// Schema v3 (settings, migration_state) is provisional and local-only
/// (DEC-124); it no longer matches axpert's schema.
@DriftDatabase(
  tables: [DeviceContextEntries, SettingsEntries, MigrationStateEntries],
)
class AxpertDatabase extends _$AxpertDatabase {
  AxpertDatabase(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2 && to >= 2) {
        await migrator.createTable(deviceContextEntries);
      }
      if (from < 3 && to >= 3) {
        // Drift does not roll back a failed upgrade by itself; one
        // transaction keeps v3 all-or-nothing.
        await transaction(() async {
          await migrator.createTable(settingsEntries);
          await migrator.createTable(migrationStateEntries);
        });
      }
    },
    beforeOpen: (_) async {
      // The database design requires SQLite foreign-key checks on each open.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
