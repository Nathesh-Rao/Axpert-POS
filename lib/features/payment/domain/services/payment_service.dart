import '../../../../core/result/result.dart';
import '../entities/payment_request.dart';
import '../entities/payment_result.dart';

/// Payment boundary implemented by the mock and, later, by provider adapters.
/// A `Result` failure means the attempt could not be made (transport or
/// configuration); a declined payment is a success carrying `failed`.
abstract interface class PaymentService {
  Future<Result<PaymentResult>> process(PaymentRequest request);
}
