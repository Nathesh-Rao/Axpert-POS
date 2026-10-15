import '../database_provider.dart';
import 'database_export_service.dart';
import 'database_export_service_stub.dart'
    if (dart.library.io) 'native_snapshot_service.dart'
    if (dart.library.js_interop) 'web_snapshot_service.dart'
    as platform;

/// The platform's snapshot service (VACUUM INTO native, logical copy web).
DatabaseExportService createDatabaseExportService(DatabaseProvider provider) =>
    platform.createPlatformExportService(provider);
