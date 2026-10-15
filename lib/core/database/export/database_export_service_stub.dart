import '../database_provider.dart';
import 'database_export_service.dart';

DatabaseExportService createPlatformExportService(DatabaseProvider provider) =>
    throw UnsupportedError('Database export is not supported here');
