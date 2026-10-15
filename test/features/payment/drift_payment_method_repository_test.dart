import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/features/payment/data/repositories/drift_payment_method_repository.dart';
import 'package:pos_application/features/payment/domain/entities/payment_method_info.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

void main() {
  late AxpertDatabase db;
  late DriftPaymentMethodRepository repository;

  setUp(() async {
    db = AxpertDatabase(NativeDatabase.memory());
    repository = DriftPaymentMethodRepository(_Provider(db));
    await db.customStatement(
      "INSERT INTO currencies (code, name, symbol, exponent, grouping, "
      "created_at, updated_at) VALUES ('INR', 'R', 'R', 2, 'lakh', 1, 1)",
    );
    for (final s in ['s1', 's2']) {
      await db.customStatement(
        "INSERT INTO stores (id, name, currency_code, created_at, updated_at) "
        "VALUES ('$s', '$s', 'INR', 1, 1)",
      );
    }
    Future<void> m(
      String id,
      String store,
      String code,
      String type,
      int sort, {
      int enabled = 1,
      int? deleted,
    }) => db.customStatement(
      'INSERT INTO payment_methods (id, store_id, code, name, type, enabled, '
      'sort_order, requires_reference, created_at, updated_at, deleted_at) '
      "VALUES ('$id', '$store', '$code', '$code', '$type', $enabled, $sort, "
      '${type == 'bank_transfer' ? 1 : 0}, 1, 1, ${deleted ?? 'NULL'})',
    );
    await m('a', 's1', 'card', 'card', 2, enabled: 0);
    await m('b', 's1', 'cash', 'cash', 1);
    await m('c', 's1', 'bank_transfer', 'bank_transfer', 3);
    await m('d', 's1', 'old', 'other', 4, deleted: 9);
    await m('e', 's2', 'cash', 'cash', 1);
  });
  tearDown(() => db.close());

  test('methods of one store in sort order, tombstones left out', () async {
    final list = await repository.methodsFor('s1');

    expect(list.map((m) => m.code), ['cash', 'card', 'bank_transfer']);
    expect(list[1].enabled, isFalse);
    expect(list[0].enabled, isTrue);
    expect(list[2].type, PaymentMethodType.bankTransfer);
    expect(list[2].requiresReference, isTrue);
    expect(list.every((m) => m.storeId == 's1'), isTrue);
  });

  test('another store sees only its own methods', () async {
    expect((await repository.methodsFor('s2')).map((m) => m.id), ['e']);
    expect(await repository.methodsFor('nobody'), isEmpty);
  });

  test('idForCode finds the live row of the store', () async {
    expect(await DriftPaymentMethodRepository.idForCode(db, 's1', 'cash'), 'b');
    expect(await DriftPaymentMethodRepository.idForCode(db, 's2', 'cash'), 'e');
    expect(
      await DriftPaymentMethodRepository.idForCode(db, 's1', 'old'),
      isNull,
    );
    expect(await DriftPaymentMethodRepository.idForCode(db, 's1', 'x'), isNull);
  });

  test('the mock offers the four defaults, some can be turned off', () async {
    const mock = MockPaymentMethodRepository(disabled: {'card'});
    final list = await mock.methodsFor('s1');
    expect(list.map((m) => m.code), [
      'cash',
      'card',
      'bank_transfer',
      'mobile_money',
    ]);
    expect(list.map((m) => m.enabled), [true, false, true, true]);
  });
}
