import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../axpert_database.dart';
import '../database_provider.dart';
import 'database_export_service.dart';

DatabaseExportService createPlatformExportService(DatabaseProvider provider) =>
    VacuumIntoExportService(provider: provider);

/// Native snapshot: `VACUUM INTO` a temp file that does not exist yet (a
/// consistent, defragmented copy that never depends on WAL state), read it,
/// delete it. The copy runs inside SQLite (Drift's background isolate), the
/// file read is async, so the UI isolate is not blocked.
final class VacuumIntoExportService implements DatabaseExportService {
  VacuumIntoExportService({
    required this.provider,
    Future<Directory> Function()? tempDirectory,
  }) : _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  final DatabaseProvider provider;
  final Future<Directory> Function() _tempDirectory;

  @override
  Future<DatabaseSnapshot> createSnapshot() async {
    final AxpertDatabase db = await provider.open();
    final dir = await _tempDirectory();
    final file = File(
      p.join(
        dir.path,
        'pos_export_${DateTime.now().microsecondsSinceEpoch}.db',
      ),
    );
    try {
      final escaped = file.path.replaceAll("'", "''");
      await db.customStatement("VACUUM INTO '$escaped'");
      final bytes = await file.readAsBytes();
      final (version, tables) = _inspect(file.path);
      return DatabaseSnapshot(
        bytes: bytes,
        schemaVersion: version,
        tableCount: tables,
      );
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  (int, int) _inspect(String path) {
    final snapshot = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      final version =
          snapshot.select('PRAGMA user_version').first.values.first! as int;
      final tables =
          snapshot
                  .select(
                    "SELECT count(*) FROM sqlite_master WHERE type = 'table' "
                    "AND name NOT LIKE 'sqlite_%'",
                  )
                  .first
                  .values
                  .first!
              as int;
      return (version, tables);
    } finally {
      snapshot.close();
    }
  }
}
