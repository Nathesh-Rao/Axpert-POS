// DEC-129: the checkout is memory-first (option b2, default) or waits for the
// commit before the receipt (option b1); both are one switch and both are
// tested. A fully failed commit shows `toastSaveFailed`; nothing else does.
import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/config/app_config.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/persist_outcome.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/payment/domain/entities/payment_request.dart';
import 'package:pos_application/features/payment/domain/entities/payment_result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_status.dart';
import 'package:pos_application/features/payment/domain/services/payment_service.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/customers/controllers/customers_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_meta_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/cart.dart' show SaleType;
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/pos/repository/checkout_repository.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';
import '../../support/test_infrastructure.dart';

/// Records commits; each one waits for [gate] (when set) and answers [outcome].
class _FakeCheckout implements CheckoutRepository {
  final List<CheckoutCommit> commits = <CheckoutCommit>[];
  Completer<void>? gate;
  PersistOutcome outcome = PersistOutcome.saved;
  Object? error;

  @override
  Future<PersistOutcome> commit(CheckoutCommit commit) async {
    commits.add(commit);
    await gate?.future;
    final e = error;
    if (e != null) throw e;
    return outcome;
  }
}

class _DecliningPayments implements PaymentService {
  @override
  Future<Result<PaymentResult>> process(PaymentRequest request) async =>
      Result.success(
        PaymentResult(
          paymentId: request.paymentId,
          saleId: request.saleId,
          amount: request.amount,
          method: request.method,
          status: PaymentStatus.failed,
        ),
      );
}

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

const String _saveFailed = 'Could not save. The data is only in this session.';

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<PaymentController> _cashSale() async {
  Get.find<CartActionsController>().add(
    Get.find<ProductsController>().byId(5)!,
  );
  final pay = Get.find<PaymentController>();
  pay.payment(PaymentMode.cash);
  return pay;
}

bool get _receiptOpen => Get.find<OverlayController>().modal.value == 'receipt';

List<String> get _toastTexts => [
  for (final t in Get.find<ToastController>().toasts) t.text,
];

void main() {
  useTestApp();

  group('b2: memory first (default)', () {
    test(
      'receipt, cart clear and memory update do not wait for the commit',
      () async {
        final fake = _FakeCheckout()..gate = Completer<void>();
        await bootTestApp(checkout: fake);
        final stock = Get.find<ProductsController>().byId(5)!.stock;
        final pay = await _cashSale();

        pay.completeCash();
        await _settle();

        expect(fake.commits, hasLength(1), reason: 'the commit started');
        expect(_receiptOpen, isTrue);
        expect(Get.find<CartController>().isActive, isFalse);
        expect(Get.find<SalesController>().sales, hasLength(1));
        expect(Get.find<ProductsController>().byId(5)!.stock, stock - 1);
        expect(_toastTexts, contains('Payment completed'));

        fake.gate!.complete();
        await _settle();
        expect(_toastTexts, isNot(contains(_saveFailed)));
      },
    );

    test(
      'the commit carries the sale, the payment and the three lists',
      () async {
        final fake = _FakeCheckout();
        await bootTestApp(checkout: fake);
        Get.find<CartMetaController>().setCustomer('2');
        final pay = await _cashSale();

        pay.completeCash();
        await _settle();

        final c = fake.commits.single;
        expect(c.sale, Get.find<SalesController>().sales.single);
        expect(c.payment, isNotNull);
        expect(c.payment!.saleId, c.sale.saleId);
        expect(c.salesAfter, [c.sale]);
        expect(
          c.productsAfter.firstWhere((p) => p.id == 5).stock,
          Get.find<ProductsController>().byId(5)!.stock,
        );
        expect(c.customersAfter, Get.find<CustomersController>().customers);
      },
    );

    test('a failed outcome shows the error toast, the sale stays', () async {
      final fake = _FakeCheckout()..outcome = PersistOutcome.failed;
      await bootTestApp(checkout: fake);
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();
      await _settle();

      expect(_toastTexts.last, _saveFailed);
      expect(Get.find<ToastController>().toasts.last.kind, ToastKind.error);
      expect(Get.find<SalesController>().sales, hasLength(1));
      expect(_receiptOpen, isTrue);
    });

    test('an exception from the repository counts as failed', () async {
      final fake = _FakeCheckout()..error = StateError('boom');
      await bootTestApp(checkout: fake);
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();
      await _settle();

      expect(_toastTexts.last, _saveFailed);
    });

    test('a fallback save is silent', () async {
      final fake = _FakeCheckout()..outcome = PersistOutcome.savedViaFallback;
      await bootTestApp(checkout: fake);
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();
      await _settle();

      expect(_toastTexts.last, 'Payment completed');
      expect(_toastTexts, isNot(contains(_saveFailed)));
    });

    test('credit sales commit without a payment', () async {
      final fake = _FakeCheckout();
      await bootTestApp(checkout: fake);
      Get.find<CartMetaController>().setCustomer('3');
      Get.find<CartMetaController>().setSaleType(SaleType.credit);
      Get.find<CartActionsController>().add(
        Get.find<ProductsController>().byId(5)!,
      );
      Get.find<PaymentController>().payment(PaymentMode.cash);
      Get.find<OverlayController>().accept();
      await _settle();

      expect(fake.commits.single.payment, isNull);
    });

    test('a failed payment commits nothing', () async {
      final fake = _FakeCheckout();
      await bootTestApp(checkout: fake, payments: _DecliningPayments());
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();

      expect(fake.commits, isEmpty);
      expect(Get.find<SalesController>().sales, isEmpty);
      expect(_toastTexts.last, 'Payment failed');
    });
  });

  group('b1: the receipt waits for the commit', () {
    test('receipt and cart clear come after the commit completes', () async {
      final fake = _FakeCheckout()..gate = Completer<void>();
      await bootTestApp(checkout: fake, commitBeforeReceipt: true);
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();

      expect(fake.commits, hasLength(1));
      expect(_receiptOpen, isFalse);
      expect(Get.find<CartController>().isActive, isTrue);
      expect(
        Get.find<SalesController>().sales,
        hasLength(1),
        reason: 'memory is updated for the commit lists',
      );

      fake.gate!.complete();
      await _settle();
      await _settle();
      expect(_receiptOpen, isTrue);
      expect(Get.find<CartController>().isActive, isFalse);
      expect(_toastTexts.last, 'Payment completed');
      expect(_toastTexts, isNot(contains(_saveFailed)));
    });

    test('a second Complete during the wait is ignored', () async {
      final fake = _FakeCheckout()..gate = Completer<void>();
      await bootTestApp(checkout: fake, commitBeforeReceipt: true);
      final pay = await _cashSale();

      pay.completeCash();
      await _settle();
      pay.completeCash();
      await _settle();

      expect(fake.commits, hasLength(1));
      fake.gate!.complete();
      await _settle();
      await _settle();
      expect(Get.find<SalesController>().sales, hasLength(1));
    });

    test(
      'a failed commit shows the error toast, then completes the flow',
      () async {
        final fake = _FakeCheckout()..outcome = PersistOutcome.failed;
        await bootTestApp(checkout: fake, commitBeforeReceipt: true);
        final pay = await _cashSale();

        pay.completeCash();
        await _settle();
        await _settle();

        expect(_toastTexts, contains(_saveFailed));
        expect(_receiptOpen, isTrue);
        expect(Get.find<CartController>().isActive, isFalse);
      },
    );
  });

  group('with the real Drift ledger', () {
    late AxpertDatabase db;
    late InMemoryLocalStore store;

    setUp(() {
      db = AxpertDatabase(NativeDatabase.memory());
      store = InMemoryLocalStore();
    });
    tearDown(() => db.close());

    Future<void> boot({bool? commitBeforeReceipt}) => bootTestApp(
      store: store,
      commitBeforeReceipt: commitBeforeReceipt,
      infrastructure: testInfrastructure(
        databaseProvider: _Provider(db),
        customersBackend: CustomersBackend.drift,
        productsBackend: ProductsBackend.drift,
        salesBackend: SalesBackend.drift,
      ),
    );

    Future<void> settleUntil(bool Function() done) async {
      for (var i = 0; i < 100 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    Future<int> sales() async =>
        (await db.customSelect('SELECT COUNT(*) AS n FROM sales').getSingle())
            .read<int>('n');

    for (final b1 in [false, true]) {
      test(
        'a cash sale for a member lands in Drift and the mirrors (${b1 ? 'b1' : 'b2'})',
        () async {
          await boot(commitBeforeReceipt: b1);
          Get.find<CartMetaController>().setCustomer('2');
          final pay = await _cashSale();
          final stock = Get.find<ProductsController>().byId(5)!.stock;

          pay.completeCash();
          await settleUntil(() => _receiptOpen);
          await Get.find<CartController>().flush();
          await settleUntil(() => false == false && store.hashCode != 0);
          for (var i = 0; i < 100; i++) {
            if (await sales() == 1) break;
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }

          expect(await sales(), 1);
          expect(
            (await db
                    .customSelect('SELECT COUNT(*) AS n FROM payments')
                    .getSingle())
                .read<int>('n'),
            1,
          );
          final row = await db
              .customSelect('SELECT stock FROM products WHERE legacy_id = 5')
              .getSingle();
          expect(row.read<int>('stock'), stock - 1);
          final saleJson =
              (await store.read(StorageKeys.sales) as List).single as Map;
          expect(saleJson['saleId'], isNotNull);
          expect(await store.has(StorageKeys.salesDriftStale), isFalse);
        },
      );
    }
  });
}
