// Sales and Reports across window sizes (smaller sweep: widths 900, 1100,
// 1280, 1500, 1900 x heights 600, 733, 900, 1000): nothing outside the panel,
// header and cells aligned, tile and bar gaps and paddings, long names and
// huge amounts stay inside their cells. VM tests.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/responsive/app_metrics.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/theme/tokens/app_management_sizes.dart';
import 'package:pos_application/modules/reports/widgets/report_bar.dart';
import 'package:pos_application/modules/reports/widgets/report_stat.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/widgets/app_data_table.dart';
import 'package:pos_application/shared/widgets/app_panel.dart';
import 'package:pos_application/shared/widgets/management_page.dart';

import '../../support/layout_matrix.dart';
import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

Rect _r(WidgetTester t, Finder f) => t.getRect(f);

final Finder _panel = find
    .descendant(
      of: find.byType(ManagementPage),
      matching: find.byType(AppPanel),
    )
    .first;

void main() {
  useTestApp();

  for (final w in smallWidths) {
    for (final h in smallHeights) {
      final size = Size(w, h);
      testWidgets('Sales and Reports at ${w.toInt()} x ${h.toInt()}', (
        tester,
      ) async {
        useLogicalViewport(tester, size);
        final binding = await bootInWidgetTest(tester);
        await tester.pumpWidget(testApp(binding));
        await tester.pumpAndSettle();
        final pad = AppMetrics(size).managementPad;
        final now = DateTime.now();
        Get.find<SalesController>().sales.addAll(
          <dynamic>[
            testSale(number: 'AX000001', at: now, mode: 'Credit'),
            testSale(number: 'AX000002', at: now, totalMinor: 12345),
            testSale(
              number: 'AX000003',
              at: now,
              customer:
                  'Venkata Subramanian Krishnamurthy Iyer and Sons Trading '
                  'Company Private Limited',
              mode: 'Card',
              totalMinor: 99999999999,
            ),
          ].cast(),
        );

        // ---- Sales ----
        Get.offAllNamed<void>(AppRoutes.sales);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'sales $size');
        final panel = _r(tester, _panel);
        final table = find.byType(AppDataTable);
        final headerBox = _r(
          tester,
          find
              .ancestor(
                of: find.descendant(of: table, matching: find.text('Bill')),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(headerBox.left - panel.left, closeTo(pad, 0.6), reason: '$size');
        expect(
          panel.right - headerBox.right,
          closeTo(pad, 0.6),
          reason: '$size',
        );
        var previous = -1.0;
        for (final head in <String>[
          'Bill',
          'Date',
          'Customer',
          'Mode',
          'Total',
        ]) {
          final r = _r(
            tester,
            find.descendant(of: table, matching: find.text(head)),
          );
          expect(
            r.left,
            greaterThanOrEqualTo(previous - 0.5),
            reason: '$head $size',
          );
          expect(
            r.top - headerBox.top,
            greaterThanOrEqualTo(AppManagementSizes.thPadY - 0.5),
            reason: '$head $size',
          );
          previous = r.right;
        }
        // The first row's cell starts under its header, with the row padding.
        final bill = _r(tester, find.text('AX000003'));
        expect(
          bill.left,
          closeTo(
            _r(
              tester,
              find.descendant(of: table, matching: find.text('Bill')),
            ).left,
            0.6,
          ),
          reason: 'column 1 $size',
        );
        expect(
          bill.top - headerBox.bottom,
          greaterThanOrEqualTo(AppManagementSizes.tdPadY - 0.5),
          reason: 'row pad $size',
        );
        // The huge total stays inside the panel and clear of "View receipt".
        final big = _r(tester, find.text('₹99,99,99,999.99'));
        expect(big.right, lessThanOrEqualTo(panel.right - pad + 0.5));
        // "View receipt" starts right of the total in the same row.
        expect(
          _r(tester, find.text('View receipt').first).left,
          greaterThanOrEqualTo(big.right - 0.5),
          reason: 'receipt link $size',
        );

        // ---- Reports ----
        Get.offAllNamed<void>(AppRoutes.reports);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'reports $size');
        final rp = _r(tester, _panel);
        final tiles = <Rect>[
          for (final e in tester.elementList(find.byType(ReportStat)))
            tester.getRect(find.byWidget(e.widget)),
        ];
        expect(tiles, hasLength(3));
        expect(tiles.first.left - rp.left, closeTo(pad, 0.6), reason: '$size');
        expect(rp.right - tiles.last.right, closeTo(pad, 0.6), reason: '$size');
        for (var i = 1; i < 3; i++) {
          expect(
            tiles[i].left - tiles[i - 1].right,
            closeTo(AppManagementSizes.reportStatsGap, 0.6),
            reason: 'tile gap $size',
          );
          expect(tiles[i].width, closeTo(tiles[0].width, 0.6));
          expect(tiles[i].height, closeTo(tiles[0].height, 0.6));
        }
        // Label and value keep the tile padding.
        for (final text in <String>[
          "Today's sales",
          'Bills completed',
          'Average bill',
          '₹1,00,00,00,223.44',
        ]) {
          final f = find.descendant(
            of: find.byType(ReportStat),
            matching: find.text(text),
          );
          if (f.evaluate().isEmpty) continue;
          final r = _r(tester, f.first);
          final tile = tiles.firstWhere((t) => t.contains(r.center));
          expect(
            r.left - tile.left,
            greaterThanOrEqualTo(AppManagementSizes.reportTilePadX - 0.5),
            reason: '$text $size',
          );
          expect(
            tile.right - r.right,
            greaterThanOrEqualTo(AppManagementSizes.reportTilePadX - 0.5),
            reason: '$text $size',
          );
          expect(
            r.top - tile.top,
            greaterThanOrEqualTo(AppManagementSizes.reportTilePadY - 0.5),
            reason: '$text $size',
          );
        }
        // The three bars: same x for tracks, the gap 20 either side of the
        // track, amounts right aligned to the panel padding.
        final bars = <Rect>[
          for (final e in tester.elementList(find.byType(ReportBar)))
            tester.getRect(find.byWidget(e.widget)),
        ];
        expect(bars, hasLength(3));
        for (var i = 1; i < 3; i++) {
          expect(
            bars[i].top - bars[i - 1].bottom,
            closeTo(AppManagementSizes.chartRowMarginY, 0.6),
            reason: 'bar spacing $size',
          );
        }
        for (final bar in bars) {
          expect(bar.right, closeTo(rp.right - pad, 0.6), reason: '$size');
          expect(bar.height, closeTo(AppManagementSizes.chartTrackHeight, 0.6));
        }
        final footer = _r(tester, find.textContaining('Based on completed'));
        expect(
          footer.top - bars.last.bottom,
          greaterThanOrEqualTo(AppManagementSizes.chartMarginY - 0.5),
          reason: 'footer $size',
        );
        // At 600 high the page scrolls (the footer is below the fold).
        if (h >= 733) {
          expect(footer.bottom, lessThanOrEqualTo(rp.bottom - pad + 0.5));
        }
      });
    }
  }
}
