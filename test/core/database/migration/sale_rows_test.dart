import 'package:pos_application/core/utils/epoch_time.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/sale_rows.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method.dart';
import 'package:pos_application/features/payment/domain/entities/payment_result.dart';
import 'package:pos_application/features/payment/domain/entities/payment_status.dart';
import 'package:pos_application/modules/sales/models/sale.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';

import '../../../support/ledger_fixtures.dart';

const String _id1 = '11111111-1111-4111-8111-111111111111';
const String _id2 = '22222222-2222-4222-8222-222222222222';

void main() {
  late AxpertDatabase db;
  final uuid = UuidV4Generator();

  setUp(() => db = AxpertDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<SaleWrite> save(List<Sale> sales, {int now = 1000}) async {
    late SaleWrite plan;
    await db.durableTransaction(() async {
      final existing = await SaleRows.read(db);
      plan = SaleRows.plan(sales, existing.known, now: now, uuid: uuid);
      await SaleRows.write(db, plan, now: now, uuid: uuid);
    });
    return plan;
  }

  test('appending a sale writes only that sale and its lines', () async {
    final a = ledgerSale('AX000001', saleId: _id1);
    await save([a]);

    final plan = await save([a, ledgerSale('AX000002', saleId: _id2)]);

    expect(plan.inserts, hasLength(1));
    expect(plan.updates, isEmpty);
    expect(plan.tombstones, isEmpty);
    expect(plan.rowCount, 3, reason: 'one sale and two lines');
    expect(await db.select(db.saleEntries).get(), hasLength(2));
    expect(await db.select(db.saleLineEntries).get(), hasLength(4));
  });

  test('an unchanged list plans nothing', () async {
    final list = [ledgerSale('AX000001', saleId: _id1), ledgerSale('AX000002')];
    await save(list);

    final plan = await save((await SaleRows.read(db)).list);

    expect(plan.isEmpty, isTrue);
  });

  test('a return updates the lines, the order and updated_at only', () async {
    final a = ledgerSale('AX000001', saleId: _id1);
    await save([a]);
    final returned = a.copyWith(
      returned: {
        const LineKey(2): const Qty(1000),
        const LineKey(1): const Qty(500),
      },
    );

    final plan = await save([returned], now: 2000);

    expect(plan.inserts, isEmpty);
    expect(plan.updates, hasLength(1));
    final row = await db.select(db.saleEntries).getSingle();
    expect(row.updatedAt, 2000);
    expect(row.createdAt, 1000);
    expect(row.returnedOrder, '[2,1]');
    final back = (await SaleRows.read(db)).list.single;
    expect(back.returned.keys.toList(), [const LineKey(2), const LineKey(1)]);
    expect(back.returned[const LineKey(1)], const Qty(500));
    // A second return adds on top and keeps the order.
    final again = back.copyWith(
      returned: {...back.returned, const LineKey(1): const Qty(1500)},
    );
    await save([again], now: 3000);
    final last = (await SaleRows.read(db)).list.single;
    expect(last.returned.keys.toList(), [const LineKey(2), const LineKey(1)]);
    expect(last.returned[const LineKey(1)], const Qty(1500));
  });

  test('changing anything but returned is rejected before any write', () async {
    final a = ledgerSale('AX000001', saleId: _id1);
    await save([a]);
    final other = ledgerSale('AX000001', saleId: _id1, customerName: 'Other');

    await expectLater(save([other]), throwsA(isA<SaleImmutableException>()));

    final row = await db.select(db.saleEntries).getSingle();
    expect(row.customerName, 'Walk-in Customer');
    expect(row.updatedAt, 1000);
  });

  test(
    'a removed sale is tombstoned, a returning sale is reactivated',
    () async {
      final a = ledgerSale('AX000001', saleId: _id1);
      final b = ledgerSale('AX000002', saleId: _id2);
      await save([a, b]);

      await save([a], now: 2000);
      var rows = await db.select(db.saleEntries).get();
      expect(rows.where((r) => r.deletedAt != null), hasLength(1));
      expect((await SaleRows.read(db)).list, hasLength(1));

      await save([a, b], now: 3000);
      rows = await db.select(db.saleEntries).get();
      expect(rows.where((r) => r.deletedAt != null), isEmpty);
      expect(rows, hasLength(2));
      expect(await db.select(db.saleLineEntries).get(), hasLength(4));
    },
  );

  test('a reordered list updates positions', () async {
    final a = ledgerSale('AX000001', saleId: _id1);
    final b = ledgerSale('AX000002', saleId: _id2);
    await save([a, b]);

    await save([b, a], now: 2000);

    expect((await SaleRows.read(db)).list.map((s) => s.number), [
      'AX000002',
      'AX000001',
    ]);
  });

  test('links resolve at insert when the rows exist, else by backfill', () async {
    // No customer or product rows yet: links stay null.
    await save([ledgerSale('AX000001', saleId: _id1, customerId: 'c9')]);
    expect((await db.select(db.saleEntries).getSingle()).customerId, isNull);
    expect(
      (await db.select(db.saleLineEntries).get()).map((l) => l.productId),
      everyElement(isNull),
    );

    // Customers and products appear later (parallel copies on the first start).
    await db.customStatement(
      "INSERT INTO customers VALUES ('cu1', 'c9', 0, 'N', '', '', '', 0, "
      "0, 0, NULL, NULL, NULL, NULL)",
    );
    await db.customStatement(
      "INSERT INTO products (id, legacy_id, position, name, code, barcode, "
      "price_minor, category, sub, stock, gst_bp, image, favourite, "
      "created_at, updated_at) VALUES ('pu1', 1, 0, 'n', 'c', 'b', 1, 'c', "
      "'s', 1, 1800, -1, 0, 0, 0)",
    );
    await SaleRows.resolveLinks(db);
    await SaleRows.resolveLinks(db); // idempotent

    expect((await db.select(db.saleEntries).getSingle()).customerId, 'cu1');
    final lines = await db.select(db.saleLineEntries).get();
    expect(
      {for (final l in lines) l.productLegacyId: l.productId},
      {1: 'pu1', 2: null},
    );

    // A new sale resolves inside the insert.
    await save([
      ledgerSale('AX000001', saleId: _id1, customerId: 'c9'),
      ledgerSale('AX000002', saleId: _id2, customerId: 'c9'),
    ], now: 2000);
    final second = await (db.select(
      db.saleEntries,
    )..where((t) => t.id.equals(_id2))).getSingle();
    expect(second.customerId, 'cu1');
  });

  test('a payment row is stored for a sale', () async {
    final a = ledgerSale('AX000001', saleId: _id1);
    await save([a]);

    await db.durableTransaction(
      () => SaleRows.insertPayment(
        db,
        const PaymentResult(
          paymentId: 'pay-1',
          saleId: _id1,
          amount: Money(21420, CurrencyRegistry.inr),
          method: PaymentMethod.card,
          status: PaymentStatus.succeeded,
        ),
        occurredAt: EpochTime.parse(a.date),
        now: 1000,
      ),
    );

    final p = await db.select(db.paymentEntries).getSingle();
    expect(
      (p.id, p.saleId, p.method, p.amountMinor, p.status),
      ('pay-1', _id1, 'card', 21420, 'succeeded'),
    );
  });

  test('two legacy sales with the same number keep separate rows', () async {
    final a = ledgerSale('AX000001');
    final b = ledgerSale('AX000001', customerName: 'B');
    await save([a, b]);

    final plan = await save((await SaleRows.read(db)).list, now: 2000);

    expect(plan.isEmpty, isTrue);
    expect((await SaleRows.read(db)).list.map((s) => s.customer), [
      'Walk-in Customer',
      'B',
    ]);
  });
}
