import '../entities/payment_method_info.dart';

/// The payment methods a store accepts (DEC-149).
abstract interface class PaymentMethodRepository {
  /// Methods of [storeId] in `sort_order`, enabled or not; no tombstones.
  Future<List<PaymentMethodInfo>> methodsFor(String storeId);
}
