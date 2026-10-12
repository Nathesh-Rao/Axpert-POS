// Stage 7c (DEC-123): checkout goes through the PaymentService seam for cash
// and card (amount due), not for credit; a failed payment changes nothing;
// the processing guard is always released; the new sale carries a UUID v4
// saleId that equals the one sent to the service.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/errors/app_failure.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method.dart';
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
import 'package:pos_application/modules/pos/models/cart.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/modules/sales/controllers/sales_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';

final _uuidV4 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

/// Records requests and answers from a script (default: success).
class _ScriptedPayments implements PaymentService {
  final List<PaymentRequest> requests = <PaymentRequest>[];
  final List<Future<Result<PaymentResult>> Function(PaymentRequest)> script =
      <Future<Result<PaymentResult>> Function(PaymentRequest)>[];

  static Future<Result<PaymentResult>> answer(
    PaymentRequest r,
    PaymentStatus status,
  ) async => Result.success(
    PaymentResult(
      paymentId: r.paymentId,
      saleId: r.saleId,
      amount: r.amount,
      method: r.method,
      status: status,
    ),
  );

  @override
  Future<Result<PaymentResult>> process(PaymentRequest request) {
    requests.add(request);
    if (script.isNotEmpty) return script.removeAt(0)(request);
    return answer(request, PaymentStatus.succeeded);
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

Future<PaymentController> _cashSale() async {
  final product = Get.find<ProductsController>().byId(5)!;
  Get.find<CartActionsController>().add(product);
  final pay = Get.find<PaymentController>();
  pay.payment(PaymentMode.cash);
  return pay;
}

void main() {
  useTestApp();

  test(
    'cash: one request with the amount due and the same saleId as the sale',
    () async {
      final payments = _ScriptedPayments();
      await bootTestApp(payments: payments);
      final pay = await _cashSale();
      final due = Get.find<CartController>().totals.value.total;
      pay.completeCash();
      await _settle();

      expect(payments.requests, hasLength(1));
      final request = payments.requests.single;
      expect(request.method, PaymentMethod.cash);
      expect(request.amount, due);
      expect(request.paymentId, matches(_uuidV4));
      expect(request.saleId, matches(_uuidV4));
      expect(request.paymentId, isNot(request.saleId));
      final sale = Get.find<SalesController>().sales.single;
      expect(sale.saleId, request.saleId);
      expect(sale.toJson()['saleId'], request.saleId);
      expect(Get.find<CartController>().isActive, isFalse);
      expect(Get.find<OverlayController>().modal.value, 'receipt');
    },
  );

  test(
    'cash: tendered above the amount due still sends the amount due',
    () async {
      final payments = _ScriptedPayments();
      await bootTestApp(payments: payments);
      final pay = await _cashSale();
      final due = Get.find<CartController>().totals.value.total;
      pay.tendered.text = '500';
      pay.completeCash();
      await _settle();
      expect(payments.requests.single.amount, due);
      final sale = Get.find<SalesController>().sales.single;
      expect(sale.tendered.minor, 50000);
      expect(sale.change.minor, 50000 - due.minor);
    },
  );

  test('card: method card and the amount due', () async {
    final payments = _ScriptedPayments();
    await bootTestApp(payments: payments);
    final product = Get.find<ProductsController>().byId(5)!;
    Get.find<CartActionsController>().add(product);
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.card);
    pay.terminal.value = TerminalState.approved;
    final due = Get.find<CartController>().totals.value.total;
    pay.completeCard();
    await _settle();
    expect(payments.requests.single.method, PaymentMethod.card);
    expect(payments.requests.single.amount, due);
    expect(Get.find<SalesController>().sales, hasLength(1));
  });

  test('credit sales do not call the payment service', () async {
    final payments = _ScriptedPayments();
    await bootTestApp(payments: payments);
    Get.find<CustomersController>(); // seeded members exist
    Get.find<CartMetaController>().setCustomer('3');
    Get.find<CartMetaController>().setSaleType(SaleType.credit);
    Get.find<CartActionsController>().add(
      Get.find<ProductsController>().byId(5)!,
    );
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash); // credit: opens the confirmation
    Get.find<OverlayController>().accept();
    await _settle();
    expect(payments.requests, isEmpty);
    final sale = Get.find<SalesController>().sales.single;
    expect(sale.saleId, matches(_uuidV4));
  });

  test('a failed payment changes nothing and shows the failed toast', () async {
    final payments = _ScriptedPayments()
      ..script.add((r) => _ScriptedPayments.answer(r, PaymentStatus.failed));
    await bootTestApp(payments: payments);
    final pay = await _cashSale();
    final stock = Get.find<ProductsController>().byId(5)!.stock;
    pay.completeCash();
    await _settle();

    expect(Get.find<SalesController>().sales, isEmpty);
    expect(Get.find<CartController>().isActive, isTrue);
    expect(Get.find<ProductsController>().byId(5)!.stock, stock);
    expect(Get.find<OverlayController>().modal.value, isNull);
    final toast = Get.find<ToastController>().toasts.last;
    expect(toast.text, 'Payment failed');
    expect(toast.kind, ToastKind.error);

    // The guard is released: the next attempt (scripted success) completes.
    pay.completeCash();
    await _settle();
    expect(Get.find<SalesController>().sales, hasLength(1));
  });

  test('a Result failure from the service is a failed payment too', () async {
    final payments = _ScriptedPayments()
      ..script.add(
        (r) async => const Result<PaymentResult>.failure(
          UnexpectedFailure(message: 'offline'),
        ),
      );
    await bootTestApp(payments: payments);
    final pay = await _cashSale();
    pay.completeCash();
    await _settle();
    expect(Get.find<SalesController>().sales, isEmpty);
    expect(Get.find<ToastController>().toasts.last.text, 'Payment failed');
  });

  test('an exception from the service never leaves checkout blocked', () async {
    final payments = _ScriptedPayments()
      ..script.add((r) async => throw StateError('terminal exploded'));
    await bootTestApp(payments: payments);
    final pay = await _cashSale();
    final errors = <Object>[];
    await runZonedGuarded(() async {
      pay.completeCash();
      await _settle();
    }, (error, stack) => errors.add(error));
    expect(errors.single, isA<StateError>(), reason: 'not swallowed');
    expect(Get.find<SalesController>().sales, isEmpty);

    pay.completeCash(); // guard released by the finally block
    await _settle();
    expect(Get.find<SalesController>().sales, hasLength(1));
  });

  test('a second Complete while the first is processing is ignored', () async {
    final payments = _ScriptedPayments();
    final gate = Completer<void>();
    payments.script.add((r) async {
      await gate.future;
      return _ScriptedPayments.answer(r, PaymentStatus.succeeded);
    });
    await bootTestApp(payments: payments);
    final pay = await _cashSale();
    pay.completeCash();
    pay.completeCash();
    await _settle();
    expect(payments.requests, hasLength(1));
    gate.complete();
    await _settle();
    expect(Get.find<SalesController>().sales, hasLength(1));
  });

  test('the PaymentService is registered once and is the binding\'s', () async {
    final payments = _ScriptedPayments();
    final binding = await bootTestApp(payments: payments);
    binding.dependencies();
    expect(Get.find<PaymentService>(), same(payments));
    expect(binding.payments, same(payments));
  });
}
