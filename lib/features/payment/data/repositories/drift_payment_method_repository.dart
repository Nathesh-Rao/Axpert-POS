import 'package:drift/drift.dart';

import '../../../../core/database/axpert_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../domain/entities/payment_method_info.dart';
import '../../domain/repositories/payment_method_repository.dart';

/// Payment methods read from `payment_methods`.
class DriftPaymentMethodRepository implements PaymentMethodRepository {
  DriftPaymentMethodRepository(this._provider);

  final DatabaseProvider _provider;

  @override
  Future<List<PaymentMethodInfo>> methodsFor(String storeId) async {
    final db = await _provider.open();
    final rows =
        await (db.select(db.paymentMethodEntries)
              ..where((t) => t.storeId.equals(storeId) & t.deletedAt.isNull())
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.code),
              ]))
            .get();
    return [for (final r in rows) toInfo(r)];
  }

  /// The id of the store's method with [code], inside a transaction (the
  /// checkout stores it on the payment row); null when there is none.
  static Future<String?> idForCode(
    AxpertDatabase db,
    String storeId,
    String code,
  ) async {
    final row =
        await (db.select(db.paymentMethodEntries)..where(
              (t) =>
                  t.storeId.equals(storeId) &
                  t.code.equals(code) &
                  t.deletedAt.isNull(),
            ))
            .getSingleOrNull();
    return row?.id;
  }

  static PaymentMethodInfo toInfo(PaymentMethodEntry r) => PaymentMethodInfo(
    id: r.id,
    storeId: r.storeId,
    code: r.code,
    name: r.name,
    type: PaymentMethodType.fromCode(r.methodType),
    enabled: r.enabled,
    sortOrder: r.sortOrder,
    requiresReference: r.requiresReference,
  );
}

/// The four default methods, for the LocalStore path and tests (no Drift).
class MockPaymentMethodRepository implements PaymentMethodRepository {
  const MockPaymentMethodRepository({this.disabled = const <String>{}});

  /// Codes to report as disabled.
  final Set<String> disabled;

  @override
  Future<List<PaymentMethodInfo>> methodsFor(String storeId) async => [
    for (final (i, m) in defaults.indexed)
      PaymentMethodInfo(
        id: 'mock-${m.$1}',
        storeId: storeId,
        code: m.$1,
        name: m.$2,
        type: PaymentMethodType.fromCode(m.$3),
        enabled: !disabled.contains(m.$1),
        sortOrder: i + 1,
        requiresReference: m.$4,
      ),
  ];

  /// code, name, type, requires_reference.
  static const List<(String, String, String, bool)> defaults = [
    ('cash', 'Cash', 'cash', false),
    ('card', 'Card', 'card', false),
    ('bank_transfer', 'Bank transfer', 'bank_transfer', true),
    ('mobile_money', 'Mobile money', 'mobile_money', true),
  ];
}
