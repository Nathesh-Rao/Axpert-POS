import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/result/result.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/features/payment/data/services/mock_payment_service.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method.dart';
import 'package:pos_application/features/payment/domain/entities/payment_request.dart';
import 'package:pos_application/features/payment/domain/entities/payment_result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_status.dart';
import 'package:pos_application/features/payment/domain/services/payment_service.dart';

const _request = PaymentRequest(
  paymentId: 'p-1',
  saleId: 's-1',
  amount: Money(12980, CurrencyRegistry.inr),
  method: PaymentMethod.card,
);

PaymentResult _unwrap(Result<PaymentResult> r) => r.fold(
  onSuccess: (v) => v,
  onFailure: (f) => fail('unexpected failure: ${f.message}'),
);

void main() {
  test('the default mock succeeds and echoes ids, amount and method', () async {
    const PaymentService service = MockPaymentService();
    final result = _unwrap(await service.process(_request));
    expect(result.status, PaymentStatus.succeeded);
    expect(result.succeeded, isTrue);
    expect(result.paymentId, 'p-1');
    expect(result.saleId, 's-1');
    expect(result.amount, const Money(12980, CurrencyRegistry.inr));
    expect(result.method, PaymentMethod.card);
  });

  test(
    'a configured failed outcome is a success result carrying failed',
    () async {
      final result = _unwrap(
        await const MockPaymentService(
          outcome: PaymentStatus.failed,
        ).process(_request),
      );
      expect(result.status, PaymentStatus.failed);
      expect(result.succeeded, isFalse);
      expect(result.message, isNotEmpty);
    },
  );
}
