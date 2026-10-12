import '../config/app_config.dart';
import '../database/database_config.dart';
import '../database/database_provider.dart';
import '../database/database_provider_factory.dart';
import '../database/drift_device_context_store.dart';
import '../device/device_context_service.dart';
import '../device/device_id_generator.dart';
import '../identifiers/uuid_generator.dart';
import '../identifiers/uuid_v4_generator.dart';
import '../lifecycle/app_lifecycle_service.dart';
import '../network/api_client.dart';
import '../network/dio_api_client.dart';
import '../security/authentication_service.dart';
import '../security/unconfigured_authentication_service.dart';
import 'startup_diagnostics.dart';
import 'startup_timeline.dart';

/// The axpert_pos-style infrastructure objects, built once before `runApp`
/// and registered by `InitialBinding`. `main()` uses [bootstrap]; tests build
/// the pieces they need (fakes, in-memory stores) through the constructor.
class AppInfrastructure {
  const AppInfrastructure({
    required this.config,
    required this.apiClient,
    required this.databaseProvider,
    required this.deviceContextService,
    required this.uuid,
    required this.authentication,
    required this.lifecycle,
    required this.diagnostics,
  });

  final AppConfig config;
  final ApiClient apiClient;
  final DatabaseProvider databaseProvider;
  final DeviceContextService deviceContextService;
  final UuidGenerator uuid;
  final AuthenticationService authentication;
  final AppLifecycleService lifecycle;
  final StartupDiagnostics diagnostics;

  /// Opens the local database and restores the device context. A failure is
  /// recorded in [diagnostics] and the app still starts (DEC-119): the
  /// database only holds the device context in this batch.
  static Future<AppInfrastructure> bootstrap({
    AppConfig config = const DevelopmentAppConfig(),
    DatabaseProvider? databaseProvider,
    DeviceIdGenerator? idGenerator,
  }) async {
    final diagnostics = StartupDiagnostics();
    final provider =
        databaseProvider ?? createDatabaseProvider(const DatabaseConfig());
    final deviceContext = DeviceContextService(
      store: DriftDeviceContextStore(provider),
      idGenerator: idGenerator ?? UuidV4DeviceIdGenerator(),
    );
    try {
      await StartupTimeline.measure(
        'database open (incl. schema migrations)',
        provider.open,
      );
      await StartupTimeline.measure(
        'device context init',
        deviceContext.initialize,
      );
    } on Object catch (error, stackTrace) {
      diagnostics.record('database', error, stackTrace);
    }
    return AppInfrastructure(
      config: config,
      apiClient: DioApiClient(config: config),
      databaseProvider: provider,
      deviceContextService: deviceContext,
      uuid: UuidV4Generator(),
      authentication: const UnconfiguredAuthenticationService(),
      lifecycle: AppLifecycleService(),
      diagnostics: diagnostics,
    );
  }
}
