// DEC-149: the checkout reads the store's payment methods; a method turned
// off in the database cannot be used, the others work as before.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/features/payment/data/repositories/drift_payment_method_repository.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method_info.dart';
import 'package:pos_application/features/payment/domain/repositories/payment_method_repository.dart';
import 'package:pos_application/features/products/presentation/controllers/products_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/payment_controller.dart';
import 'package:pos_application/modules/pos/models/payment_state.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/test_app.dart';

class _NoMethods implements PaymentMethodRepository {
  @override
  Future<List<PaymentMethodInfo>> methodsFor(String storeId) async =>
      const <PaymentMethodInfo>[];
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void _addItem() {
  final product = Get.find<ProductsController>().byId(5)!;
  Get.find<CartActionsController>().add(product);
}

void main() {
  useTestApp();

  test('all methods on: cash completes as before', () async {
    await bootTestApp(paymentMethods: const MockPaymentMethodRepository());
    await _settle();
    _addItem();
    final pay = Get.find<PaymentController>();
    pay.payment(PaymentMode.cash);
    expect(pay.methodEnabled('cash'), isTrue);
    expect(pay.methodEnabled('card'), isTrue);
    expect(pay.canCompleteCash, isTrue);
  });

  test(
    'cash turned off: the cash button cannot complete, a toast says why',
    () async {
      await bootTestApp(
        paymentMethods: const MockPaymentMethodRepository(disabled: {'cash'}),
      );
      await _settle();
      _addItem();
      final pay = Get.find<PaymentController>();

      pay.payment(PaymentMode.cash);

      expect(pay.methodEnabled('cash'), isFalse);
      expect(pay.canCompleteCash, isFalse);
      final toast = Get.find<ToastController>().toasts.last;
      expect(toast.kind, ToastKind.warning);
      expect(Get.find<CartController>().isActive, isTrue);
    },
  );

  test(
    'card turned off: the card mode is refused and cannot complete',
    () async {
      await bootTestApp(
        paymentMethods: const MockPaymentMethodRepository(disabled: {'card'}),
      );
      await _settle();
      _addItem();
      final pay = Get.find<PaymentController>();

      pay.payment(PaymentMode.card);

      expect(pay.mode.value, PaymentMode.cash);
      expect(pay.canCompleteCard, isFalse);
      expect(pay.methodEnabled('cash'), isTrue);
    },
  );

  test('a store with no configured methods keeps every method on', () async {
    await bootTestApp(paymentMethods: _NoMethods());
    await _settle();
    final pay = Get.find<PaymentController>();
    expect(pay.methodsByCode.value, isNull);
    expect(pay.methodEnabled('cash'), isTrue);
    expect(pay.methodEnabled('card'), isTrue);
  });
}
