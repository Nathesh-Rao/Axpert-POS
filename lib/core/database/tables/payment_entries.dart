import 'package:drift/drift.dart';

import 'payment_method_entries.dart';
import 'sale_entries.dart';

/// Payments of NEW cash and card sales (provisional, local-only, DEC-129).
/// `id` is the `paymentId`; `amount_minor` is the amount due (DEC-123). Only
/// succeeded payments are written (a failed payment stops the sale). Credit
/// sales and migrated sales have no rows. Not part of the LocalStore mirror.
@DataClassName('PaymentEntry')
class PaymentEntries extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text()();

  TextColumn get saleId => text().references(SaleEntries, #id)();

  /// `cash` or `card` (the `code` of the payment method; kept as history).
  TextColumn get method => text()();

  /// The store's payment method row (DEC-149); null for payments written
  /// before v13 or outside a store session.
  TextColumn get methodId =>
      text().nullable().references(PaymentMethodEntries, #id)();

  IntColumn get amountMinor => integer()();

  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();

  /// `succeeded` (the only value written today).
  TextColumn get status => text()();

  IntColumn get occurredAt => integer()();

  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
