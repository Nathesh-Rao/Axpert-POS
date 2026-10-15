import '../../../../core/services/pricing/basis_points.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/currency_registry.dart';
import '../../../../core/services/pricing/money.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../../domain/repositories/product_admin_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/services/product_draft_validator.dart';
import 'mock_packaging_repositories.dart';

class _Row {
  _Row(this.uuid, this.product, this.draft);

  final String uuid;
  Product product;
  ProductDraft draft;
  bool active = true;
  int balanceMilli = 0;
}

/// Product management in memory (tests, sessions without a database). Same
/// rules as the Drift implementation: validation, barcode uniqueness per
/// store, soft delete, stock only through [adjustStock]. Created products are
/// also written to [products] so the catalog sees them.
class MockProductAdminRepository implements ProductAdminRepository {
  MockProductAdminRepository({
    required ProductRepository products,
    Currency currency = CurrencyRegistry.inr,
    this.validator = const ProductDraftValidator(),
    this.allowNegative = false,
  }) : _products = products,
       _currency = currency;

  final ProductRepository _products;
  final Currency _currency;
  final ProductDraftValidator validator;
  final bool allowNegative;

  final Map<String, _Row> _rows = <String, _Row>{};
  final List<CategoryInfo> _categories = <CategoryInfo>[];
  int _seq = 0;

  /// Rows of the stock ledger written by [adjustStock] (tests read them).
  final List<({String uuid, int deltaMilli, AdjustmentReason reason})> ledger =
      [];

  String _id() => 'mock-${_seq++}';

  Set<String> _taken({String? except}) => {
    for (final r in _rows.values)
      if (r.active && r.uuid != except) ...[
        ...r.draft.barcodes,
        for (final p in r.draft.packagings)
          if ((p.barcode ?? '').isNotEmpty) p.barcode!,
      ],
  };

  void _check(ProductDraft d, {String? except}) {
    final problems = validator.validate(d);
    if (problems.isNotEmpty) throw InvalidProductException(problems);
    final taken = _taken(except: except);
    for (final code in [
      ...d.barcodes,
      for (final p in d.packagings) p.barcode ?? '',
    ]) {
      if (code.isNotEmpty && taken.contains(code)) {
        throw DuplicateBarcodeException(code);
      }
    }
  }

  Product _product(int id, ProductDraft d, {int? stock, bool? favourite}) =>
      Product(
        id: id,
        name: d.name.trim(),
        code: d.code.trim(),
        barcode: d.barcodes.firstWhere((b) => b.isNotEmpty, orElse: () => ''),
        price: Money(d.priceMinor, _currency),
        category: d.category,
        sub: d.sub,
        stock: stock ?? 0,
        gst: Bp(d.gstBp),
        image: -1,
        favourite: favourite ?? false,
      );

  @override
  Future<String> create(ProductDraft draft) async {
    _check(draft);
    final list = await _products.load();
    final id = list.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
    final uuid = _id();
    final row = _Row(
      uuid,
      _product(id, draft, stock: draft.openingMilli ~/ 1000),
      draft,
    )..balanceMilli = draft.openingMilli;
    _rows[uuid] = row;
    await _products.save([...list, row.product]);
    return uuid;
  }

  @override
  Future<void> update(String uuid, ProductDraft draft) async {
    final row = _rows[uuid]!;
    _check(draft, except: uuid);
    final list = await _products.load();
    final updated = _product(
      row.product.id,
      draft,
      stock: row.product.stock,
      favourite: row.product.favourite,
    );
    await _products.save([
      for (final p in list) p.id == updated.id ? updated : p,
    ]);
    row
      ..product = updated
      ..draft = draft;
  }

  @override
  Future<void> deactivate(String uuid) async {
    final row = _rows[uuid]!..active = false;
    final list = await _products.load();
    await _products.save([
      for (final p in list)
        if (p.id != row.product.id) p,
    ]);
  }

  @override
  Future<void> reactivate(String uuid) async {
    final row = _rows[uuid]!;
    _check(row.draft, except: uuid);
    row.active = true;
    final list = await _products.load();
    await _products.save([...list, row.product]);
  }

  @override
  Future<void> adjustStock({
    required String uuid,
    required int deltaMilli,
    required AdjustmentReason reason,
    required String note,
    String? userId,
  }) async {
    final row = _rows[uuid]!;
    final after = row.balanceMilli + deltaMilli;
    if (after < 0 && !allowNegative) {
      throw AdjustmentBlockedException(row.balanceMilli);
    }
    row.balanceMilli = after;
    ledger.add((uuid: uuid, deltaMilli: deltaMilli, reason: reason));
    row.product = Product(
      id: row.product.id,
      name: row.product.name,
      code: row.product.code,
      barcode: row.product.barcode,
      price: row.product.price,
      category: row.product.category,
      sub: row.product.sub,
      stock: (after / 1000).floor(),
      gst: row.product.gst,
      image: row.product.image,
      favourite: row.product.favourite,
    );
    final list = await _products.load();
    await _products.save([
      for (final p in list) p.id == row.product.id ? row.product : p,
    ]);
  }

  @override
  Future<ProductDetail?> detail(int legacyId) async {
    for (final r in _rows.values) {
      if (r.product.id != legacyId) continue;
      return ProductDetail(
        uuid: r.uuid,
        product: r.product,
        baseUnitId: r.draft.baseUnitId,
        brandId: r.draft.brandId,
        categoryId: r.draft.categoryId,
        barcodes: r.draft.barcodes,
        packagings: [
          for (var i = 0; i < r.draft.packagings.length; i++)
            ProductPackaging(
              id: r.draft.packagings[i].id ?? '${r.uuid}-p$i',
              productId: r.uuid,
              unitId: r.draft.packagings[i].unitId,
              name: r.draft.packagings[i].name,
              quantityBaseMilli: r.draft.packagings[i].quantityBaseMilli,
              sku: r.draft.packagings[i].sku,
              priceMinor: r.draft.packagings[i].priceMinor,
              sortOrder: i,
              enabled: r.draft.packagings[i].enabled,
            ),
        ],
        packagingBarcodes: {
          for (var i = 0; i < r.draft.packagings.length; i++)
            if ((r.draft.packagings[i].barcode ?? '').isNotEmpty)
              r.draft.packagings[i].id ?? '${r.uuid}-p$i':
                  r.draft.packagings[i].barcode!,
        },
        balanceMilli: r.balanceMilli,
        active: r.active,
      );
    }
    return null;
  }

  @override
  Future<List<CatalogRow>> catalog() async {
    final live = {for (final p in await _products.load()) p.id: p};
    return [
      for (final p in live.values) CatalogRow(product: p, active: true),
      for (final r in _rows.values)
        if (!r.active) CatalogRow(product: r.product, active: false),
    ];
  }

  @override
  Future<Map<int, StockView>> stockViews() async {
    final unit = MockUnitRepository.units.firstWhere((u) => u.code == 'piece');
    return {
      for (final p in await _products.load())
        p.id: StockView(
          balanceMilli: _byLegacy(p.id)?.balanceMilli ?? p.stock * 1000,
          baseUnitName: unit.name,
          levels: [
            for (final pk in _byLegacy(p.id)?.draft.packagings ?? const [])
              if (pk.enabled)
                (name: pk.name, quantityBaseMilli: pk.quantityBaseMilli),
          ],
        ),
    };
  }

  _Row? _byLegacy(int id) {
    for (final r in _rows.values) {
      if (r.product.id == id) return r;
    }
    return null;
  }

  @override
  Future<List<CategoryInfo>> categories() async => List.of(_categories);

  @override
  Future<CategoryInfo> createCategory(String name, {String? parentId}) async {
    final info = CategoryInfo(id: _id(), name: name.trim(), parentId: parentId);
    _categories.add(info);
    return info;
  }
}
