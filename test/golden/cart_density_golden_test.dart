// Desktop POS work-area goldens (DEC-139): the cart view (compact rows with
// offers and free items), the catalog view with items in the cart (the tab
// reads Cart (n)) and the catalog view of an empty cart. Regression only: the
// layout is an approved deviation from the prototype, no reference screenshot.

@TestOn('vm')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:pos_application/modules/pos/controllers/pos_work_view_controller.dart';
import 'package:pos_application/modules/shell/controllers/settings_controller.dart';
import 'package:pos_application/shared/controllers/clock_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../support/test_app.dart';
import 'harness.dart';
import 'images.dart';

const _inr = CurrencyRegistry.inr;

List<Offer> _offers(ProductsController products) => <Offer>[
  const Offer(
    id: 'd-cola',
    kind: OfferKind.discount,
    name: 'Cola 20% off',
    productId: 0,
    percent: Bp(2000),
  ),
  const Offer(
    id: 'd-oreo',
    kind: OfferKind.promotion,
    name: 'Oreo Buy 1 Get 1',
    productId: 7,
    percent: Bp(5000),
  ),
  Offer(
    id: 'd-tier-100',
    kind: OfferKind.giftTier,
    name: 'Spend 100',
    minCart: const Money(10000, _inr),
    gift: products.byId(5),
  ),
  Offer(
    id: 'd-tier-500',
    kind: OfferKind.giftTier,
    name: 'Spend 500',
    minCart: const Money(50000, _inr),
    gift: products.byId(8),
  ),
];

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

  void golden(
    String name,
    String file, {
    required Size size,
    bool dark = false,
    bool catalogView = false,
    int lines = 12,
  }) {
    testWidgets('$prefix$name', (tester) async {
      useRealShadows();
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = size;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final binding = await bootInWidgetTest(tester);
        AppTypography.useBundledFonts = true;
        Get.delete<ClockController>(force: true);
        Get.put<ClockController>(
          ClockController(now: () => DateTime(2026, 10, 7, 16, 57, 8)),
          permanent: true,
        );
        final products = Get.find<ProductsController>();
        final offers = Get.find<OffersController>();
        offers.offers.assignAll(_offers(products));
        offers.revision.value++;
        if (dark) {
          await tester.runAsync(
            () => Get.find<SettingsController>().setDark(true),
          );
        }
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        await settleImages(tester);
        final actions = Get.find<CartActionsController>();
        for (final id in <int>[
          7,
          7,
          0,
          1,
          2,
          3,
          4,
          6,
          9,
          10,
          11,
          12,
        ].take(lines)) {
          actions.add(products.byId(id)!);
        }
        if (catalogView && lines > 0) {
          Get.find<PosWorkViewController>().toggle();
        }
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        Get.find<ToastController>().toasts.clear();
        await tester.pumpAndSettle();
        await settleImages(tester);
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

  for (final dark in <bool>[false, true]) {
    final mode = dark ? 'dark' : 'light';
    golden(
      'Cart view 1280x720 ($mode)',
      'cart_density_1280_cart_$mode',
      size: const Size(1280, 720),
      dark: dark,
    );
    golden(
      'Cart view 1868x1035 ($mode)',
      'cart_density_1868_cart_$mode',
      size: const Size(1868, 1035),
      dark: dark,
    );
  }
  golden(
    'Cart view 950x733 (light)',
    'cart_density_950_cart_light',
    size: const Size(950, 733),
  );
  golden(
    'Catalog view with 12 items 1280x720 (light)',
    'cart_density_1280_catalog_light',
    size: const Size(1280, 720),
    catalogView: true,
  );
  golden(
    'Catalog view with 12 items 1868x1035 (light)',
    'cart_density_1868_catalog_light',
    size: const Size(1868, 1035),
    catalogView: true,
  );
  golden(
    'Catalog view, empty cart 1280x720 (light)',
    'cart_density_1280_catalog_empty_light',
    size: const Size(1280, 720),
    lines: 0,
  );
}
