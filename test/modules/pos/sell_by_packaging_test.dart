// DEC-154: selling by packaging on the sales screen: unit options and prices,
// adding a packaging, switching and cycling the unit, scan by pack barcode
// (strictly in order), the receipt line and the widgets.
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/services/pricing/qty.dart';
import 'package:pos_application/core/shortcuts/shortcut_controller.dart';
import 'package:pos_application/features/products/domain/entities/packaging_entities.dart';
import 'package:pos_application/features/products/domain/repositories/packaging_repositories.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/packaging_catalog_controller.dart';
import 'package:pos_application/modules/pos/controllers/scan_controller.dart';
import 'package:pos_application/modules/pos/controllers/unit_switch_controller.dart';
import 'package:pos_application/modules/pos/models/line_key.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';
import 'package:pos_application/shared/controllers/search_field_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import '../../support/pos_support.dart';
import '../../support/test_app.dart';
import '../../support/viewport.dart';

const _ctn = LineKey(0, 'ctn');
const _pack = LineKey(0, 'pk6');

SellableUnits _units() => const SellableUnits(
  baseUnitName: 'Piece',
  packagings: <ProductPackaging>[
    ProductPackaging(
      id: 'pk6',
      productId: 'uuid-0',
      unitId: 'u-pack',
      name: 'Pack',
      quantityBaseMilli: 6000,
      priceMinor: 22000, // explicit: cheaper than 6 x 40.00
    ),
    ProductPackaging(
      id: 'ctn',
      productId: 'uuid-0',
      unitId: 'u-ctn',
      name: 'Carton',
      quantityBaseMilli: 24000,
    ),
  ],
);

/// Resolves barcodes from a map; [delays] holds a lookup until completed.
class _FakeBarcodes implements BarcodeRepository {
  _FakeBarcodes(this.matches);

  final Map<String, BarcodeMatch> matches;
  final Map<String, Completer<void>> gates = <String, Completer<void>>{};
  final List<String> asked = <String>[];
  bool fail = false;

  @override
  Future<BarcodeMatch?> findByBarcode(String? storeId, String barcode) async {
    asked.add(barcode);
    await gates[barcode]?.future;
    if (fail) throw StateError('database unavailable');
    return matches[barcode];
  }

  @override
  Future<List<ProductBarcode>> forProduct(String productId) async => const [];

  @override
  Future<void> save(ProductBarcode barcode) async {}

  @override
  Future<void> remove(String id) async {}
}

BarcodeMatch _cartonMatch() => const BarcodeMatch(
  productId: 'uuid-0',
  productLegacyId: 0,
  barcode: 'CTN-0',
  packaging: ProductPackaging(
    id: 'ctn',
    productId: 'uuid-0',
    unitId: 'u-ctn',
    name: 'Carton',
    quantityBaseMilli: 24000,
  ),
);

BarcodeMatch _packMatch() => const BarcodeMatch(
  productId: 'uuid-0',
  productLegacyId: 0,
  barcode: 'PK-0',
  packaging: ProductPackaging(
    id: 'pk6',
    productId: 'uuid-0',
    unitId: 'u-pack',
    name: 'Pack',
    quantityBaseMilli: 6000,
  ),
);

ScanController _scan(_FakeBarcodes barcodes) => ScanController(
  products: Get.find(),
  actions: Get.find(),
  toasts: Get.find(),
  search: Get.find<SearchFieldController>(),
  overlay: Get.find<OverlayController>(),
  barcodes: barcodes,
  catalog: Get.find<PackagingCatalogController>(),
);

void main() {
  useTestApp();

  group('options and prices', () {
    test('base unit first, package price derived or explicit', () async {
      final h = await PosHarness.boot();
      final catalog = Get.find<PackagingCatalogController>()
        ..seed(<int, SellableUnits>{0: _units()});
      final product = h.products.byId(0)!;
      final options = catalog.optionsFor(product);
      expect(options.map((o) => o.name), <String>['Piece', 'Pack', 'Carton']);
      expect(options[0].price, product.price);
      expect(options[1].price.minor, 22000);
      expect(options[2].price.minor, product.price.minor * 24);
      expect(catalog.hasPackagings(0), isTrue);
      expect(catalog.hasPackagings(1), isFalse);
      expect(catalog.optionsFor(h.products.byId(1)!).length, 1);
    });
  });

  group('adding and switching', () {
    test(
      'a carton adds its own line; pieces stay apart; stock is base',
      () async {
        final h = await PosHarness.boot();
        final catalog = Get.find<PackagingCatalogController>()
          ..seed(<int, SellableUnits>{0: _units()});
        final unit = Get.find<UnitSwitchController>();
        final product = h.products.byId(0)!;
        final options = catalog.optionsFor(product);
        expect(h.actions.add(product), isTrue);
        expect(unit.add(product, options[2]), isTrue);
        final lines = h.cart.cart.value.lines;
        expect(lines.map((l) => l.key), <LineKey>[const LineKey(0), _ctn]);
        expect(lines[1].qty, Qty.units(1));
        expect(lines[1].price.minor, product.price.minor * 24);
        expect(h.toasts.toasts.last.text, 'Coca Cola 500ml (Carton) added');
        expect(h.selection.selected.value, _ctn);
        expect(h.cart.cart.value.baseQtyOf(0), Qty.units(25));
        // Stock is in base units across both lines: a second carton (49) is
        // refused.
        expect(product.stock, lessThan(49));
        expect(unit.add(product, options[2]), isFalse);
        expect(h.toasts.toasts.last.kind, ToastKind.warning);
      },
    );

    test(
      'switching a row converts the unit, merges and respects stock',
      () async {
        final h = await PosHarness.boot();
        final catalog = Get.find<PackagingCatalogController>()
          ..seed(<int, SellableUnits>{0: _units()});
        final unit = Get.find<UnitSwitchController>();
        final product = h.products.byId(0)!;
        final options = catalog.optionsFor(product);
        h.actions.add(product);
        unit.switchLine(h.cart.lineOf(const LineKey(0))!, options[1]);
        expect(h.cart.cart.value.lines.single.key, _pack);
        expect(h.cart.cart.value.lines.single.price.minor, 22000);
        expect(h.selection.selected.value, _pack);
        // Back to pieces.
        unit.switchLine(h.cart.lineOf(_pack)!, options[0]);
        expect(h.cart.cart.value.lines.single.key, const LineKey(0));
        // A carton (24) does not fit next to 20 pieces of a stock of 40? It
        // does: 20 pieces become 20 cartons only if stock allows (480) - no.
        h.cart.setQty(const LineKey(0), Qty.units(5));
        unit.switchLine(h.cart.lineOf(const LineKey(0))!, options[2]);
        expect(
          h.cart.cart.value.lines.single.key,
          const LineKey(0),
          reason: '5 cartons = 120 base units, over the stock',
        );
        expect(h.toasts.toasts.last.kind, ToastKind.warning);
      },
    );

    test('Ctrl/Cmd+Shift+U cycles the unit of the selected row', () async {
      final h = await PosHarness.boot();
      Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
        0: _units(),
      });
      h.actions.add(h.products.byId(0)!);
      final run =
          Get.find<ShortcutController>().handlers[ShortcutAction.cycleUnit]!;
      run();
      expect(h.cart.cart.value.lines.single.key, _pack);
      run();
      expect(
        h.cart.cart.value.lines.single.key,
        _ctn.productId == 0 ? _ctn : _ctn,
      );
      run();
      expect(h.cart.cart.value.lines.single.key, const LineKey(0));
    });

    test('a product without packagings never changes unit', () async {
      final h = await PosHarness.boot();
      h.actions.add(h.products.byId(1)!);
      Get.find<UnitSwitchController>().cycleSelected();
      expect(h.cart.cart.value.lines.single.key, const LineKey(1));
    });
  });

  group('scan', () {
    test(
      'a pack barcode adds the packaging line, with the unit in the toast',
      () async {
        final h = await PosHarness.boot();
        Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
          0: _units(),
        });
        final scan = _scan(
          _FakeBarcodes(<String, BarcodeMatch>{'CTN-0': _cartonMatch()}),
        );
        await scan.scanProduct('CTN-0');
        final line = h.cart.cart.value.lines.single;
        expect(line.key, _ctn);
        expect(line.price.minor, h.products.byId(0)!.price.minor * 24);
        expect(h.toasts.toasts.last.text, 'Coca Cola 500ml (Carton) added');
      },
    );

    test('a base barcode and a code still add the base unit', () async {
      final h = await PosHarness.boot();
      final barcodes = _FakeBarcodes(<String, BarcodeMatch>{});
      final scan = _scan(barcodes);
      final product = h.products.byId(0)!;
      await scan.scanProduct(product.barcode);
      expect(h.cart.cart.value.lines.single.key, const LineKey(0));
      expect(barcodes.asked, isEmpty, reason: 'a base barcode needs no lookup');
      await scan.scanProduct(product.code.toLowerCase());
      expect(h.cart.cart.value.lines.single.qty, Qty.units(2));
      await scan.scanProduct('nope');
      expect(h.toasts.toasts.last.kind, ToastKind.error);
    });

    test('a failing lookup falls back to the product list', () async {
      final h = await PosHarness.boot();
      final barcodes = _FakeBarcodes(<String, BarcodeMatch>{})..fail = true;
      await _scan(barcodes).scanProduct(h.products.byId(1)!.code);
      expect(h.cart.cart.value.lines.single.key, const LineKey(1));
    });

    test('a pack barcode of a disabled packaging is not found', () async {
      final h = await PosHarness.boot();
      // Catalog without the carton: only the base unit is sellable.
      Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{});
      final scan = _scan(
        _FakeBarcodes(<String, BarcodeMatch>{'CTN-0': _cartonMatch()}),
      );
      await scan.scanProduct('CTN-0');
      expect(h.cart.cart.value.lines, isEmpty);
      expect(h.toasts.toasts.last.kind, ToastKind.error);
    });

    test('two rapid scans keep their order and never double-add', () async {
      final h = await PosHarness.boot();
      Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
        0: _units(),
      });
      final barcodes = _FakeBarcodes(<String, BarcodeMatch>{
        'CTN-0': _cartonMatch(),
      });
      // The carton lookup is slow; the base barcode is scanned right after.
      barcodes.gates['CTN-0'] = Completer<void>();
      final scan = _scan(barcodes);
      final first = scan.scanProduct('CTN-0');
      final second = scan.scanProduct(h.products.byId(0)!.barcode);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(h.cart.cart.value.lines, isEmpty, reason: 'the second waits');
      barcodes.gates['CTN-0']!.complete();
      await Future.wait(<Future<void>>[first, second]);
      expect(h.cart.cart.value.lines.map((l) => l.key), <LineKey>[
        _ctn,
        const LineKey(0),
      ]);
      expect(h.cart.cart.value.lines.map((l) => l.qty), <Qty>[
        Qty.units(1),
        Qty.units(1),
      ]);
    });

    test(
      'the same pack barcode twice in a row adds two packs, once each',
      () async {
        final h = await PosHarness.boot();
        Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
          0: _units(),
        });
        final barcodes = _FakeBarcodes(<String, BarcodeMatch>{
          'PK-0': _packMatch(),
        });
        barcodes.gates['PK-0'] = Completer<void>();
        final scan = _scan(barcodes);
        final a = scan.scanProduct('PK-0');
        final b = scan.scanProduct('PK-0');
        barcodes.gates['PK-0']!.complete();
        await Future.wait(<Future<void>>[a, b]);
        expect(h.cart.cart.value.lines.single.qty, Qty.units(2));
      },
    );
  });

  group('widgets', () {
    Future<void> boot(WidgetTester tester) async {
      useReferenceViewport(tester);
      final binding = await bootInWidgetTest(tester);
      await tester.pumpWidget(testApp(binding));
      await tester.pumpAndSettle();
    }

    testWidgets('only a product with packagings shows the pack chip', (
      tester,
    ) async {
      await boot(tester);
      Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
        0: _units(),
      });
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Sell Coca Cola 500ml by pack or carton (3 units)'),
        findsOneWidget,
      );
      expect(
        find.byTooltip('Sell Pepsi 500ml by pack or carton (1 units)'),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('the tile chip opens the list and adds the picked unit', (
      tester,
    ) async {
      await boot(tester);
      Get.find<PackagingCatalogController>().seed(<int, SellableUnits>{
        0: _units(),
      });
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip('Sell Coca Cola 500ml by pack or carton (3 units)'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Carton of 24'), findsOneWidget);
      expect(find.text('Pack of 6'), findsOneWidget);
      await tester.tap(find.text('Carton of 24'));
      await tester.pump();
      final cart = Get.find<CartController>().cart.value;
      expect(cart.lines.single.key, _ctn);
      // The tile badge counts base units when only packagings are held.
      expect(find.text('x24'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('the cart row shows the unit chip; picking switches the unit', (
      tester,
    ) async {
      await boot(tester);
      final catalog = Get.find<PackagingCatalogController>()
        ..seed(<int, SellableUnits>{0: _units()});
      final product = Get.find<CartController>().cart.value.lines.isEmpty
          ? null
          : null;
      expect(product, isNull);
      Get.find<UnitSwitchController>().add(
        Get.find<UnitSwitchController>().products.byId(0)!,
        catalog.optionsFor(
          Get.find<UnitSwitchController>().products.byId(0)!,
        )[2],
      );
      await tester.pumpAndSettle();
      final chip = find.byTooltip('Change the unit of Coca Cola 500ml');
      expect(chip, findsOneWidget);
      expect(find.text('Carton of 24'), findsWidgets);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pack of 6').last);
      await tester.pumpAndSettle();
      expect(Get.find<CartController>().cart.value.lines.single.key, _pack);
      await tester.pump(const Duration(seconds: 6));
    });

    testWidgets('Ctrl+Shift+U and Cmd+Shift+U cycle the unit', (tester) async {
      await boot(tester);
      final catalog = Get.find<PackagingCatalogController>()
        ..seed(<int, SellableUnits>{0: _units()});
      final unit = Get.find<UnitSwitchController>();
      unit.add(
        unit.products.byId(0)!,
        catalog.optionsFor(unit.products.byId(0)!)[0],
      );
      await tester.pumpAndSettle();
      final cart = Get.find<CartController>();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(cart.cart.value.lines.single.key, _pack, reason: 'Ctrl');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyU);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();
      expect(cart.cart.value.lines.single.key, _ctn, reason: 'Cmd');
      await tester.pump(const Duration(seconds: 6));
    });
  });
}
