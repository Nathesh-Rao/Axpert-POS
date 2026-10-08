// The cart at several window widths: no overflow (flutter_test fails on any
// RenderFlex error), the name is not squeezed, and each layout shows what the
// media rules say. Runs on VM and Chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/widgets/cart_line_row.dart';
import 'package:pos_application/modules/pos/widgets/stat_tiles.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/widgets/action_button.dart';
import 'package:pos_application/shared/widgets/number_field.dart';
import 'package:pos_application/shared/widgets/product_image.dart';

import '../../support/test_app.dart';
import '../../support/viewport.dart';

const List<Size> _sizes = <Size>[
  Size(1868.44, 1034.67),
  Size(1701, 900),
  Size(1700, 900),
  Size(1440, 900),
  Size(1280, 800),
  Size(1101, 760),
  Size(1100, 700),
  Size(1000, 700),
];

Future<void> _boot(WidgetTester tester, Size size) async {
  useLogicalViewport(tester, size);
  final binding = await bootInWidgetTest(tester);
  await tester.pumpWidget(testApp(binding));
  await tester.pumpAndSettle();
  final products = Get.find<ProductsController>();
  for (final id in const <int>[5, 12, 1]) {
    Get.find<CartActionsController>().add(products.byId(id)!);
  }
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _finish(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  useTestApp();

  for (final size in _sizes) {
    testWidgets('cart at ${size.width.toInt()} x ${size.height.toInt()}', (
      tester,
    ) async {
      await _boot(tester, size);
      final m = AppMetrics(size);
      final row = find.byType(CartLineRow).first;
      expect(find.byType(CartLineRow), findsAtLeastNWidgets(2)); // lazy list

      // The name keeps a readable width and never wraps per character.
      final name = find.descendant(
        of: row,
        matching: find.text('Lays Classic 52g'),
      );
      final nameSize = tester.getSize(name);
      expect(nameSize.width, greaterThan(70), reason: 'name squeezed');
      expect(nameSize.height, lessThan(40), reason: 'name wrapped');

      // Barcode and image follow the media rules; GST always shows.
      expect(
        find.descendant(of: row, matching: find.text('8901234567895')),
        m.showLineBarcode ? findsOneWidget : findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.text('GST 5%')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byType(ProductImage)),
        m.showLineImage ? findsOneWidget : findsNothing,
      );

      // Stacked lines carry their own labels; wide lines rely on the header.
      expect(
        find.descendant(of: row, matching: find.text('Price')),
        m.lineStacked ? findsOneWidget : findsNothing,
      );
      expect(
        find.descendant(of: row, matching: find.text('Disc %')),
        m.lineStacked ? findsOneWidget : findsNothing,
      );

      // Price and discount boxes have the layout's height.
      final box = tester.getSize(
        find.descendant(of: row, matching: find.byType(NumberField)).first,
      );
      expect(box.height, m.lineEditHeight);
      expect(box.width, lessThanOrEqualTo(76.5));

      // Stat tiles: icons hide at width <= 1100.
      expect(
        find.descendant(
          of: find.byType(StatTiles),
          matching: find.byType(Icon),
        ),
        m.showStatTileIcon ? findsNWidgets(3) : findsNothing,
      );

      // Cart actions: icon above the label when stacked, beside it otherwise.
      final label = tester.getCenter(find.text('Clear Cart'));
      final icon = tester.getCenter(
        find
            .descendant(
              of: find.ancestor(
                of: find.text('Clear Cart'),
                matching: find.byType(ActionButton),
              ),
              matching: find.byType(Icon),
            )
            .first,
      );
      if (m.cartActionsStacked) {
        expect(icon.dy, lessThan(label.dy - 8));
        expect((icon.dx - label.dx).abs(), lessThan(1));
      } else {
        expect(icon.dx, lessThan(label.dx));
        expect((icon.dy - label.dy).abs(), lessThan(1));
      }

      // The clock moves to its own row at width <= 1280.
      final time = find.textContaining(RegExp(r'\d\d/\d\d/\d{4}'));
      final counter = find.text('C3');
      final sameRow =
          (tester.getCenter(time).dy - tester.getCenter(counter).dy).abs() < 6;
      expect(sameRow, !m.cartTimeOnOwnRow);

      await _finish(tester);
    });
  }

  testWidgets('wide layout: header cells sit over the row cells', (
    tester,
  ) async {
    await _boot(tester, _sizes.first);
    final row = find.byType(CartLineRow).first;
    double cx(Finder f) => tester.getCenter(f).dx;
    // The line has a 1 px border the header does not: allow 1.5 px.
    const tolerance = 1.5;
    expect(
      cx(find.text('Price')),
      closeTo(
        cx(find.descendant(of: row, matching: find.byType(NumberField)).at(0)),
        tolerance,
      ),
    );
    expect(
      cx(find.text('Disc %')),
      closeTo(
        cx(find.descendant(of: row, matching: find.byType(NumberField)).at(1)),
        tolerance,
      ),
    );
    final qtyControl = find
        .descendant(of: row, matching: find.byTooltip('Decrease quantity'))
        .first;
    // Qty header is centered over the 144 px control (minus button at its left).
    expect(
      cx(find.text('Qty')),
      closeTo(tester.getTopLeft(qtyControl).dx + 72, tolerance),
    );
    expect(
      tester.getTopLeft(find.text('Item')).dx,
      closeTo(
        tester
            .getTopLeft(
              find.descendant(of: row, matching: find.byType(ProductImage)),
            )
            .dx,
        tolerance,
      ),
    );
    await _finish(tester);
  });

  testWidgets('stacked layout: the header keeps its own columns', (
    tester,
  ) async {
    await _boot(tester, const Size(1440, 900));
    // `18 | 1.4fr | 1.3fr | .8fr | .8fr | 1fr | 0`, gap 4, padding 12: the
    // header cells are laid out by their own proportions, not the line's
    // (React does the same: the header does not line up with stacked lines).
    double cx(String t) => tester.getCenter(find.text(t).first).dx;
    expect(cx('Item'), lessThan(cx('Qty')));
    expect(cx('Qty'), lessThan(cx('Price')));
    expect(cx('Price'), lessThan(cx('Disc %')));
    expect(cx('Disc %'), lessThan(cx('Total')));
    final stacked = AppMetrics(const Size(1440, 900)).cartHeaderColumns;
    expect(stacked, same(CartHeaderColumns.stacked));
    final header = tester.getRect(
      find
          .ancestor(
            of: find.text('Item').first,
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    // Column widths: (W - 2*12 - 18 - 6*4) split 14:13:8:8:10 over 53.
    final fr = (header.width - 24 - 18 - 24) / 53;
    final itemLeft = header.left + 12 + 18 + 4;
    final qtyCenter = itemLeft + 14 * fr + 4 + 13 * fr / 2;
    expect(cx('Qty'), closeTo(qtyCenter, 1.5));
    await _finish(tester);
  });
}
