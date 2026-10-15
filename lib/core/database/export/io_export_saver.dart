import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database_export_saver.dart';

DatabaseExportSaver createPlatformExportSaver() => IoExportSaver();

/// Writes to the Downloads folder, else the Documents folder. Never
/// overwrites: an existing name gets `_2`, `_3` ... before the extension.
final class IoExportSaver implements DatabaseExportSaver {
  IoExportSaver({
    Future<Directory?> Function()? downloads,
    Future<Directory> Function()? documents,
  }) : _downloads = downloads ?? getDownloadsDirectory,
       _documents = documents ?? getApplicationDocumentsDirectory;

  final Future<Directory?> Function() _downloads;
  final Future<Directory> Function() _documents;

  @override
  Future<SavedExport> save(String fileName, Uint8List bytes) async {
    final dir = await _target();
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var file = File(p.join(dir.path, fileName));
    for (var n = 2; await file.exists(); n++) {
      file = File(p.join(dir.path, '${base}_$n$ext'));
    }
    await file.writeAsBytes(bytes, flush: true);
    return SavedExport(fileName: p.basename(file.path), path: file.path);
  }

  Future<Directory> _target() async {
    try {
      final downloads = await _downloads();
      if (downloads != null) {
        await downloads.create(recursive: true);
        return downloads;
      }
    } on Object {
      // Not available here (mobile) or not writable: fall back to Documents.
    }
    return _documents();
  }
}
