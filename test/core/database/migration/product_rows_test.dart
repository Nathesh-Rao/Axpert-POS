import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/product_rows.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/services/pricing/basis_points.dart';
import 'package:pos_application/core/utils/gst_json.dart';

import '../../../support/product_fixtures.dart';

void main() {
  const now = '2026-10-12T00:00:00.000Z';
  final uuid = UuidV4Generator();
  late AxpertDatabase db;

  setUp(() => db = AxpertDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Map<int, KnownProduct>> apply(
    List<dynamic> list,
    Map<int, KnownProduct> known, {
    String at = now,
  }) async {
    final plan = ProductRows.plan(list.cast(), known, now: at, uuid: uuid);
    await db.durableTransaction(() => ProductRows.write(db, plan, now: at));
    return plan.next;
  }

  test('an unchanged list plans zero row writes', () async {
    final list = prods(50);
    final known = await apply(list, {});

    final plan = ProductRows.plan(list, known, now: now, uuid: uuid);

    expect(plan.isEmpty, isTrue);
    expect(identical(plan.next.length, known.length), isTrue);
  });

  test('k changed products plan exactly k updates', () async {
    final list = prods(50);
    final known = await apply(list, {});
    final changed = [
      for (final p in list)
        if (p.id == 3 || p.id == 20) p.copyWith(stock: p.stock - 2) else p,
    ];

    final plan = ProductRows.plan(changed, known, now: now, uuid: uuid);

    expect(plan.inserts, isEmpty);
    expect(plan.tombstones, isEmpty);
    expect(plan.updates.map((u) => u.$1).toSet(), {
      known[3]!.uuid,
      known[20]!.uuid,
    });
  });

  test('planning never mutates the snapshot passed in', () async {
    final list = prods(5);
    final known = await apply(list, {});
    final before = {for (final e in known.entries) e.key: e.value.product};

    ProductRows.plan([list[0].copyWith(stock: 1)], known, now: now, uuid: uuid);

    expect({for (final e in known.entries) e.key: e.value.product}, before);
    expect(known.values.every((k) => k.active), isTrue);
  });

  test(
    'new ids insert, missing ids tombstone, a returning id reactivates',
    () async {
      final list = prods(3);
      var known = await apply(list, {});
      final uuid1 = known[1]!.uuid;

      known = await apply(
        [list[0], prod(9)],
        known,
        at: '2026-10-13T00:00:00.000Z',
      );
      expect(known[1]!.active, isFalse);
      expect(known[9]!.position, 1);
      var all = await db.select(db.productEntries).get();
      expect(all, hasLength(4), reason: 'never DELETE');
      expect(all.firstWhere((r) => r.legacyId == 1).deletedAt, isNotNull);

      known = await apply(
        [list[0], list[1]],
        known,
        at: '2026-10-14T00:00:00.000Z',
      );
      all = await db.select(db.productEntries).get();
      final back = all.firstWhere((r) => r.legacyId == 1);
      expect(back.id, uuid1, reason: 'same UUID');
      expect(back.deletedAt, isNull);
      expect(back.createdAt, now);
      expect(back.updatedAt, '2026-10-14T00:00:00.000Z');
    },
  );

  test('duplicate ids in a list are refused before any write', () async {
    expect(
      () => ProductRows.plan([prod(1), prod(1)], {}, now: now, uuid: uuid),
      throwsA(isA<DuplicateProductIdsException>()),
    );
  });

  test('gst percent <-> basis points round trips for every value 0..10000', () {
    for (var bp = 0; bp <= 10000; bp++) {
      final json = GstJson.toJson(Bp(bp));
      expect(GstJson.parse(json), Bp(bp), reason: '$bp -> $json');
    }
    expect(GstJson.toJson(const Bp(1800)), 18);
    expect(GstJson.toJson(const Bp(550)), 5.5);
  });

  test('rows rebuild the exact JSON of the list (byte-compatible)', () async {
    final list = [
      prod(0, gstBp: 1800),
      prod(1, gstBp: 550, favourite: true, image: 7),
      prod(2, gstBp: 0, stock: 0),
      prod(3, gstBp: 1250),
    ];
    await apply(list, {});

    final read = (await ProductRows.read(db)).list;

    expect(jsonEncode(productsJson(read)), jsonEncode(productsJson(list)));
  });
}
