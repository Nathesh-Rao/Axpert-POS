import 'database_export_saver.dart';
import 'database_export_saver_stub.dart'
    if (dart.library.io) 'io_export_saver.dart'
    if (dart.library.js_interop) 'web_export_saver.dart'
    as platform;

/// The platform's saver (browser download on web, Downloads/Documents else).
DatabaseExportSaver createDatabaseExportSaver() =>
    platform.createPlatformExportSaver();
