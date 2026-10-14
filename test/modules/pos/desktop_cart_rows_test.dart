// Compact cart rows of the desktop layout: offers (discount, Buy 1 Get 1, a
// locked and an unlocked free item), selection and Delete, the stepper, the
// remove button, and the column alignment of head and rows.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_gift_row.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_head.dart';
import 'package:pos_application/modules/pos/widgets/cart_compact_row.dart';
import 'package:pos_application/modules/pos/widgets/desktop_cart_column.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _inr = CurrencyRegistry.inr;

List<Offer> _offers(ProductsController products) => <Offer>[
  const Offer(
    id: 'r-cola',
    kind: OfferKind.discount,
    name: 'Cola 20% off',
    productId: 0,
    percent: Bp(2000),
  ),
  const Offer(
    id: 'r-oreo',
    kind: OfferKind.promotion,
    name: 'Oreo Buy 1 Get 1',
    productId: 7,
    percent: Bp(5000),
  ),
  Offer(
    id: 'r-tier-100',
    kind: OfferKind.giftTier,
    name: 'Spend 100',
    minCart: const Money(10000, _inr),
    gift: products.byId(5),
  ),
  Offer(
    id: 'r-tier-500',
    kind: OfferKind.giftTier,
    name: 'Spend 500',
    minCart: const Money(50000, _inr),
    gift: products.byId(8),
  ),
];

Future<void> _boot(WidgetTester tester, Size size) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  final offers = Get.find<OffersController>();
  offers.offers.assignAll(_offers(Get.find<ProductsController>()));
  offers.revision.value++;
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
}

Future<void> _add(WidgetTester tester, int id) async {
  Get.find<CartActionsController>().add(
    Get.find<ProductsController>().byId(id)!,
  );
  await tester.pump();
  // The first add moves the layout to the cart view (180 ms).
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _drain(WidgetTester tester) async {
  Get.find<ToastController>().toasts.clear();
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('offer lines and the free items are 48 px rows with their '
      'texts', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester, const Size(1868, 1035));
      await _add(tester, 7);
      await _add(tester, 7);
      await _add(tester, 0);
      final tata = Get.find<ProductsController>().products.firstWhere(
        (p) => p.price.minor >= 10000 && p.id != 8 && p.id != 5,
      );
      await _add(tester, tata.id);
      final cart = find.byType(DesktopCartColumn);
      Finder inCart(Finder f) => find.descendant(of: cart, matching: f);
      expect(
        inCart(find.textContaining('Oreo Buy 1 Get 1 · saved')),
        findsOneWidget,
      );
      expect(
        inCart(find.textContaining('Cola 20% off · saved')),
        findsOneWidget,
      );
      // Lays is the free item of the 100 tier (unlocked), Dairy Milk of the
      // 500 tier (locked).
      final gifts = find.byType(CartCompactGiftRow);
      expect(gifts, findsNWidgets(2));
      expect(inCart(find.textContaining('Free gift')), findsOneWidget);
      expect(inCart(find.textContaining('more to unlock')), findsOneWidget);
      expect(inCart(find.text('FREE')), findsOneWidget);
      for (final w in gifts.evaluate()) {
        expect(tester.getSize(find.byWidget(w.widget)).height, 48);
      }
      for (final w in find.byType(CartCompactRow).evaluate()) {
        expect(tester.getSize(find.byWidget(w.widget)).height, 48);
      }
      // Gift rows have no remove button: 3 lines, 3 buttons.
      expect(find.byTooltip('Remove item'), findsNWidgets(3));
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the head and the rows share their column positions; the '
      'total is never ellipsized', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester, const Size(1280, 720));
      await _add(tester, 3);
      final head = find.byType(CartCompactHead);
      double right(Finder f) => tester.getTopRight(f).dx;
      final totalHead = find.descendant(of: head, matching: find.text('Total'));
      final totalCell = find.descendant(
        of: find.byType(CartCompactRow),
        matching: find.textContaining('₹'),
      );
      // Both are right aligned in the same column: same right edge.
      expect(
        tester.getRect(totalCell.first).right,
        closeTo(tester.getRect(totalHead).right, 0.5),
      );
      final text = tester.widget<Text>(totalCell.first);
      expect(text.overflow, isNot(TextOverflow.ellipsis));
      expect(right(totalCell.first), greaterThan(0));
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('select a row, Delete removes it; the stepper and the remove '
      'button change the line', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester, const Size(1280, 720));
      await _add(tester, 3);
      await _add(tester, 4);
      final cart = Get.find<CartController>();
      expect(cart.cart.value.lines, hasLength(2));
      // Increase through the stepper (tap = one step).
      await tester.tap(find.byTooltip('Increase quantity').first);
      await tester.pumpAndSettle();
      expect(cart.cart.value.lines.first.qty.milli, 2000);
      // Select the second row, then Delete removes exactly it.
      await tester.tapAt(
        tester.getCenter(find.byType(CartCompactRow).last) +
            const Offset(40, 0),
      );
      await tester.pump();
      FocusManager.instance.primaryFocus?.unfocus(); // Delete ignores inputs
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();
      expect(cart.cart.value.lines, hasLength(1));
      // The remove button removes the last line.
      await tester.tap(find.byTooltip('Remove item').first);
      await tester.pumpAndSettle();
      expect(cart.cart.value.lines, isEmpty);
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('narrow cart (panel open at 950 px): no thumbnail, no barcode, '
      'no overflow', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      await _boot(tester, const Size(950, 733));
      await _add(tester, 7);
      await _add(tester, 7);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('8901234560015'), findsNothing);
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
