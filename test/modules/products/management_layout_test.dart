// Products and Customers across window sizes (smaller sweep: widths 900,
// 1100, 1280, 1500, 1900 x heights 600, 733, 900, 1000): nothing outside the
// panel, header and row cells aligned, cell paddings, long names wrap inside
// their cell, the heading and search gaps. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/theme/tokens/app_management_sizes.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/customers/models/customer.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/modules/products/models/product.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';
import 'package:pos_application/shared/widgets/management_page.dart';

import '../../support/layout_matrix.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const String _longName =
    'Extra Large Family Pack Roasted Salted Cashew Nuts With Himalayan Pink '
    'Salt and Black Pepper 1 kg Resealable Pouch Limited Edition';

Rect _r(WidgetTester t, Finder f) => t.getRect(f);

/// The page's own panel (the Bill Summary frame is a second `AppPanel`).
final Finder _panel = find
    .descendant(
      of: find.byType(ManagementPage),
      matching: find.byType(AppPanel),
    )
    .first;

/// Every header label starts where its column's first cell content starts,
/// both inset by the cell padding from the column edge.
void _expectTable(
  WidgetTester tester,
  Size size,
  List<String> heads,
  String firstCell,
  double pad,
) {
  final why = 'at $size';
  final panel = _r(tester, _panel);
  final table = find.byType(AppDataTable);
  Rect head(String h) =>
      _r(tester, find.descendant(of: table, matching: find.text(h)));
  final headRects = <Rect>[for (final h in heads) head(h)];
  // The header row is a `ColoredBox` of the secondary colour.
  final headerBox = _r(
    tester,
    find
        .ancestor(
          of: find.descendant(of: table, matching: find.text(heads.first)),
          matching: find.byType(ColoredBox),
        )
        .first,
  );
  expect(headerBox.left - panel.left, closeTo(pad, 0.6), reason: 'left $why');
  expect(
    panel.right - headerBox.right,
    closeTo(pad, 0.6),
    reason: 'right $why',
  );
  for (final r in headRects) {
    expect(
      r.top - headerBox.top,
      greaterThanOrEqualTo(AppManagementSizes.thPadY - 0.5),
      reason: why,
    );
    expect(
      headerBox.bottom - r.bottom,
      greaterThanOrEqualTo(AppManagementSizes.thPadY - 0.5),
      reason: why,
    );
    expect(
      r.right,
      lessThanOrEqualTo(headerBox.right - AppManagementSizes.cellPadX + 0.5),
      reason: why,
    );
  }
  // Header labels do not overlap each other.
  for (var i = 1; i < headRects.length; i++) {
    expect(
      headRects[i].left,
      greaterThanOrEqualTo(headRects[i - 1].right - 0.5),
      reason: 'heads $why',
    );
  }
  // The first row's first cell aligns with the first header label.
  final cell = _r(
    tester,
    find.descendant(of: table, matching: find.text(firstCell)).first,
  );
  expect(
    cell.left,
    closeTo(headRects.first.left, 0.6),
    reason: 'column 1 $why',
  );
  expect(
    cell.top - headerBox.bottom,
    greaterThanOrEqualTo(AppManagementSizes.tdPadY - 0.5),
    reason: 'row pad $why',
  );
}

void main() {
  useTestApp();

  for (final w in smallWidths) {
    for (final h in smallHeights) {
      final size = Size(w, h);
      testWidgets('Products and Customers at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final pad = AppMetrics(size).managementPad;

        // A product with a very long name and a customer with a long email.
        final products = Get.find<ProductsController>();
        products.products.insert(
          0,
          const Product(
            id: 999,
            name: _longName,
            code: 'LONG001',
            barcode: '8909999999999',
            price: Money(123456789, CurrencyRegistry.inr),
            category: 'Personal Care',
            sub: 'Hair Care',
            stock: 9,
            gst: Bp(1800),
            image: -1,
            favourite: false,
          ),
        );
        Get.find<CustomersController>().customers.insert(
          1,
          const Customer(
            id: 'long',
            name: 'Venkata Subramanian Krishnamurthy Iyer',
            phone: '+91 98450 11111',
            email: 'venkata.subramanian.krishnamurthy.iyer@example-company.in',
            member: 'MG99999',
            points: 123456,
          ),
        );
        await tester.pump();

        // ---- Products ----
        Get.offAllNamed<void>(AppRoutes.products);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'products $size');
        _expectTable(
          tester,
          size,
          <String>[
            'Product',
            'Code / Barcode',
            'Category',
            'GST',
            'Price',
            'Stock',
          ],
          _longName,
          pad,
        );
        // The long name wraps inside its column: its right edge stays left of
        // the code column's text.
        final name = _r(tester, find.text(_longName));
        final code = _r(tester, find.text('LONG001'));
        expect(
          name.right,
          lessThanOrEqualTo(code.left + 0.5),
          reason: 'name / code $size',
        );
        // Heading, search and table order and gaps.
        final title = _r(
          tester,
          find
              .descendant(
                of: find.byType(ManagementPage),
                matching: find.text('Products'),
              )
              .first,
        );
        final search = _r(tester, find.byType(ManagementSearch));
        final headerTop = _r(
          tester,
          find.descendant(
            of: find.byType(AppDataTable),
            matching: find.text('Product'),
          ),
        ).top;
        expect(
          search.top - title.bottom,
          greaterThanOrEqualTo(AppManagementSizes.headingMarginBottom - 0.5),
          reason: size.toString(),
        );
        expect(
          search.width,
          lessThanOrEqualTo(AppManagementSizes.searchMaxWidth + 0.5),
        );
        expect(
          headerTop - search.bottom,
          greaterThanOrEqualTo(AppManagementSizes.searchMarginBottom - 0.5),
          reason: size.toString(),
        );
        // The stock chip keeps its padding (stock 9 is the low one).
        final chipText = _r(tester, find.text('9'));
        final chipBox = _r(
          tester,
          find
              .ancestor(of: find.text('9'), matching: find.byType(DecoratedBox))
              .first,
        );
        expect(
          chipText.left - chipBox.left,
          greaterThanOrEqualTo(AppManagementSizes.chipPadX - 0.5),
        );
        expect(
          chipText.top - chipBox.top,
          greaterThanOrEqualTo(AppManagementSizes.chipPadY - 0.5),
        );

        // ---- Customers ----
        Get.offAllNamed<void>(AppRoutes.customers);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'customers $size');
        _expectTable(
          tester,
          size,
          <String>['Name', 'Phone', 'Email', 'Membership', 'Points'],
          'Walk-in Customer',
          pad,
        );
        // A long email stays on one line, cut with an ellipsis, left of the
        // next column (it never breaks inside the word).
        const longEmail =
            'venkata.subramanian.krishnamurthy.iyer@example-company.in';
        final email = _r(tester, find.text(longEmail));
        final member = _r(
          tester,
          find.descendant(
            of: find.byType(AppDataTable),
            matching: find.text('Membership'),
          ),
        );
        expect(email.height, lessThan(30), reason: 'one line $size');
        expect(
          email.right,
          lessThanOrEqualTo(member.left - AppManagementSizes.cellPadX + 0.6),
          reason: 'email inside its column $size',
        );
        expect(
          find.byTooltip(longEmail),
          findsOneWidget,
          reason: 'the full email is in the tooltip',
        );
        final heading = _r(
          tester,
          find
              .descendant(
                of: find.byType(ManagementPage),
                matching: find.text('Customers'),
              )
              .first,
        );
        final button = _r(tester, find.text('Add Customer'));
        expect(
          button.left,
          greaterThanOrEqualTo(heading.right - 0.5),
          reason: 'button beside title $size',
        );
        final panel = _r(tester, _panel);
        expect(
          panel.right - button.right,
          greaterThanOrEqualTo(pad - 0.5),
          reason: 'button inside padding $size',
        );
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      });
    }
  }
}
