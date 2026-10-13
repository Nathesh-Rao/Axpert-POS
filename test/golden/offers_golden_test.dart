// Offer goldens (DEC-134): the catalog with the three tile badges and the cart
// with a locked and an unlocked free item, light and dark. Regression only: the
// prototype has no offers, so there is no reference screenshot (unverified
// visually, KG list).

@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/theme/tokens/app_typography.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/main.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/products_panel_controller.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import 'harness.dart';
import 'images.dart';

const _inr = CurrencyRegistry.inr;

/// Cola (id 0) 20 % off, Oreo (id 7) Buy 1 Get 1, Lays (id 5) is the free item
/// of the 100 tier, Dairy Milk (id 8) the free item of the 500 tier.
List<Offer> _offers(ProductsController products) => <Offer>[
  const Offer(
    id: 'g-cola',
    kind: OfferKind.discount,
    name: 'Cola 20% off',
    productId: 0,
    percent: Bp(2000),
  ),
  const Offer(
    id: 'g-oreo',
    kind: OfferKind.promotion,
    name: 'Oreo Buy 1 Get 1',
    productId: 7,
    percent: Bp(5000),
  ),
  Offer(
    id: 'g-tier-100',
    kind: OfferKind.giftTier,
    name: 'Spend 100',
    minCart: const Money(10000, _inr),
    gift: products.byId(5),
  ),
  Offer(
    id: 'g-tier-500',
    kind: OfferKind.giftTier,
    name: 'Spend 500',
    minCart: const Money(50000, _inr),
    gift: products.byId(8),
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required bool dark,
  required Future<void> Function(WidgetTester tester) after,
}) async {
  useReferenceViewport(tester);
  // The offers need the products (the gifts), so boot once to read them.
  final binding = await bootInWidgetTest(tester);
  AppTypography.useBundledFonts = true;
  final offers = Get.find<OffersController>();
  offers.offers.assignAll(_offers(Get.find<ProductsController>()));
  offers.revision.value++;
  if (dark) {
    await tester.runAsync(() => Get.find<SettingsController>().setDark(true));
  }
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  await settleImages(tester);
  await after(tester);
}

void main() {
  useTolerantGoldens();
  useTestApp();
  final skipReason = fontsSkipReason();
  final skip = skipReason.isNotEmpty;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    if (!skip) await loadTestFonts();
  });
  final prefix = skip ? '[$skipReason] ' : '';

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 2)); // highlight ends
    Get.find<ToastController>().toasts.clear();
    await tester.pumpAndSettle();
    await settleImages(tester);
  }

  void golden(
    String name,
    String file, {
    required bool dark,
    required Future<void> Function(WidgetTester tester) after,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await _pump(tester, dark: dark, after: after);
        await expectLater(
          find.byType(PosApp),
          matchesGoldenFile('goldens/$file.png'),
        );
      } finally {
        if (Get.isRegistered<ToastController>()) {
          Get.find<ToastController>().onClose();
        }
        debugDefaultTargetPlatformOverride = null;
        restoreDefaultShadows();
      }
    }, skip: skip);
  }

  // The catalog is collapsed by default on desktop: open it to show the tiles.
  Future<void> tilesOnly(WidgetTester tester) async {
    await tester.runAsync(Get.find<ProductsPanelController>().open);
    await tester.pumpAndSettle();
    await settle(tester);
  }

  Future<void> lockedGift(WidgetTester tester) async {
    final products = Get.find<ProductsController>();
    final actions = Get.find<CartActionsController>();
    actions.add(products.byId(7)!); // Oreo: half price
    actions.add(products.byId(7)!);
    actions.add(products.byId(0)!); // Cola: 20 % off
    await settle(tester);
  }

  Future<void> unlockedGift(WidgetTester tester) async {
    final products = Get.find<ProductsController>();
    final actions = Get.find<CartActionsController>();
    actions.add(products.byId(7)!);
    actions.add(products.byId(0)!);
    actions.add(products.byId(11)!); // Closeup 85.00
    actions.add(products.byId(11)!);
    actions.add(products.byId(11)!);
    actions.add(products.byId(11)!);
    actions.add(products.byId(11)!);
    expect(
      Get.find<CartController>().offerResolution.value.gifts.first.unlocked,
      isTrue,
    );
    await settle(tester);
  }

  for (final dark in <bool>[false, true]) {
    final mode = dark ? 'dark' : 'light';
    golden(
      'Catalog tiles: discount, Buy 1 Get 1 and free gift badges ($mode)',
      'offers_tiles_$mode',
      dark: dark,
      after: tilesOnly,
    );
    golden(
      'Cart with offer lines and a locked free item ($mode)',
      'offers_cart_locked_$mode',
      dark: dark,
      after: lockedGift,
    );
    golden(
      'Cart with an unlocked free item ($mode)',
      'offers_cart_unlocked_$mode',
      dark: dark,
      after: unlockedGift,
    );
  }
}
