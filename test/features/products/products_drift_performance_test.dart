// 10,000 products in Drift (D4): copy, load and checkout write cost, native
// in-memory SQLite. Row counts are asserted strictly elsewhere; the time
// thresholds here are loose guards, the measured values are printed for the
// report. VM tests.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/constants/storage_keys.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/database/database_provider.dart';
import 'package:pos_application/core/database/migration/product_rows.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/products/data/datasources/large_dataset.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_repository.dart';

class _Provider implements DatabaseProvider {
  _Provider(this.db);

  final AxpertDatabase db;

  @override
  Future<AxpertDatabase> open() async => db;

  @override
  Future<void> close() async {}
}

void _report(String label, Stopwatch sw) {
  // ignore: avoid_print
  print(
    'PERF $label: ${(sw.elapsedMicroseconds / 1000).toStringAsFixed(2)} ms',
  );
}

void main() {
  setUp(() => MockDelay.provider = () => Duration.zero);

  test(
    '10,000 products: copy, load, checkout delta and unchanged save',
    () async {
      final db = AxpertDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final store = InMemoryLocalStore();
      final source = LargeDataset.products();
      await store.write(StorageKeys.products, [
        for (final p in source) p.toJson(),
      ]);
      DriftProductRepository create() => DriftProductRepository(
        provider: _Provider(db),
        store: store,
        diagnostics: StartupDiagnostics(),
        uuid: UuidV4Generator(),
      );

      var sw = Stopwatch()..start();
      final first = create();
      final copied = await first.load();
      sw.stop();
      _report('copy 10k (first load: copy, verify, read)', sw);
      expect(copied.length, 10000);
      expect(sw.elapsedMilliseconds, lessThan(3000));

      sw = Stopwatch()..start();
      final repository = create();
      final list = await repository.load();
      sw.stop();
      _report('load 10k from Drift (marker present)', sw);
      expect(list, source);
      expect(sw.elapsedMilliseconds, lessThan(500));

      final sold = [
        for (final p in list)
          if (p.id == 10 || p.id == 5000 || p.id == 9999)
            p.copyWith(stock: p.stock - 2)
          else
            p,
      ];
      sw = Stopwatch()..start();
      final plan = ProductRows.plan(
        sold,
        repository.snapshot,
        now: '2026-10-12T00:00:00.000Z',
        uuid: UuidV4Generator(),
      );
      sw.stop();
      _report('diff 10k list vs snapshot (3 changed)', sw);
      expect(plan.rowCount, 3);
      expect(sw.elapsedMilliseconds, lessThan(50));

      sw = Stopwatch()..start();
      await db.durableTransaction(
        () => ProductRows.write(db, plan, now: '2026-10-12T00:00:00.000Z'),
      );
      sw.stop();
      _report('checkout Drift write (3 rows)', sw);
      expect(sw.elapsedMilliseconds, lessThan(50));

      sw = Stopwatch()..start();
      await repository.save(sold);
      sw.stop();
      _report('repository.save checkout (Drift + whole-list mirror)', sw);

      sw = Stopwatch()..start();
      await repository.save(sold);
      sw.stop();
      _report('repository.save unchanged list (0 rows + mirror)', sw);
    },
  );
}
