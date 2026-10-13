// The Total Value tile and "Flat amount" follow the active currency (no
// hardcoded rupee): INR keeps the Lucide rupee glyph, a currency without a
// glyph (UGX) shows its own symbol from the currencies row.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/theme/tokens/app_icons.dart';
import 'package:pos_application/features/products/domain/entities/product.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/session/presentation/controllers/active_session.dart';
import 'package:pos_application/modules/pos/controllers/discount_form_controller.dart';
import 'package:pos_application/modules/pos/widgets/stat_tiles.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/test_tax.dart';
import '../../support/viewport.dart';

ActiveSession _ugxSession() => ActiveSession.fixed(
  user: testUser,
  store: const StoreInfo(
    id: 'kampala',
    name: 'Axpert Mart - Kampala',
    currencyCode: 'UGX',
    region: 'UG',
  ),
  counter: const CounterInfo(id: 'k1', storeId: 'kampala', name: 'K1'),
  access: const <StoreAccess>[],
  quickCash: const <String, List<int>>{
    'UGX': <int>[5000, 20000],
  },
  regime: testVatRegime,
);

Finder _glyph(IconData icon) => find.descendant(
  of: find.byType(StatTiles),
  matching: find.byWidgetPredicate((w) => w is Icon && w.icon == icon),
);

void main() {
  useTestApp();

  testWidgets('INR: the Total Value tile keeps the rupee glyph', (
    tester,
  ) async {
    useReferenceViewport(tester);
    final binding = await bootInWidgetTest(tester);
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(5)!,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_glyph(AppIcons.indianRupee), findsOneWidget);
    expect(
      find.descendant(of: find.byType(StatTiles), matching: find.text('₹')),
      findsNothing,
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });

  testWidgets('UGX: the tile shows USh as text, no rupee, "Flat amount USh"', (
    tester,
  ) async {
    useReferenceViewport(tester);
    final binding = await bootInWidgetTest(tester, session: _ugxSession());
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    Get.find<CartController>().addItem(
      const Product(
        id: 900,
        name: 'Soda',
        code: 'S1',
        barcode: 'B1',
        price: Money(1800, CurrencyRegistry.ugx),
        category: 'c',
        sub: 's',
        stock: 10,
        gst: Bp(1800),
        image: -1,
        favourite: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(_glyph(AppIcons.indianRupee), findsNothing);
    expect(
      find.descendant(of: find.byType(StatTiles), matching: find.text('USh')),
      findsOneWidget,
    );
    expect(Get.find<DiscountFormController>().currencySymbol.trim(), 'USh');
    Get.find<DiscountFormController>().open();
    await tester.pumpAndSettle();
    expect(find.text('Flat amount USh'), findsOneWidget);
    expect(find.text('Flat amount ₹'), findsNothing);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  });
}
