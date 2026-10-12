import '../../../../core/services/pricing/money.dart';
import 'payment_method.dart';
import 'payment_status.dart';

/// Outcome of one payment attempt.
final class PaymentResult {
  const PaymentResult({
    required this.paymentId,
    required this.saleId,
    required this.amount,
    required this.method,
    required this.status,
    this.message,
  });

  final String paymentId;
  final String saleId;
  final Money amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? message;

  bool get succeeded => status == PaymentStatus.succeeded;
}
