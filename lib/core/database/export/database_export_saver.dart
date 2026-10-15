import 'dart:typed_data';

/// Where a saved export ended up.
class SavedExport {
  const SavedExport({required this.fileName, this.path});

  final String fileName;

  /// Full path on native platforms; null on the web (a browser download).
  final String? path;
}

/// Hands the snapshot bytes to the user: a browser download on the web, a file
/// in Downloads (else Documents) elsewhere.
abstract interface class DatabaseExportSaver {
  Future<SavedExport> save(String fileName, Uint8List bytes);
}
