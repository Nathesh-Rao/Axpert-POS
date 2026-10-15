// DEC-152: the product form, the packaging preview and the role gate.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/features/products/presentation/controllers/product_admin_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/product_form_controller.dart';
import 'package:pos_application/features/products/domain/entities/product_admin_entities.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/stock_adjust_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/viewport.dart';

Future<void> _open(WidgetTester tester, String role) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester, session: roleSession(role));
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.offAllNamed<void>(AppRoutes.products);
  await tester.pumpAndSettle();
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  group('role gate', () {
    for (final role in <String>['admin', 'manager']) {
      testWidgets('$role sees add, edit and deactivate', (tester) async {
        await _open(tester, role);
        expect(find.text('Add product'), findsOneWidget);
        expect(find.text('Edit'), findsWidgets);
        expect(find.text('Deactivate'), findsWidgets);
        expect(find.text('Show inactive'), findsOneWidget);
      });
    }

    testWidgets('a cashier sees the plain table', (tester) async {
      await _open(tester, 'cashier');
      expect(find.text('Add product'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Deactivate'), findsNothing);
      expect(find.text('Actions'), findsNothing);
    });

    testWidgets('the controller re-checks the role before writing', (
      tester,
    ) async {
      await _open(tester, 'cashier');
      final admin = Get.find<ProductAdminController>();
      expect(admin.canManage, isFalse);
      admin.openAdd();
      await _settle(tester);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      expect(Get.isRegistered<ProductFormController>(), isFalse);
      final before = Get.find<ProductsController>().products.length;
      await tester.runAsync(
        () => admin.deactivate(Get.find<ProductsController>().products.first),
      );
      expect(admin.inactive, isEmpty);
      await tester.pump(const Duration(seconds: 6)); // the toast
      expect(Get.find<ProductsController>().products.length, before);
    });

    testWidgets('Ctrl+I opens the form for an admin, not for a cashier', (
      tester,
    ) async {
      await _open(tester, 'cashier');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _settle(tester);
      expect(Get.find<OverlayController>().isOpen, isFalse);
    });

    testWidgets('Ctrl+I and Cmd+I open the form for an admin', (tester) async {
      await _open(tester, 'admin');
      for (final key in <LogicalKeyboardKey>[
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.metaLeft,
      ]) {
        await tester.sendKeyDownEvent(key);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
        await tester.sendKeyUpEvent(key);
        await _settle(tester);
        expect(Get.find<OverlayController>().modal.value, 'productForm');
        Get.find<ProductFormController>().close();
        await _settle(tester);
      }
    });
  });

  group('form', () {
    testWidgets('creates a product with a carton and opening stock', (
      tester,
    ) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      expect(find.text('Name'), findsOneWidget);
      final form = Get.find<ProductFormController>();
      form.name.text = 'Test Cola';
      form.sku.text = 'TST001';
      form.gstBp.value = form.taxRates.first;
      form.price.text = '100';
      form.addPackaging();
      final row = form.packagings.single;
      row.factor.text = '24';
      await _settle(tester);
      // The live preview, derived from the base price.
      expect(form.previewOf(row)!.text, '1 Pack = 24 Piece = ₹2,400.00');
      expect(form.previewOf(row)!.derived, isTrue);
      expect(find.textContaining('1 Pack = 24 Piece = ₹2,400.00'), findsOne);
      row.price.text = '2200';
      await _settle(tester);
      expect(form.previewOf(row)!.text, '1 Pack = 24 Piece = ₹2,200.00');
      expect(form.previewOf(row)!.derived, isFalse);
      row.stockCount.text = '3';
      form.stockBase.text = '5';
      await _settle(tester);
      expect(form.stockTotalText(), '= 77 Piece');
      final ok = await tester.runAsync(form.submit);
      await _settle(tester);
      expect(ok, isTrue);
      final created = Get.find<ProductsController>().products.last;
      expect(created.name, 'Test Cola');
      expect(created.stock, 77);
      expect(Get.find<OverlayController>().isOpen, isFalse);
    });

    testWidgets('shows a message under each invalid field', (tester) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      form.price.text = '-';
      form.addPackaging();
      await _settle(tester);
      final ok = await tester.runAsync(form.submit);
      await _settle(tester);
      expect(ok, isFalse);
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter a SKU'), findsOneWidget);
      expect(find.text('Enter a price of 0 or more'), findsOneWidget);
      expect(find.text('Enter a quantity above 0'), findsOneWidget);
      expect(Get.find<OverlayController>().isOpen, isTrue);
    });

    testWidgets('the tax slab is a required choice with nothing preselected', (
      tester,
    ) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      expect(form.gstBp.value, isNull);
      expect(find.text('Select rate'), findsOneWidget);
      form.name.text = 'Slabless';
      form.sku.text = 'SL1';
      form.price.text = '10';
      expect(await tester.runAsync(form.submit), isFalse);
      await _settle(tester);
      expect(find.text('Choose a rate'), findsOneWidget);
      form.gstBp.value = form.taxRates.first;
      await _settle(tester);
      expect(find.text('Select rate'), findsNothing);
      expect(await tester.runAsync(form.submit), isTrue);
    });

    testWidgets('the same unit twice and a repeated barcode are refused', (
      tester,
    ) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      form.name.text = 'X';
      form.sku.text = 'X1';
      form.gstBp.value = form.taxRates.first;
      form.price.text = '10';
      form.addPackaging();
      form.addPackaging();
      form.packagings[0].factor.text = '6';
      form.packagings[1].factor.text = '12';
      form.packagings[1].unitId.value = form.packagings[0].unitId.value;
      form.barcodes.addAll(<String>['111', '111']);
      final ok = await tester.runAsync(form.submit);
      await _settle(tester);
      expect(ok, isFalse);
      expect(find.text('This unit is already used'), findsOneWidget);
      expect(find.text('Barcode 111 is entered twice'), findsOneWidget);
    });

    testWidgets('Esc cancels and Enter in a box saves', (tester) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      form.name.text = 'Enter Product';
      form.sku.text = 'ENT1';
      form.gstBp.value = form.taxRates.first;
      form.price.text = '5';
      await tester.tap(
        find.byWidgetPredicate(
          (w) => w is EditableText && w.controller == form.name,
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 6)); // the toast
      expect(
        Get.find<ProductsController>().products.any(
          (p) => p.name == 'Enter Product',
        ),
        isTrue,
      );
    });

    testWidgets('edit shows the current stock and a deactivated product '
        'leaves the catalog and comes back', (tester) async {
      await _open(tester, 'admin');
      final products = Get.find<ProductsController>();
      final admin = Get.find<ProductAdminController>();
      // The mock admin only knows products created through it.
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      form.name.text = 'Edit Me';
      form.sku.text = 'ED1';
      form.gstBp.value = form.taxRates.first;
      form.price.text = '20';
      form.stockBase.text = '9';
      await tester.runAsync(form.submit);
      await _settle(tester);
      final p = products.products.last;
      admin.openEdit(p);
      await _settle(tester);
      expect(find.text('Edit product'), findsOneWidget);
      expect(find.text('9 Piece'), findsOneWidget);
      Get.find<ProductFormController>().close();
      await _settle(tester);
      await tester.runAsync(() => admin.deactivate(p));
      await _settle(tester);
      expect(products.products.any((x) => x.id == p.id), isFalse);
      expect(admin.inactive.any((x) => x.id == p.id), isTrue);
      await tester.runAsync(() => admin.reactivate(p));
      await _settle(tester);
      expect(products.products.any((x) => x.id == p.id), isTrue);
    });
  });

  group('stock dialog', () {
    testWidgets('adjusts through the ledger path and returns to the form', (
      tester,
    ) async {
      await _open(tester, 'admin');
      await tester.tap(find.text('Add product'));
      await _settle(tester);
      final form = Get.find<ProductFormController>();
      form.name.text = 'Counted';
      form.sku.text = 'CNT1';
      form.gstBp.value = form.taxRates.first;
      form.price.text = '10';
      form.stockBase.text = '10';
      await tester.runAsync(form.submit);
      await _settle(tester);
      final product = Get.find<ProductsController>().products.last;
      final admin = Get.find<ProductAdminController>();
      admin.openEdit(product);
      await _settle(tester);
      await tester.tap(find.text('Adjust stock').first);
      await _settle(tester);
      expect(Get.find<OverlayController>().modal.value, 'adjustStock');
      final adjust = Get.find<StockAdjustController>();
      adjust.base.text = '4';
      adjust.reason.value = AdjustmentReason.other;
      await _settle(tester);
      expect(find.text('Change: -6 Piece'), findsOneWidget);
      // "Other" needs a note.
      expect(await tester.runAsync(adjust.submit), isFalse);
      await _settle(tester);
      expect(find.text('Add a note for this reason'), findsOneWidget);
      adjust.note.text = 'recount';
      expect(await tester.runAsync(adjust.submit), isTrue);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 6)); // the toast
      expect(Get.find<OverlayController>().modal.value, 'productForm');
      expect(Get.find<ProductsController>().byId(product.id)!.stock, 4);
      expect(find.text('4 Piece'), findsOneWidget);
    });
  });

  for (final touch in <bool>[false, true]) {
    testWidgets('form and stock dialogs raise no error '
        '(${touch ? 'touch' : 'desktop'} layout)', (tester) async {
      debugDefaultTargetPlatformOverride = touch
          ? TargetPlatform.android
          : TargetPlatform.macOS;
      await _open(tester, 'admin');
      final admin = Get.find<ProductAdminController>();
      admin.openAdd();
      await _settle(tester);
      Get.find<ProductFormController>().addPackaging();
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(RxInterface.proxy, isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(Get.find<OverlayController>().isOpen, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
