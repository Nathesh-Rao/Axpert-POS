import 'dart:typed_data';

/// A standalone SQLite file holding the whole database at one moment.
class DatabaseSnapshot {
  const DatabaseSnapshot({
    required this.bytes,
    required this.schemaVersion,
    required this.tableCount,
  });

  final Uint8List bytes;

  /// `PRAGMA user_version` of the snapshot (the Drift schema version).
  final int schemaVersion;

  /// Number of user tables in the snapshot.
  final int tableCount;
}

/// Produces a consistent snapshot of the local database (never a copy of the
/// live file).
abstract interface class DatabaseExportService {
  Future<DatabaseSnapshot> createSnapshot();
}
