// The store configuration on the seeded database: legacy fallback, save and
// reload, forex effective dates, what the session loads, and the tax lines
// saved with a sale.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/bindings/startup_diagnostics.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/mock/mock_delay.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/money.dart';
import 'package:pos_application/core/services/pricing/tax_components.dart';
import 'package:pos_application/core/services/pricing/tax_split.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/features/session/data/drift_session_repositories.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/store_config/data/drift_store_config_repository.dart';
import 'package:pos_application/features/store_config/domain/entities/store_config.dart';
import 'package:pos_application/modules/sales/repository/drift_sale_repository.dart';

import '../../support/ledger_fixtures.dart';
import '../../support/seeded_database.dart';

const _ozone = 'demo-store-ozone';
const _kampala = 'demo-store-kampala';

void main() {
  late AxpertDatabase db;
  late DriftStoreConfigRepository repo;
  late DateTime clock;

  setUp(() async {
    MockDelay.provider = () => Duration.zero;
    db = await seededDatabase();
    clock = DateTime.utc(2026, 10, 15, 9);
    repo = DriftStoreConfigRepository(
      FixedDatabaseProvider(db),
      UuidV4Generator(),
      now: () => clock,
    );
  });
  tearDown(() => db.close());

  test(
    'a store without own slabs shows its legacy regime as components',
    () async {
      final config = await repo.load(_ozone);
      expect(config.countryCode, 'IN');
      expect(config.currencyCode, 'INR');
      expect(config.slabs.map((s) => s.rateBp), [0, 500, 1200, 1800]);
      final gst18 = config.slabs.last;
      expect(gst18.label, 'GST 18%');
      expect(gst18.components.map((c) => '${c.label}:${c.rateBp}'), [
        'CGST:900',
        'SGST:900',
      ]);
      expect(config.slabs.where((s) => s.isDefault), hasLength(1));
      expect(config.slabs.every((s) => s.id.isEmpty), isTrue);

      final vat = await repo.load(_kampala);
      expect(vat.countryCode, 'UG');
      expect(vat.slabs.last.components.single.label, 'VAT');
      expect(vat.slabs.last.label, 'Standard 18%');
    },
  );

  test('save then load returns what was saved, in one transaction', () async {
    final config = await repo.load(_ozone);
    final custom = TaxSlabInfo.of(
      id: '',
      name: 'VAT 16% + Service charge 5%',
      components: const [
        TaxComponent(label: 'VAT', rateBp: 1600),
        TaxComponent(label: 'Service charge', rateBp: 500),
      ],
    );
    await repo.save(
      config.copyWith(
        name: 'Ozone Mart',
        stateCode: 'KA',
        slabs: [...config.slabs, custom],
      ),
    );
    final back = await repo.load(_ozone);
    expect(back.name, 'Ozone Mart');
    expect(back.stateCode, 'KA');
    expect(back.slabs, hasLength(5));
    expect(back.slabs.last.rateBp, 2100);
    expect(back.slabs.last.components.map((c) => c.label), [
      'VAT',
      'Service charge',
    ]);
    expect(back.slabs.every((s) => s.id.isNotEmpty), isTrue);
    expect(await db.select(db.storeTaxSlabEntries).get(), hasLength(5));
  });

  test(
    'the session loads the store slabs, falling back to the regime',
    () async {
      final sessionRepo = DriftStoreRepository(FixedDatabaseProvider(db));
      final legacy = await sessionRepo.loadTaxRegime('IN', storeId: _ozone);
      expect(legacy!.hasComponentSlabs, isFalse);
      expect(legacy.taxName, 'GST');
      expect(legacy.splitParts, ['CGST', 'SGST']);

      final config = await repo.load(_ozone);
      await repo.save(config);
      final own = await sessionRepo.loadTaxRegime('IN', storeId: _ozone);
      expect(own!.hasComponentSlabs, isTrue);
      expect(own.slabFor(1800)!.label, 'GST 18%');
      // The other store keeps its regime.
      final kampala = await sessionRepo.loadTaxRegime('UG', storeId: _kampala);
      expect(kampala!.hasComponentSlabs, isFalse);
      expect(kampala.taxName, 'VAT');
    },
  );

  test('a store with its own slabs and no regime row still has tax', () async {
    final sessionRepo = DriftStoreRepository(FixedDatabaseProvider(db));
    final config = (await repo.load(_kampala)).copyWith(countryCode: 'KE');
    await repo.save(config);
    final regime = await sessionRepo.loadTaxRegime('KE', storeId: _kampala);
    expect(regime, isNotNull);
    expect(regime!.taxName, 'VAT');
  });

  test('forex: the effective date moves only for a changed row', () async {
    final first = await repo.load(_ozone);
    final usd = first.forex.firstWhere((f) => f.code == 'USD');
    clock = DateTime.utc(2026, 10, 16, 9);
    await repo.save(
      first.copyWith(
        forex: [
          for (final f in first.forex)
            f.code == 'EUR' ? f.copyWith(rateMicro: 91000000) : f,
        ],
      ),
    );
    final back = await repo.load(_ozone);
    expect(
      back.forex.firstWhere((f) => f.code == 'USD').updatedAtMs,
      usd.updatedAtMs,
    );
    expect(
      back.forex.firstWhere((f) => f.code == 'EUR').updatedAtMs,
      DateTime.utc(2026, 10, 16, 9).millisecondsSinceEpoch,
    );
    expect(back.forex.firstWhere((f) => f.code == 'EUR').rateMicro, 91000000);
  });

  test(
    'forex: rows can be added and removed; a new currency gets a row',
    () async {
      final first = await repo.load(_ozone);
      await repo.save(
        first.copyWith(
          forex: [
            const ForexRow(code: 'NGN', rateMicro: 55000),
            first.forex.first,
          ],
        ),
      );
      final back = await repo.load(_ozone);
      expect(back.forex.map((f) => f.code), ['NGN', first.forex.first.code]);
      expect(
        (await db.select(db.currencyEntries).get()).map((c) => c.code),
        contains('NGN'),
      );
    },
  );

  test('products per rate and store sales', () async {
    final counts = await repo.productCountsByRate(_ozone);
    expect(counts.values.fold<int>(0, (a, b) => a + b), 32);
    // The demo seed has sales for Ozone.
    expect(await repo.storeHasSales(_ozone), isTrue);
  });

  test('tax lines saved with a sale survive the database', () async {
    final sales = DriftSaleRepository(
      provider: FixedDatabaseProvider(db),
      store: InMemoryLocalStore(),
      diagnostics: StartupDiagnostics(),
      uuid: UuidV4Generator(),
    );
    await sales.load();
    const parts = [
      TaxPart('CGST', Money(5, CurrencyRegistry.inr)),
      TaxPart('SGST', Money(6, CurrencyRegistry.inr)),
    ];
    final plain = ledgerSale(
      'AX000001',
      saleId: '11111111-1111-4111-8111-111111111111',
    );
    final withParts = ledgerSale(
      'AX000002',
      saleId: '22222222-2222-4222-8222-222222222222',
    ).copyWith(taxParts: parts);
    await sales.save([plain, withParts]);
    final back = await sales.load();
    expect(back[0].taxParts, isEmpty);
    expect([for (final p in back[1].taxParts) p.label], ['CGST', 'SGST']);
    expect([for (final p in back[1].taxParts) p.amount.minor], [5, 6]);
  });
}
