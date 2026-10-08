import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/main.dart';

/// Fresh Get registry, in-memory store, zero mock delay, bundled test fonts.
Future<InitialBinding> bootTestApp({LocalStore? store}) async {
  AppTypography.useBundledFonts = true;
  MockDelay.provider = () => Duration.zero;
  Get.reset();
  final binding = InitialBinding(store ?? InMemoryLocalStore());
  binding.dependencies();
  await binding.loadData();
  return binding;
}

void useTestApp() {
  tearDown(() {
    Get.reset();
    AppTypography.useBundledFonts = false;
  });
}

PosApp testApp(InitialBinding binding) => PosApp(binding: binding);

/// `bootTestApp` for `testWidgets`: the store awaits real futures, which
/// would hang inside the fake-async zone.
Future<InitialBinding> bootInWidgetTest(
  WidgetTester tester, {
  LocalStore? store,
}) async => (await tester.runAsync(() => bootTestApp(store: store)))!;
