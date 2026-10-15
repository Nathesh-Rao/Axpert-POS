import 'package:pos_application/core/utils/epoch_time.dart';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/migration/cart_migrator.dart';
import 'package:pos_application/core/database/migration/cart_rows.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/modules/pos/models/cart.dart';

import '../../../support/product_fixtures.dart';

void main() {
  late AxpertDatabase db;
  late InMemoryLocalStore store;
  final migrator = CartMigrator(now: () => DateTime.utc(2026, 10, 12));
  final full = Cart.empty
      .addItem(prod(1))
      .addItem(prod(2))
      .setQty(2, const Qty(2500))
      .copyWith(customer: '2', note: 'n', points: 3);

  setUp(() {
    db = AxpertDatabase(NativeDatabase.memory());
    store = InMemoryLocalStore();
  });
  tearDown(() => db.close());

  Future<Map<String, dynamic>> markerJson() async {
    final row = await (db.select(
      db.migrationStateEntries,
    )..where((t) => t.key.equals(cartCopyMarkerKey))).getSingle();
    return jsonDecode(row.value) as Map<String, dynamic>;
  }

  Future<List<CurrentCartEntry>> rows() =>
      db.select(db.currentCartEntries).get();

  test('a missing key copies nothing: no row, LocalStore untouched', () async {
    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, CartCopyResult.copied);
    expect(await rows(), isEmpty);
    expect(await store.has(StorageKeys.cart), isFalse);
    final marker = await markerJson();
    expect(marker['count'], 0);
    expect(marker['report'], {'had_value': false, 'unreadable': false});
    expect((await CartRows.read(db)).cart.lines, isEmpty);
  });

  test(
    'a readable cart is copied as canonical JSON, LocalStore untouched',
    () async {
      await store.write(StorageKeys.cart, full.toJson());
      final before = await store.read(StorageKeys.cart);

      await migrator.ensureCopied(db, store);

      final r = await rows();
      expect(r.single.id, 1);
      expect(r.single.cartJson, jsonEncode(full.toJson()));
      expect(r.single.updatedAt, EpochTime.parse('2026-10-12T00:00:00.000Z'));
      expect((await CartRows.read(db)).cart.toJson(), full.toJson());
      expect(await store.read(StorageKeys.cart), before);
      expect((await markerJson())['count'], 1);
    },
  );

  test('a stored empty cart is copied as the empty cart row', () async {
    await store.write(StorageKeys.cart, Cart.empty.toJson());

    await migrator.ensureCopied(db, store);

    expect((await rows()).single.cartJson, jsonEncode(Cart.empty.toJson()));
    expect((await markerJson())['count'], 1);
  });

  for (final bad in <String, Object?>{
    'a string': 'x',
    'a list': <Object?>[],
    'lines not a list': {'lines': 5},
    'an empty map': <String, dynamic>{},
  }.entries) {
    test(
      'an unreadable value (${bad.key}) is not copied and does not throw',
      () async {
        await store.write(StorageKeys.cart, bad.value);

        final outcome = await migrator.ensureCopied(db, store);

        expect(outcome.report!.unreadable, isTrue);
        expect(outcome.report!.hasFindings, isTrue);
        expect(await rows(), isEmpty);
        expect(await store.read(StorageKeys.cart), bad.value);
        expect((await markerJson())['count'], 0);
        expect((await CartRows.read(db)).cart.lines, isEmpty);
      },
    );
  }

  test('second run is a no-op', () async {
    await store.write(StorageKeys.cart, full.toJson());
    await migrator.ensureCopied(db, store);
    await store.write(StorageKeys.cart, Cart.empty.toJson());

    final again = await migrator.ensureCopied(db, store);

    expect(again.result, CartCopyResult.alreadyCopied);
    expect((await CartRows.read(db)).cart.lines, hasLength(2));
  });

  test('stale key re-copies the LocalStore cart and clears the key', () async {
    await store.write(StorageKeys.cart, full.toJson());
    await migrator.ensureCopied(db, store);
    final newer = Cart.empty.addItem(prod(7));
    await store.write(StorageKeys.cart, newer.toJson());
    await store.write(StorageKeys.cartDriftStale, true);

    final outcome = await migrator.ensureCopied(db, store);

    expect(outcome.result, CartCopyResult.recopied);
    expect((await CartRows.read(db)).cart.toJson(), newer.toJson());
    expect(await rows(), hasLength(1));
    expect(await store.has(StorageKeys.cartDriftStale), isFalse);
  });

  test(
    'stale re-copy with a missing or unreadable value resets the row',
    () async {
      await store.write(StorageKeys.cart, full.toJson());
      await migrator.ensureCopied(db, store);

      await store.remove(StorageKeys.cart);
      await store.write(StorageKeys.cartDriftStale, true);
      await migrator.ensureCopied(db, store);
      expect((await CartRows.read(db)).cart.lines, isEmpty);
      expect(await rows(), hasLength(1));

      await store.write(StorageKeys.cart, full.toJson());
      await store.write(StorageKeys.cartDriftStale, true);
      await migrator.ensureCopied(db, store);
      await store.write(StorageKeys.cart, 'garbage');
      await store.write(StorageKeys.cartDriftStale, true);
      final outcome = await migrator.ensureCopied(db, store);
      expect(outcome.report!.unreadable, isTrue);
      expect((await CartRows.read(db)).cart.lines, isEmpty);
      expect(await store.has(StorageKeys.cartDriftStale), isFalse);
    },
  );

  test('verification failure rolls everything back', () async {
    await store.write(StorageKeys.cart, full.toJson());
    await db.customStatement(
      'CREATE TRIGGER t AFTER INSERT ON current_cart BEGIN '
      "UPDATE current_cart SET cart_json = 'garbage'; END",
    );

    await expectLater(migrator.ensureCopied(db, store), throwsA(anything));

    expect(await rows(), isEmpty);
    expect(await db.select(db.migrationStateEntries).get(), isEmpty);
  });

  test('an unreadable Drift row reads as the empty cart, flagged', () async {
    await db.customStatement(
      "INSERT INTO current_cart (cart_json, updated_at) VALUES ('{bad', 0)",
    );

    final read = await CartRows.read(db);

    expect(read.unreadable, isTrue);
    expect(read.cart.lines, isEmpty);
    expect(read.json, isNull);
  });

  test('write upserts the single row', () async {
    await CartRows.write(db, CartRows.encode(full), now: 1000);
    await CartRows.write(db, CartRows.encode(Cart.empty), now: 2000);

    final r = await rows();
    expect(r, hasLength(1));
    expect(r.single.updatedAt, 2000);
    expect((await CartRows.read(db)).cart.lines, isEmpty);
  });
}
