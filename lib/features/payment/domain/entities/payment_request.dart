import '../../../../core/services/pricing/money.dart';
import 'payment_method.dart';

/// One payment attempt for a sale: the amount due (`sale.totals.total`), not
/// the tendered amount or the change.
final class PaymentRequest {
  const PaymentRequest({
    required this.paymentId,
    required this.saleId,
    required this.amount,
    required this.method,
  });

  /// Local technical UUID of this attempt; not a provider transaction id.
  final String paymentId;
  final String saleId;
  final Money amount;
  final PaymentMethod method;
}
