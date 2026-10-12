import '../../../../core/result/result.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_result.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/services/payment_service.dart';

/// Deterministic demo adapter: no delay, no I/O, no terminal. Succeeds unless
/// [outcome] says otherwise. NOT a payment provider (KG-185).
final class MockPaymentService implements PaymentService {
  const MockPaymentService({this.outcome = PaymentStatus.succeeded});

  final PaymentStatus outcome;

  @override
  Future<Result<PaymentResult>> process(PaymentRequest request) async =>
      Result.success(
        PaymentResult(
          paymentId: request.paymentId,
          saleId: request.saleId,
          amount: request.amount,
          method: request.method,
          status: outcome,
          message: switch (outcome) {
            PaymentStatus.succeeded => 'Mock payment successful (demo).',
            PaymentStatus.failed => 'Mock payment failed (demo).',
          },
        ),
      );
}
