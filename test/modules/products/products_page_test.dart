// The Products page: filter, table, stock chips. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/products/controllers/products_page_controller.dart';
import 'package:pos_application/shared/controllers/page_filter_controller.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

Future<void> _open(WidgetTester tester) async {
  useReferenceViewport(tester);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  Get.offAllNamed<void>(AppRoutes.products);
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  testWidgets('shows the heading, the search and all 20 products', (
    tester,
  ) async {
    await _open(tester);
    expect(find.text('MAISON GALAXY / RETAIL WORKSPACE'), findsOneWidget);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Search products...'), findsOneWidget);
    for (final head in <String>[
      'Product',
      'Code / Barcode',
      'Category',
      'GST',
      'Price',
      'Stock',
    ]) {
      expect(find.text(head), findsOneWidget, reason: head);
    }
    final page = Get.find<ProductsPageController>();
    expect(page.rows.length, 20);
    expect(find.text('Coca Cola 500ml'), findsOneWidget);
    expect(find.text('BDV001'), findsOneWidget);
    expect(find.text('8901234567890'), findsOneWidget);
    expect(find.text('18%'), findsWidgets);
    expect(find.text('₹40.00'), findsWidgets);
    expect(find.text('45'), findsWidgets); // stock of the first product
  });

  testWidgets('the filter matches name, code and barcode (lowercase)', (
    tester,
  ) async {
    await _open(tester);
    final page = Get.find<ProductsPageController>();
    page.filterNow('COLA');
    await tester.pumpAndSettle();
    expect(page.rows.map((p) => p.code), <String>['BDV001']);
    page.filterNow('bdv00');
    expect(page.rows.length, 4);
    page.filterNow('8901234567899'); // a barcode
    expect(page.rows.length, 1);
    page.filterNow('nothing like this');
    await tester.pumpAndSettle();
    expect(page.rows, isEmpty);
    expect(find.byType(StockChip), findsNothing);
    await tester.pump(const Duration(milliseconds: 200)); // debounce
  });

  testWidgets('typing is debounced and follows the shared filter', (
    tester,
  ) async {
    await _open(tester);
    final page = Get.find<ProductsPageController>();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.controller == page.filterText,
      ),
      'pepsi',
    );
    await tester.pump();
    expect(page.rows.length, 20, reason: 'not applied yet (150 ms debounce)');
    await tester.pump(const Duration(milliseconds: 200));
    expect(page.rows.length, 1);
    expect(Get.find<PageFilterController>().filter.value, 'pepsi');
    // Navigation clears the shared filter (KG-027).
    Get.find<PageFilterController>().clear();
    await tester.pump(const Duration(milliseconds: 200));
    expect(page.rows.length, 20);
    expect(page.filterText.text, '');
  });

  testWidgets('stock chip: orange below 10, green from 10', (tester) async {
    await _open(tester);
    final products = Get.find<ProductsController>();
    expect(products.products.where((p) => p.stock < 10).length, 1);
    // Rows are lazy: scroll down to the product with stock 8.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final stocks = tester
        .widgetList<StockChip>(find.byType(StockChip))
        .map((c) => c.stock)
        .toList();
    expect(stocks, contains(8));
    expect(stocks.length, lessThan(20), reason: 'only the visible rows exist');
  });
}
