import 'package:pos_application/core/bindings/app_infrastructure.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/device/device_context.dart';
import 'package:pos_application/core/device/device_context_service.dart';
import 'package:pos_application/core/device/device_context_store.dart';
import 'package:pos_application/core/device/device_id_generator.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/lifecycle/app_lifecycle_service.dart';
import 'package:pos_application/core/network/dio_api_client.dart';
import 'package:pos_application/core/security/unconfigured_authentication_service.dart';

/// Stands in for the Drift database in every test that is not about the
/// database: it never opens, so no sqlite3 library is loaded.
class FakeDatabaseProvider implements DatabaseProvider {
  /// Number of `close()` calls.
  int closed = 0;

  @override
  Future<AxpertDatabase> open() =>
      Future<AxpertDatabase>.error(StateError('FakeDatabaseProvider.open'));

  @override
  Future<void> close() async => closed++;
}

class MemoryDeviceContextStore implements DeviceContextStore {
  DeviceContext? stored;

  @override
  Future<DeviceContext?> read() async => stored;

  @override
  Future<void> write(DeviceContext context) async => stored = context;
}

class FixedDeviceIdGenerator implements DeviceIdGenerator {
  const FixedDeviceIdGenerator();

  @override
  String generate() => '4b1f3a52-191c-4dd2-9e19-2da6fd9aec21';
}

/// Infrastructure for tests: fakes and in-memory stores, no real database, no
/// platform lifecycle observer.
AppInfrastructure testInfrastructure({
  FakeDatabaseProvider? databaseProvider,
  MemoryDeviceContextStore? deviceContextStore,
}) {
  const config = DevelopmentAppConfig(settingsBackend: SettingsBackend.mock);
  return AppInfrastructure(
    config: config,
    apiClient: DioApiClient(config: config),
    databaseProvider: databaseProvider ?? FakeDatabaseProvider(),
    deviceContextService: DeviceContextService(
      store: deviceContextStore ?? MemoryDeviceContextStore(),
      idGenerator: const FixedDeviceIdGenerator(),
    ),
    uuid: UuidV4Generator(),
    authentication: const UnconfiguredAuthenticationService(),
    lifecycle: AppLifecycleService(observe: false),
    diagnostics: StartupDiagnostics(),
  );
}
