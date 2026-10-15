import 'dart:typed_data';

import 'package:sqlite3/wasm.dart';

import '../database_provider.dart';
import 'database_export_service.dart';
import 'logical_snapshot.dart';

DatabaseExportService createPlatformExportService(DatabaseProvider provider) =>
    WebSnapshotExportService(provider: provider);

/// Web snapshot: the page loads its own SQLite WASM (the same `sqlite3.wasm`
/// Drift uses), copies schema and rows into an in-memory file system and
/// returns that file's bytes (see [copyDatabaseInto]).
final class WebSnapshotExportService implements DatabaseExportService {
  WebSnapshotExportService({required this.provider});

  final DatabaseProvider provider;

  static const String _path = '/export.db';

  @override
  Future<DatabaseSnapshot> createSnapshot() async {
    final source = await provider.open();
    final wasm = await WasmSqlite3.loadFromUrl(Uri.parse('sqlite3.wasm'));
    final fileSystem = InMemoryFileSystem();
    wasm.registerVirtualFileSystem(fileSystem, makeDefault: false);
    final target = wasm.open(_path, vfs: fileSystem.name);
    try {
      final result = await copyDatabaseInto(source: source, target: target);
      target.close();
      final data = fileSystem.fileData[_path]!;
      return DatabaseSnapshot(
        bytes: Uint8List.fromList(data),
        schemaVersion: result.schemaVersion,
        tableCount: result.tables,
      );
    } finally {
      wasm.unregisterVirtualFileSystem(fileSystem);
    }
  }
}
