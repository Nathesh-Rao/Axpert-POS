// DEC-153: offers in the product form (rules, overlap, preview, atomic save).
import 'package:drift/drift.dart' show Variable;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:pos_application/core/database/axpert_database.dart';
import 'package:pos_application/core/identifiers/uuid_v4_generator.dart';
import 'package:pos_application/core/routes/app_routes.dart';
import 'package:pos_application/core/services/pricing/currency_registry.dart';
import 'package:pos_application/core/session/store_scope.dart';
import 'package:pos_application/features/inventory/data/drift_inventory_repository.dart';
import 'package:pos_application/features/offers/data/drift_offer_repository.dart';
import 'package:pos_application/features/offers/domain/entities/offer.dart';
import 'package:pos_application/features/offers/domain/entities/offer_draft.dart';
import 'package:pos_application/features/offers/domain/services/offer_draft_rules.dart';
import 'package:pos_application/features/offers/presentation/controllers/offer_editor_controller.dart';
import 'package:pos_application/features/offers/presentation/controllers/offers_controller.dart';
import 'package:pos_application/features/products/data/repositories/drift_product_admin_repository.dart';
import 'package:pos_application/features/products/domain/entities/product_admin_entities.dart';
import 'package:pos_application/features/products/presentation/controllers/product_admin_controller.dart';
import 'package:pos_application/features/products/presentation/controllers/product_form_controller.dart';
import 'package:pos_application/shared/controllers/overlay_controller.dart';

import '../../support/seeded_database.dart';
import '../../support/test_app.dart';
import '../../support/test_session.dart';
import '../../support/viewport.dart';

const _piece = '5a1f0001-0000-4000-8000-000000000001';

OfferDraft _discount({
  String? id,
  int percent = 2000,
  DateTime? from,
  DateTime? to,
  bool active = true,
}) => OfferDraft(
  id: id,
  kind: OfferKind.discount,
  name: 'Cola 20%',
  percentBp: percent,
  startsAt: from,
  endsAt: to,
  active: active,
);

ProductDraft _draft({List<OfferDraft> offers = const []}) => ProductDraft(
  name: 'Offer Cola',
  code: 'OFF001',
  priceMinor: 10000,
  gstBp: 1800,
  baseUnitId: _piece,
  category: 'Beverages',
  categoryId: 'demo-cat-1',
  barcodes: const ['9991111111111'],
  openingMilli: 10000,
  offers: offers,
);

Future<int> _count(
  AxpertDatabase db,
  String sql, [
  List<Object?> v = const [],
]) async =>
    (await db
            .customSelect(sql, variables: [for (final x in v) Variable(x)])
            .getSingle())
        .read<int>('c');

void main() {
  group('rules', () {
    const rules = OfferDraftRules();

    test('a discount needs exactly one value', () {
      expect(rules.validate(_discount()), isEmpty);
      expect(
        rules.validate(
          const OfferDraft(
            kind: OfferKind.discount,
            name: 'x',
            percentBp: 100,
            fixedMinor: 100,
          ),
        ),
        [OfferIssue.valueInvalid],
      );
      expect(rules.validate(_discount(percent: 10001)), [
        OfferIssue.valueInvalid,
      ]);
      expect(
        rules.validate(
          const OfferDraft(
            kind: OfferKind.giftTier,
            name: 'g',
            minCartMinor: 0,
          ),
        ),
        [OfferIssue.minCartInvalid],
      );
    });

    test('an end before the start and an empty name are refused', () {
      final issues = rules.validate(
        OfferDraft(
          kind: OfferKind.promotion,
          name: ' ',
          percentBp: 5000,
          startsAt: DateTime.utc(2026, 11),
          endsAt: DateTime.utc(2026, 10),
        ),
      );
      expect(
        issues,
        containsAll([OfferIssue.nameRequired, OfferIssue.dateOrder]),
      );
    });

    test('overlap: active offers with intersecting windows', () {
      final a = _discount(
        from: DateTime.utc(2026, 10),
        to: DateTime.utc(2026, 10, 20),
      );
      final b = _discount(from: DateTime.utc(2026, 10, 15));
      final c = _discount(from: DateTime.utc(2026, 11));
      expect(OfferOverlap.conflicting([a, b]), {0, 1});
      expect(OfferOverlap.conflicting([a, c]), isEmpty);
      expect(OfferOverlap.conflicting([a, b.copyWith(active: false)]), isEmpty);
      // A tier does not compete with a discount.
      const tier = OfferDraft(
        kind: OfferKind.giftTier,
        name: 't',
        minCartMinor: 100,
      );
      expect(OfferOverlap.conflicting([_discount(), tier]), isEmpty);
      expect(OfferOverlap.conflicting([tier, tier]), {0, 1});
    });
  });

  group('preview (real engine)', () {
    OfferEditorController make() => OfferEditorController(
      currency: () => CurrencyRegistry.inr,
      basePriceMinor: () => 10000,
      productId: () => 7,
      productName: () => 'Cola',
    )..init();

    test('percent discount, promotion and free item', () {
      final e = make()..beginAdd();
      e.value.text = '20';
      var p = e.preview()!;
      expect(p.badge, '-20%');
      expect(p.text, '₹100.00 to ₹80.00');
      e.kind.value = OfferKind.promotion;
      p = e.preview()!;
      expect(p.badge, 'Buy 1 Get 1');
      expect(p.text, '₹100.00 to ₹50.00');
      e.kind.value = OfferKind.giftTier;
      expect(e.preview(), isNull); // no minimum yet
      e.minCart.text = '500';
      p = e.preview()!;
      expect(p.badge, 'Free gift');
      expect(p.text, 'Free item from a cart of ₹500.00');
      e.dispose();
    });

    test('a fixed amount, apply and edit', () {
      final e = make()..beginAdd();
      e.mode.value = DiscountMode.amount;
      e.value.text = '15';
      expect(e.preview()!.text, '₹100.00 to ₹85.00');
      expect(e.apply(), isTrue);
      expect(e.offers.single.fixedMinor, 1500);
      expect(e.offers.single.name, e.offers.single.name.trim());
      e.beginEdit(0);
      expect(e.value.text, '15.00');
      e.value.text = '';
      expect(e.apply(), isFalse);
      expect(e.errors['value'], isNotNull);
      e.dispose();
    });

    test('dates must be YYYY-MM-DD and ordered', () {
      final e = make()..beginAdd();
      e.value.text = '10';
      e.starts.text = '2026-13-01';
      expect(e.apply(), isFalse);
      expect(e.errors['starts'], 'Use YYYY-MM-DD');
      e.starts.text = '2026-10-10';
      e.ends.text = '2026-10-01';
      expect(e.apply(), isFalse);
      expect(e.errors['ends'], 'The end is before the start');
      e.ends.text = '2026-10-31';
      expect(e.apply(), isTrue);
      expect(e.offers.single.endsAt!.hour, 23); // the whole end day
      e.dispose();
    });

    test('a second active offer in the window warns', () {
      final e = make()..load([_discount()]);
      e.beginAdd();
      e.value.text = '5';
      expect(e.candidateOverlaps, isTrue);
      e.active.value = false;
      expect(e.candidateOverlaps, isFalse);
      e.dispose();
    });
  });

  group('Drift: offers with the product', () {
    late AxpertDatabase db;
    late DriftProductAdminRepository repo;
    late DriftOfferRepository offers;

    setUp(() async {
      db = await seededDatabase();
      final provider = FixedDatabaseProvider(db);
      repo = DriftProductAdminRepository(
        provider: provider,
        uuid: UuidV4Generator(),
        scope: StoreScope()
          ..set(storeId: 'demo-store-ozone', currency: CurrencyRegistry.inr),
        inventory: DriftInventoryRepository(
          provider: provider,
          uuid: UuidV4Generator(),
        ),
      );
      offers = DriftOfferRepository(provider);
    });

    tearDown(() => db.close());

    test('offers are saved in the same transaction as the product', () async {
      final id = await repo.create(
        _draft(
          offers: [
            _discount(),
            const OfferDraft(
              kind: OfferKind.promotion,
              name: 'BOGO',
              percentBp: 5000,
            ),
            const OfferDraft(
              kind: OfferKind.giftTier,
              name: 'Free gift',
              minCartMinor: 50000,
            ),
          ],
        ),
      );
      final loaded = await offers.load(storeId: 'demo-store-ozone');
      final mine = loaded.where(
        (o) =>
            o.name == 'Cola 20%' || o.name == 'BOGO' || o.name == 'Free gift',
      );
      expect(mine.map((o) => o.kind).toSet(), {
        OfferKind.discount,
        OfferKind.promotion,
        OfferKind.giftTier,
      });
      final tier = mine.firstWhere((o) => o.kind == OfferKind.giftTier);
      expect(tier.gift!.name, 'Offer Cola');
      expect(tier.minCart!.minor, 50000);
      expect(
        await _count(
          db,
          'SELECT COUNT(*) AS c FROM offers WHERE (product_id = ? OR '
          'gift_product_id = ?) AND deleted_at IS NULL',
          [id, id],
        ),
        3,
      );
      expect(
        await _count(
          db,
          'SELECT COUNT(*) AS c FROM seed_manifest WHERE table_name = ? AND '
          'row_id IN (SELECT id FROM offers WHERE name = ?)',
          ['offers', 'BOGO'],
        ),
        0,
      );
    });

    test('a failing offer insert rolls the product back', () async {
      await db.customStatement(
        "CREATE TRIGGER boom BEFORE INSERT ON offers WHEN NEW.name = 'Bad' "
        "BEGIN SELECT RAISE(ABORT, 'boom'); END",
      );
      final before = await _count(db, 'SELECT COUNT(*) AS c FROM products');
      await expectLater(
        repo.create(
          _draft(
            offers: [
              _discount(),
              const OfferDraft(
                kind: OfferKind.promotion,
                name: 'Bad',
                percentBp: 5000,
              ),
            ],
          ),
        ),
        throwsA(anything),
      );
      expect(await _count(db, 'SELECT COUNT(*) AS c FROM products'), before);
      expect(
        await _count(
          db,
          "SELECT COUNT(*) AS c FROM offers WHERE name = 'Cola 20%'",
        ),
        0,
      );
      expect(
        await _count(
          db,
          "SELECT COUNT(*) AS c FROM product_barcodes WHERE barcode = '9991111111111'",
        ),
        0,
      );
    });

    test('invalid offers are refused', () async {
      await expectLater(
        repo.create(_draft(offers: [_discount(percent: 0)])),
        throwsA(isA<InvalidOfferException>()),
      );
    });

    test('edit, toggle and delete several offers; reseed keeps them', () async {
      final id = await repo.create(
        _draft(offers: [_discount(), _discount(percent: 500, active: false)]),
      );
      final legacy = (await repo.catalog()).last.product.id;
      var detail = (await repo.detail(legacy))!;
      expect(detail.offers.length, 2);
      final first = detail.offers.firstWhere((o) => o.percentBp == 2000);
      final second = detail.offers.firstWhere((o) => o.percentBp == 500);
      await repo.update(
        id,
        _draft(
          offers: [
            OfferDraft(
              id: first.id,
              kind: OfferKind.discount,
              name: 'Cola 25%',
              percentBp: 2500,
              active: false,
            ),
            // the second offer is removed
          ],
        ),
      );
      detail = (await repo.detail(legacy))!;
      expect(detail.offers.single.percentBp, 2500);
      expect(detail.offers.single.active, isFalse);
      expect(
        await _count(
          db,
          'SELECT COUNT(*) AS c FROM offers WHERE id = ? AND deleted_at IS NOT NULL',
          [second.id],
        ),
        1,
      );
      await seederFor(db).run(reseed: true);
      expect((await repo.detail(legacy))!.offers.single.name, 'Cola 25%');
    });

    test('the sales tile shows the new offer', () async {
      await repo.create(_draft(offers: [_discount()]));
      final loaded = await offers.load(storeId: 'demo-store-ozone');
      final product = (await repo.catalog()).last.product;
      final tile = OffersController.tileFor(
        loaded,
        product.inCurrency(CurrencyRegistry.inr),
        DateTime.now(),
      );
      expect(tile!.label, '-20%');
      expect(tile.salePrice!.minor, 8000);
    });
  });

  testWidgets('the offer editor works inside the form', (tester) async {
    useReferenceViewport(tester);
    final binding = await bootInWidgetTest(
      tester,
      session: roleSession('manager'),
    );
    await tester.pumpWidget(testApp(binding));
    await tester.pumpAndSettle();
    Get.offAllNamed<void>(AppRoutes.products);
    await tester.pumpAndSettle();
    Get.find<ProductAdminController>().openAdd();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final form = Get.find<ProductFormController>();
    expect(find.text('Offers & promotions'), findsOneWidget);
    expect(find.text('No offers yet'), findsOneWidget);
    form.price.text = '100';
    await tester.ensureVisible(find.text('Add offer').first);
    await tester.tap(find.text('Add offer').first);
    await tester.pumpAndSettle();
    final editor = form.offerEditor;
    editor.value.text = '20';
    await tester.pumpAndSettle();
    expect(find.text('₹100.00 to ₹80.00'), findsOneWidget);
    await tester.ensureVisible(find.text('Add offer').last);
    await tester.tap(find.text('Add offer').last);
    await tester.pumpAndSettle();
    expect(editor.offers.length, 1);
    expect(find.text('-20%'), findsOneWidget);
    // A second overlapping offer shows the warning on both rows.
    editor.beginAdd();
    editor.value.text = '5';
    await tester.pumpAndSettle();
    expect(
      find.text('Overlaps another active offer: only one of them applies'),
      findsOneWidget,
    );
    editor.apply();
    await tester.pumpAndSettle();
    expect(
      find.text('Overlaps another active offer: only one of them applies'),
      findsNWidgets(2),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(Get.find<OverlayController>().isOpen, isFalse);
  });
}
