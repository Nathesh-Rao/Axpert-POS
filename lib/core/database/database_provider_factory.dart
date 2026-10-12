import 'database_config.dart';
import 'database_provider.dart';
import 'database_provider_stub.dart'
    if (dart.library.io) 'native_database_provider.dart'
    if (dart.library.js_interop) 'web_database_provider.dart'
    as platform;

/// Creates the platform-specific local database provider.
DatabaseProvider createDatabaseProvider(DatabaseConfig config) =>
    platform.createDatabaseProvider(config);
