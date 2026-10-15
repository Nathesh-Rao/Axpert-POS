// DEC-129: a refund is memory-first (toast at once) and then persisted as one
// unit; only a fully failed save shows `toastSaveFailed`.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/database/persist_outcome.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/returns/bindings/returns_binding.dart';
import 'package:pos_application/modules/returns/controllers/returns_controller.dart';
import 'package:pos_application/modules/returns/repository/return_repository.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/ledger_fixtures.dart';
import '../../support/test_app.dart';

class _FakeReturns implements ReturnRepository {
  final List<RefundCommit> commits = <RefundCommit>[];
  PersistOutcome outcome = PersistOutcome.saved;
  Object? error;

  @override
  Future<PersistOutcome> applyRefund(RefundCommit commit) async {
    commits.add(commit);
    final e = error;
    if (e != null) throw e;
    return outcome;
  }
}

const String _saveFailed = 'Could not save. The data is only in this session.';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

List<String> get _toasts => [
  for (final t in Get.find<ToastController>().toasts) t.text,
];

Future<(ReturnsController, _FakeReturns)> _boot() async {
  final fake = _FakeReturns();
  await bootTestApp();
  Get.put<ReturnRepository>(fake);
  ReturnsBinding().dependencies();
  Get.find<SalesController>().addInMemory(
    ledgerSale('AX000001', saleId: '11111111-1111-4111-8111-111111111111'),
  );
  final page = Get.find<ReturnsController>();
  page.onBillChanged('AX000001');
  page.onQtyChanged(const LineKey(1), '1');
  return (page, fake);
}

void main() {
  useTestApp();

  test('refund updates memory at once and commits both lists', () async {
    final (page, fake) = await _boot();
    final stock = Get.find<ProductsController>().byId(1)!.stock;

    page.refund();
    Get.find<OverlayController>().accept();
    await _settle();

    expect(Get.find<ProductsController>().byId(1)!.stock, stock + 1);
    expect(Get.find<SalesController>().sales.single.returned, {
      const LineKey(1): const Qty(1000),
    });
    final commit = fake.commits.single;
    expect(commit.request.saleNumber, 'AX000001');
    expect(commit.sales.single.returned, {const LineKey(1): const Qty(1000)});
    expect(commit.products.firstWhere((p) => p.id == 1).stock, stock + 1);
    expect(_toasts, isNot(contains(_saveFailed)));
  });

  test('a failed outcome or an exception shows the error toast', () async {
    for (final bad in <void Function(_FakeReturns)>[
      (f) => f.outcome = PersistOutcome.failed,
      (f) => f.error = StateError('boom'),
    ]) {
      final (page, fake) = await _boot();
      bad(fake);

      page.refund();
      Get.find<OverlayController>().accept();
      await _settle();
      await _settle();

      expect(_toasts.last, _saveFailed);
      expect(Get.find<ToastController>().toasts.last.kind, ToastKind.error);
    }
  });

  test('a fallback save is silent', () async {
    final (page, fake) = await _boot();
    fake.outcome = PersistOutcome.savedViaFallback;

    page.refund();
    Get.find<OverlayController>().accept();
    await _settle();
    await _settle();

    expect(_toasts, isNot(contains(_saveFailed)));
  });
}
