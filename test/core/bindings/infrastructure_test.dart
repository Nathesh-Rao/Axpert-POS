// Stage 5 (axpert_pos integration): bootstrap with a safe failure path, the
// idempotent registrations in InitialBinding and the lifecycle observer.
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/app_infrastructure.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/database/database_config.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/native_database_provider.dart';
import 'package:pos_application/core/device/device_context_service.dart';
import 'package:pos_application/core/identifiers/uuid_generator.dart';
import 'package:pos_application/core/lifecycle/app_lifecycle_service.dart';
import 'package:pos_application/core/network/api_client.dart';
import 'package:pos_application/core/security/authentication_service.dart';
import 'package:pos_application/core/session/session_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_infrastructure.dart';

void main() {
  useTestApp();

  test(
    'bootstrap survives a database that cannot open (logged, no throw)',
    () async {
      final infrastructure = await AppInfrastructure.bootstrap(
        databaseProvider: FakeDatabaseProvider(),
      );
      expect(infrastructure.diagnostics.hasFailures, isTrue);
      expect(infrastructure.diagnostics.failures.single.stage, 'database');
      expect(infrastructure.deviceContextService.context.value, isNull);
    },
  );

  test(
    'bootstrap opens the database and restores a stable device id',
    () async {
      final provider = NativeDatabaseProvider(
        config: const DatabaseConfig(),
        executor: NativeDatabase.memory(),
      );
      addTearDown(provider.close);
      final infrastructure = await AppInfrastructure.bootstrap(
        databaseProvider: provider,
      );
      expect(infrastructure.diagnostics.hasFailures, isFalse);
      expect(
        infrastructure.deviceContextService.context.value?.deviceId,
        matches(RegExp(r'^[0-9a-f-]{36}$')),
      );
    },
  );

  test(
    'InitialBinding registers the infrastructure once, however often it runs',
    () async {
      final binding = await bootTestApp();
      final session = Get.find<SessionController>();
      binding.dependencies();
      binding.dependencies();
      expect(Get.find<SessionController>(), same(session));
      final i = binding.infrastructure;
      expect(Get.find<AppConfig>(), same(i.config));
      expect(Get.find<ApiClient>(), same(i.apiClient));
      expect(Get.find<DatabaseProvider>(), same(i.databaseProvider));
      expect(Get.find<DeviceContextService>(), same(i.deviceContextService));
      expect(Get.find<UuidGenerator>(), same(i.uuid));
      expect(Get.find<AuthenticationService>(), same(i.authentication));
      expect(Get.find<AppLifecycleService>(), same(i.lifecycle));
      expect(Get.find<StartupDiagnostics>(), same(i.diagnostics));
      expect(binding, isA<InitialBinding>());
    },
  );

  test(
    'the session starts unauthenticated (authentication is unconfigured)',
    () async {
      await bootTestApp();
      await Future<void>.delayed(Duration.zero);
      expect(
        Get.find<SessionController>().status.value,
        SessionStatus.unauthenticated,
      );
    },
  );

  test('detaching the app closes the database', () async {
    final database = FakeDatabaseProvider();
    Get.reset();
    final binding = InitialBinding(
      (await bootTestApp()).store,
      infrastructure: testInfrastructure(databaseProvider: database),
    );
    Get.reset();
    binding.dependencies();
    Get.find<AppLifecycleService>().didChangeAppLifecycleState(
      AppLifecycleState.detached,
    );
    expect(database.closed, 1);
  });
}
