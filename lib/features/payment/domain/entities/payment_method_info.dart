/// The kind of a payment method (the `type` column).
enum PaymentMethodType {
  cash('cash'),
  card('card'),
  bankTransfer('bank_transfer'),
  mobileMoney('mobile_money'),
  other('other');

  const PaymentMethodType(this.code);

  final String code;

  static PaymentMethodType fromCode(String code) => values.firstWhere(
    (t) => t.code == code,
    orElse: () => PaymentMethodType.other,
  );
}

/// A payment method of one store, as configured in the database (DEC-149).
class PaymentMethodInfo {
  const PaymentMethodInfo({
    required this.id,
    required this.storeId,
    required this.code,
    required this.name,
    required this.type,
    this.enabled = true,
    this.sortOrder = 0,
    this.requiresReference = false,
  });

  final String id;
  final String storeId;

  /// `cash`, `card`, `bank_transfer`, `mobile_money` (stable within a store).
  final String code;
  final String name;
  final PaymentMethodType type;
  final bool enabled;
  final int sortOrder;
  final bool requiresReference;
}
