// Store configuration rules (plain Dart): validation, country hints, the
// currency guard, the role gate and the sample bill.
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/services/pricing/tax_components.dart';
import 'package:pos_application/core/session/permissions.dart';
import 'package:pos_application/features/session/domain/entities/session_entities.dart';
import 'package:pos_application/features/store_config/domain/entities/store_config.dart';
import 'package:pos_application/features/store_config/domain/services/currency_change_guard.dart';
import 'package:pos_application/features/store_config/domain/services/store_config_validator.dart';
import 'package:pos_application/features/store_config/domain/services/tax_presets.dart';
import 'package:pos_application/features/store_config/domain/services/tax_preview.dart';

TaxSlabInfo _slab(
  String name,
  List<TaxComponent> comps, {
  bool isDefault = false,
  bool enabled = true,
  String scheme = TaxScheme.standard,
}) => TaxSlabInfo.of(
  id: name,
  name: name,
  components: comps,
  isDefault: isDefault,
  enabled: enabled,
  scheme: scheme,
);

StoreConfig _config({
  String name = 'Shop',
  List<TaxSlabInfo>? slabs,
  List<ForexRow> forex = const [],
}) => StoreConfig(
  storeId: 's',
  name: name,
  countryCode: 'IN',
  stateCode: '',
  currencyCode: 'INR',
  forex: forex,
  slabs:
      slabs ??
      [
        _slab('GST 18%', const [
          TaxComponent(label: 'CGST', rateBp: 900),
          TaxComponent(label: 'SGST', rateBp: 900),
        ], isDefault: true),
      ],
);

Set<ConfigIssueKind> _kinds(StoreConfig c) => {
  for (final i in StoreConfigValidator.validate(c)) i.kind,
};

void main() {
  group('validation', () {
    test('a good setup has no issues', () {
      expect(StoreConfigValidator.validate(_config()), isEmpty);
    });

    test('store name and slab name are required', () {
      expect(_kinds(_config(name: ' ')), {ConfigIssueKind.nameRequired});
      final k = _kinds(
        _config(
          slabs: [
            _slab('', const [
              TaxComponent(label: 'VAT', rateBp: 100),
            ], isDefault: true),
          ],
        ),
      );
      expect(k, contains(ConfigIssueKind.slabNameRequired));
    });

    test('component label required, rate 0..100 percent', () {
      final k = _kinds(
        _config(
          slabs: [
            _slab('x', const [
              TaxComponent(label: '  ', rateBp: 100),
              TaxComponent(label: 'Low', rateBp: -1),
              TaxComponent(label: 'High', rateBp: 10001),
            ], isDefault: true),
          ],
        ),
      );
      expect(
        k,
        containsAll([
          ConfigIssueKind.labelRequired,
          ConfigIssueKind.rateOutOfRange,
        ]),
      );
      // 0 and 100 percent are allowed.
      expect(
        StoreConfigValidator.validate(
          _config(
            slabs: [
              _slab('zero', const [
                TaxComponent(label: 'VAT', rateBp: 0),
              ], isDefault: true),
              _slab('full', const [TaxComponent(label: 'VAT', rateBp: 10000)]),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('a slab total above 100 percent is refused', () {
      final k = _kinds(
        _config(
          slabs: [
            _slab('big', const [
              TaxComponent(label: 'A', rateBp: 6000),
              TaxComponent(label: 'B', rateBp: 5000),
            ], isDefault: true),
          ],
        ),
      );
      expect(k, contains(ConfigIssueKind.slabTotalTooHigh));
    });

    test('no duplicate labels inside a slab (any case), across slabs ok', () {
      final dup = _kinds(
        _config(
          slabs: [
            _slab('x', const [
              TaxComponent(label: 'VAT', rateBp: 100),
              TaxComponent(label: 'vat ', rateBp: 200),
            ], isDefault: true),
          ],
        ),
      );
      expect(dup, contains(ConfigIssueKind.duplicateLabel));
      expect(
        StoreConfigValidator.validate(
          _config(
            slabs: [
              _slab('a', const [
                TaxComponent(label: 'VAT', rateBp: 100),
              ], isDefault: true),
              _slab('b', const [TaxComponent(label: 'VAT', rateBp: 200)]),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('a slab needs a component and a default slab must exist', () {
      expect(
        _kinds(_config(slabs: [_slab('empty', const [], isDefault: true)])),
        contains(ConfigIssueKind.slabNeedsComponent),
      );
      expect(
        _kinds(
          _config(
            slabs: [
              _slab('a', const [TaxComponent(label: 'VAT', rateBp: 100)]),
            ],
          ),
        ),
        contains(ConfigIssueKind.noDefaultSlab),
      );
    });

    test('enabled slabs of one scheme need unique totals', () {
      const c1800 = [TaxComponent(label: 'VAT', rateBp: 1800)];
      final dup = _kinds(
        _config(slabs: [_slab('a', c1800, isDefault: true), _slab('b', c1800)]),
      );
      expect(dup, contains(ConfigIssueKind.duplicateTotal));
      // Another scheme (IGST) or a disabled slab may repeat the total.
      expect(
        StoreConfigValidator.validate(
          _config(
            slabs: [
              _slab('a', c1800, isDefault: true),
              _slab('igst', const [
                TaxComponent(label: 'IGST', rateBp: 1800),
              ], scheme: TaxScheme.interState),
              _slab('off', c1800, enabled: false),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('forex: positive rate, one row per currency', () {
      final k = _kinds(
        _config(
          forex: const [
            ForexRow(code: 'USD', rateMicro: 0),
            ForexRow(code: 'EUR', rateMicro: 5),
            ForexRow(code: 'EUR', rateMicro: 6),
          ],
        ),
      );
      expect(k, {
        ConfigIssueKind.forexRateInvalid,
        ConfigIssueKind.forexDuplicate,
      });
    });
  });

  group('country hint', () {
    test('India lists the Indian presets first, every preset stays', () {
      final list = CountryHints.presetsFor('IN');
      expect(list.take(4), ['GST', 'CGST', 'SGST', 'IGST']);
      expect(list.toSet(), TaxPresets.all.toSet());
    });

    test('Uganda lists VAT first and still offers GST', () {
      final list = CountryHints.presetsFor('UG');
      expect(list.first, 'VAT');
      expect(list, contains('GST'));
      expect(list.toSet(), TaxPresets.all.toSet());
    });

    test('GST outside India warns but is allowed; in India it does not', () {
      expect(CountryHints.warnsIndianLabel('UG', 'GST'), isTrue);
      expect(CountryHints.warnsIndianLabel('UG', ' igst '), isTrue);
      expect(CountryHints.warnsIndianLabel('IN', 'GST'), isFalse);
      expect(CountryHints.warnsIndianLabel('UG', 'VAT'), isFalse);
      expect(CountryHints.warnsIndianLabel('UG', 'My levy'), isFalse);
      // The validator never blocks it.
      expect(
        StoreConfigValidator.validate(
          StoreConfig(
            storeId: 's',
            name: 'Kampala',
            countryCode: 'UG',
            stateCode: '',
            currencyCode: 'UGX',
            forex: const [],
            slabs: [
              _slab('GST', const [
                TaxComponent(label: 'GST', rateBp: 1800),
              ], isDefault: true),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('currency is only a default of the country', () {
      expect(CountryHints.defaultCurrency('IN'), 'INR');
      expect(CountryHints.defaultCurrency('UG'), 'UGX');
      expect(CountryHints.defaultCurrency('ZZ'), isNull);
      for (final c in CountryHints.countries) {
        expect(CurrencyRegistry.byCode(c.currencyCode).code, c.currencyCode);
      }
    });
  });

  test('currency guard blocks a change only when the store has sales', () {
    bool blocked(String now, bool sales) => CurrencyChangeGuard.isBlocked(
      currentCode: 'INR',
      newCode: now,
      hasSales: sales,
    );
    expect(blocked('USD', true), isTrue);
    expect(blocked('INR', true), isFalse);
    expect(blocked('USD', false), isFalse);
  });

  test('role gate: admin edits, manager views, cashier nothing', () {
    expect(StoreConfigPermissions.canEdit('admin'), isTrue);
    expect(StoreConfigPermissions.canEdit('manager'), isFalse);
    expect(StoreConfigPermissions.canEdit('cashier'), isFalse);
    expect(StoreConfigPermissions.canEdit(null), isFalse);
    expect(StoreConfigPermissions.canView('manager'), isTrue);
    expect(StoreConfigPermissions.canView('cashier'), isFalse);
    expect(StoreConfigPermissions.canView(null), isFalse);
  });

  group('sample bill through the real pricing', () {
    TaxPreview preview(List<TaxComponent> comps, {bool inclusive = false}) =>
        TaxPreview.of(
          slab: _slab('s', comps, isDefault: true),
          currency: CurrencyRegistry.inr,
          priceMinor: 100000,
          inclusive: inclusive,
        );

    test('one component: tax row only', () {
      final p = preview(const [TaxComponent(label: 'VAT', rateBp: 1800)]);
      expect(p.subtotal.minor, 100000);
      expect(p.tax.minor, 18000);
      expect(p.total.minor, 118000);
      expect(p.parts, isEmpty);
    });

    test('two components: 9 + 9', () {
      final p = preview(const [
        TaxComponent(label: 'CGST', rateBp: 900),
        TaxComponent(label: 'SGST', rateBp: 900),
      ]);
      expect(p.tax.minor, 18000);
      expect([for (final x in p.parts) x.amount.minor], [9000, 9000]);
    });

    test('three components: VAT 16 + levy 3 + service 5', () {
      final p = preview(const [
        TaxComponent(label: 'VAT', rateBp: 1600),
        TaxComponent(label: 'Levy', rateBp: 300),
        TaxComponent(label: 'Service charge', rateBp: 500),
      ]);
      expect(p.tax.minor, 24000);
      expect([for (final x in p.parts) x.amount.minor], [16000, 3000, 5000]);
      expect(p.total.minor, 124000);
    });

    test('rounding happens once: the parts add up to the tax', () {
      final p = TaxPreview.of(
        slab: _slab('s', const [
          TaxComponent(label: 'A', rateBp: 333),
          TaxComponent(label: 'B', rateBp: 333),
          TaxComponent(label: 'C', rateBp: 334),
        ], isDefault: true),
        currency: CurrencyRegistry.inr,
        priceMinor: 9999,
      );
      expect(
        p.parts.map((x) => x.amount.minor).reduce((a, b) => a + b),
        p.tax.minor,
      );
    });

    test('a disabled component is not applied', () {
      final p = preview(const [
        TaxComponent(label: 'VAT', rateBp: 1800),
        TaxComponent(label: 'Levy', rateBp: 500, enabled: false),
      ]);
      expect(p.tax.minor, 18000);
      expect(p.parts, isEmpty);
    });
  });
}
