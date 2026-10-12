import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/repository/checkout_repository.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/bindings/app_infrastructure.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/audio/audio_service.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/features/payment/domain/services/payment_service.dart';
import 'package:pos_application/main.dart';

import 'package:pos_application/features/offers/data/drift_offer_repository.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'test_infrastructure.dart';
import 'test_session.dart';

/// Fresh Get registry, in-memory store, zero mock delay, bundled test fonts.
Future<InitialBinding> bootTestApp({
  LocalStore? store,
  PaymentService? payments,
  AppInfrastructure? infrastructure,
  CheckoutRepository? checkout,
  bool? commitBeforeReceipt,
  List<Offer> offers = const <Offer>[],
  ActiveSession? session,
}) async {
  AppTypography.useBundledFonts = true;
  MockDelay.provider = () => Duration.zero;
  Get.reset();
  final localStore = store ?? InMemoryLocalStore();
  // What the first start used to seed: the legacy catalog and customers.
  for (final entry in legacyStoreData().entries) {
    if (!await localStore.has(entry.key)) {
      await localStore.write(entry.key, entry.value);
    }
  }
  final binding = InitialBinding(
    localStore,
    sessionOverride: session ?? testSession(),
    offerRepositoryOverride: InMemoryOfferRepository(offers),
    infrastructure: infrastructure ?? testInfrastructure(),
    audio: RecordingAudioService(),
    payments: payments,
    checkoutOverride: checkout,
    commitBeforeReceipt: commitBeforeReceipt,
  );
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

/// Starts on the landing page (like `--dart-define=SKIP_ENTRY=true`); pass
/// [AppRoutes.splash] to test the entry flow.
PosApp testApp(InitialBinding binding, {String initialRoute = AppRoutes.pos}) =>
    PosApp(binding: binding, initialRoute: initialRoute);

/// `bootTestApp` for `testWidgets`: the store awaits real futures, which
/// would hang inside the fake-async zone.
Future<InitialBinding> bootInWidgetTest(
  WidgetTester tester, {
  LocalStore? store,
  List<Offer> offers = const <Offer>[],
  ActiveSession? session,
}) async => (await tester.runAsync(
  () => bootTestApp(store: store, offers: offers, session: session),
))!;
