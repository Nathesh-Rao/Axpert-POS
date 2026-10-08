// Bill lookup on 10,000 sales: the number index is built once per ledger
// change, typing only reads it. Timing is printed for the report. VM test.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';

import '../../support/sale_fixtures.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

void main() {
  useTestApp();

  testWidgets('10,000 sales: open and look a bill up', (tester) async {
    useReferenceViewport(tester);
    final store = InMemoryLocalStore();
    store.write(StorageKeys.sales, <Map<String, dynamic>>[
      for (var i = 0; i < 10000; i++)
        testSale(
          number: 'AX${(i + 1).toString().padLeft(6, '0')}',
          at: DateTime(2026, 10, 8, 9),
        ).toJson(),
    ]);
    final binding = await tester.runAsync(() => bootTestApp(store: store));
    await tester.pumpWidget(testApp(binding!));
    await tester.pumpAndSettle();

    var sw = Stopwatch()..start();
    Get.offAllNamed<void>(AppRoutes.returns);
    await tester.pumpAndSettle();
    sw.stop();
    // ignore: avoid_print
    print(
      'PERF open Returns (10k sales, index built): ${sw.elapsedMilliseconds} ms',
    );
    final page = Get.find<ReturnsController>();

    sw = Stopwatch()..start();
    for (var i = 0; i < 200; i++) {
      page.onBillChanged(i.isEven ? 'ax009999' : 'AX000001');
    }
    sw.stop();
    // ignore: avoid_print
    print(
      'PERF lookup per keystroke: ${(sw.elapsedMicroseconds / 200 / 1000).toStringAsFixed(3)} ms (mean of 200)',
    );
    expect(page.sale.value?.number, 'AX000001');
    page.onBillChanged('AX010000');
    expect(page.sale.value?.number, 'AX010000');
    page.onBillChanged('AX010001');
    expect(page.sale.value, isNull);
    await tester.pumpAndSettle();
  });
}
