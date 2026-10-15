import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/identifiers/uuid_generator.dart';
import '../../../../core/services/packaging/packaging_service.dart';
import '../../../../core/services/pricing/currency.dart';
import '../../../../core/services/pricing/currency_registry.dart';
import '../../../../core/services/pricing/qty.dart';
import '../../../../core/utils/decimal_input.dart';
import '../../../../core/utils/decimal_text.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/qty_formatter.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/toast_controller.dart';
import '../../../session/presentation/controllers/active_session.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../../domain/repositories/packaging_repositories.dart';
import '../../domain/services/product_draft_validator.dart';
import '../stock_text.dart';
import 'product_admin_controller.dart';

/// One packaging row of the form (its text boxes live as long as the form).
class PackagingRowState {
  PackagingRowState({
    this.id,
    String? unitId,
    String factor = '',
    String sku = '',
    String barcode = '',
    String price = '',
    bool enabled = true,
  }) : unitId = Rxn<String>(unitId),
       enabledOn = enabled.obs,
       factor = TextEditingController(text: factor),
       sku = TextEditingController(text: sku),
       barcode = TextEditingController(text: barcode),
       price = TextEditingController(text: price);

  final String? id;
  final Rxn<String> unitId;
  final RxBool enabledOn;
  final TextEditingController factor;
  final TextEditingController sku;
  final TextEditingController barcode;
  final TextEditingController price;

  /// Whole packages of this unit in the stock entry (integer text).
  final TextEditingController stockCount = TextEditingController();

  void dispose() {
    factor.dispose();
    sku.dispose();
    barcode.dispose();
    price.dispose();
    stockCount.dispose();
  }
}

/// "1 carton = 24 pcs = 2,400.00" for one row.
class PackagingPreview {
  const PackagingPreview({required this.text, required this.derived});

  final String text;

  /// The price comes from the base price (blank override).
  final bool derived;
}

/// The product form (transient: created when it opens, kept while the stock
/// dialog is shown on top, replaced by the next open). Holds the text boxes,
/// validates through [ProductDraftValidator] and saves through
/// [ProductAdminController]; no widget code and no SQL.
class ProductFormController extends GetxController {
  ProductFormController({
    required this.admin,
    required this.units,
    required this.brands,
    required this.session,
    required this.overlay,
    required this.toasts,
    required this.uuid,
    this.editing,
    this.validator = const ProductDraftValidator(),
  });

  final ProductAdminController admin;
  final UnitRepository units;
  final BrandRepository brands;
  final ActiveSession session;
  final OverlayController overlay;
  final ToastController toasts;
  final UuidGenerator uuid;

  /// The product being edited; null = a new one.
  final Product? editing;
  final ProductDraftValidator validator;
  final PackagingService _packaging = const PackagingService();

  bool get isEdit => editing != null;

  // ---- text boxes ----
  final TextEditingController name = TextEditingController();
  final TextEditingController sku = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController barcodeInput = TextEditingController();
  final TextEditingController newCategory = TextEditingController();
  final TextEditingController newSub = TextEditingController();
  final TextEditingController newBrand = TextEditingController();

  /// Base-unit part of the stock entry (decimal text).
  final TextEditingController stockBase = TextEditingController();

  // ---- choices ----
  final RxBool loading = true.obs;
  final RxBool saving = false.obs;
  final RxBool active = true.obs;
  final RxList<MeasureUnit> unitList = <MeasureUnit>[].obs;
  final RxList<Brand> brandList = <Brand>[].obs;
  final RxList<CategoryInfo> categoryList = <CategoryInfo>[].obs;
  final Rxn<String> categoryId = Rxn<String>();
  final RxString sub = ''.obs;
  final Rxn<String> brandId = Rxn<String>();
  final Rxn<String> baseUnitId = Rxn<String>();
  final Rxn<int> gstBp = Rxn<int>();
  final RxList<String> barcodes = <String>[].obs;
  final RxList<PackagingRowState> packagings = <PackagingRowState>[].obs;
  final RxBool creatingCategory = false.obs;
  final RxBool creatingSub = false.obs;
  final RxBool creatingBrand = false.obs;

  /// Field key -> message (`name`, `sku`, `price`, `unit`, `tax`, `barcodes`,
  /// `opening`, `p<i>.factor`, `p<i>.unit`, `p<i>.barcode`, `p<i>.price`).
  final RxMap<String, String> errors = <String, String>{}.obs;

  /// Bumped when any text box changes, so previews refresh once.
  final RxInt tick = 0.obs;

  /// What the edit form shows as the current stock.
  final RxString currentStock = ''.obs;
  String? _uuid;

  String? get productUuid => _uuid;

  Currency get currency => session.currency ?? CurrencyRegistry.inr;

  List<int> get taxRates => [
    for (final s in session.regime.value?.slabs ?? const []) s.rateBp,
  ];

  List<CategoryInfo> get topCategories => [
    for (final c in categoryList)
      if (c.parentId == null) c,
  ];

  List<CategoryInfo> get subCategories => [
    for (final c in categoryList)
      if (c.parentId != null && c.parentId == categoryId.value) c,
  ];

  MeasureUnit? unitById(String? id) {
    for (final u in unitList) {
      if (u.id == id) return u;
    }
    return null;
  }

  String get baseUnitName => unitById(baseUnitId.value)?.name ?? '';

  /// Loads the lists (and the product when editing); call right after the
  /// controller is created, outside of build.
  Future<void> load() async {
    for (final c in <TextEditingController>[name, sku, price, stockBase]) {
      c.addListener(_changed);
    }
    final unitRows = await units.all();
    unitList.assignAll(unitRows);
    brandList.assignAll(await brands.all());
    categoryList.assignAll(await admin.repository.categories());
    final piece = unitRows.where((u) => u.code == 'piece');
    baseUnitId.value = piece.isEmpty ? null : piece.first.id;
    final rates = taxRates;
    gstBp.value = rates.isEmpty ? null : rates.first;
    final product = editing;
    if (product != null) {
      final detail = await admin.repository.detail(product.id);
      if (detail != null) _fill(detail);
    }
    loading.value = false;
  }

  void _fill(ProductDetail d) {
    _uuid = d.uuid;
    active.value = d.active;
    name.text = d.product.name;
    sku.text = d.product.code;
    price.text = DecimalText.fixed(d.product.price.minor, currency.exponent);
    categoryId.value = d.categoryId;
    sub.value = d.product.sub;
    brandId.value = d.brandId;
    baseUnitId.value = d.baseUnitId;
    final rate = d.product.gst.value;
    gstBp.value = rate;
    barcodes.assignAll(d.barcodes);
    packagings.assignAll([
      for (final p in d.packagings)
        PackagingRowState(
          id: p.id,
          unitId: p.unitId,
          factor: QtyFormatter.compact(Qty(p.quantityBaseMilli)),
          sku: p.sku ?? '',
          barcode: d.packagingBarcodes[p.id] ?? '',
          price: p.priceMinor == null
              ? ''
              : DecimalText.fixed(p.priceMinor!, currency.exponent),
          enabled: p.enabled,
        ),
    ]);
    packagings.forEach(_listen);
    currentStock.value = _stockOf(d.balanceMilli, d.packagings);
  }

  String _stockOf(int milli, List<ProductPackaging> list) =>
      stockText(AppStrings.current, milli, [
        for (final p in list)
          if (p.enabled) (name: p.name, quantityBaseMilli: p.quantityBaseMilli),
      ], baseUnitName);

  /// Re-reads the stock after an adjustment made from the stock dialog.
  Future<void> refreshStock() async {
    final product = editing;
    if (product == null) return;
    final d = await admin.repository.detail(product.id);
    if (d != null) currentStock.value = _stockOf(d.balanceMilli, d.packagings);
  }

  void _changed() => tick.value++;

  // ---- barcodes ----

  void addBarcode() {
    final code = barcodeInput.text.trim();
    if (code.isEmpty) return;
    if (!barcodes.contains(code)) barcodes.add(code);
    barcodeInput.clear();
  }

  void removeBarcode(String code) => barcodes.remove(code);

  // ---- inline create ----

  Future<void> createCategory() async {
    final text = newCategory.text.trim();
    if (text.isEmpty) return;
    final created = await admin.repository.createCategory(text);
    categoryList.add(created);
    categoryId.value = created.id;
    sub.value = '';
    newCategory.clear();
    creatingCategory.value = false;
  }

  Future<void> createSub() async {
    final parent = categoryId.value;
    final text = newSub.text.trim();
    if (text.isEmpty || parent == null) return;
    final created = await admin.repository.createCategory(
      text,
      parentId: parent,
    );
    categoryList.add(created);
    sub.value = created.name;
    newSub.clear();
    creatingSub.value = false;
  }

  Future<void> createBrand() async {
    final text = newBrand.text.trim();
    if (text.isEmpty) return;
    final brand = Brand(id: uuid.generate(), name: text);
    await brands.save(brand);
    brandList.add(brand);
    brandId.value = brand.id;
    newBrand.clear();
    creatingBrand.value = false;
  }

  // ---- packagings ----

  void addPackaging() {
    final used = {for (final p in packagings) p.unitId.value};
    final base = baseUnitId.value;
    final next = unitList.firstWhereOrNull(
      (u) => u.id != base && !used.contains(u.id),
    );
    final row = PackagingRowState(unitId: next?.id);
    _listen(row);
    packagings.add(row);
  }

  void _listen(PackagingRowState row) {
    for (final c in [row.factor, row.price, row.stockCount, row.barcode]) {
      c.addListener(_changed);
    }
    row.unitId.listen((_) => _changed());
  }

  void removePackaging(PackagingRowState row) {
    packagings.remove(row);
    row.dispose();
    tick.value++;
  }

  /// The live line under a row, or null while the factor is not a number.
  PackagingPreview? previewOf(PackagingRowState row) {
    tick.value; // ignore: unnecessary_statements
    final factor = DecimalInput.tryScaled(row.factor.text, 3);
    final base = DecimalInput.tryScaled(price.text, currency.exponent);
    final unit = unitById(row.unitId.value);
    if (factor == null || factor <= 0 || base == null || unit == null) {
      return null;
    }
    final override = DecimalInput.tryScaled(row.price.text, currency.exponent);
    final minor = _packaging.packagePriceMinor(
      basePriceMinor: base,
      factorMilli: factor,
      explicitMinor: override,
    );
    return PackagingPreview(
      text: AppStrings.current.productPackagingPreview(
        unit.name,
        QtyFormatter.compact(Qty(factor)),
        baseUnitName,
        MoneyFormatter.formatMinor(minor, currency),
      ),
      derived: override == null,
    );
  }

  // ---- stock entry (create) ----

  int? get _stockMilli {
    var total = 0;
    final base = stockBase.text.trim();
    if (base.isNotEmpty) {
      final v = DecimalInput.tryScaled(base, 3);
      if (v == null) return null;
      total += v;
    }
    for (final row in packagings) {
      final count = row.stockCount.text.trim();
      if (count.isEmpty) continue;
      final n = int.tryParse(count);
      final factor = DecimalInput.tryScaled(row.factor.text, 3);
      if (n == null || n < 0 || factor == null || factor <= 0) return null;
      total += n * factor;
    }
    return total;
  }

  /// "= 77 pcs" under the stock entry, or null while it is empty or invalid.
  String? stockTotalText() {
    tick.value; // ignore: unnecessary_statements
    final milli = _stockMilli;
    if (milli == null) return null;
    return AppStrings.current.productStockTotal(
      stockText(AppStrings.current, milli, const [], baseUnitName),
    );
  }

  // ---- save ----

  ProductDraft? _draft() {
    final s = AppStrings.current;
    errors.clear();
    final basePrice = DecimalInput.tryScaled(price.text, currency.exponent);
    if (basePrice == null) errors['price'] = s.productErrPrice();
    if (gstBp.value == null) errors['tax'] = s.productErrTax();
    final opening = isEdit ? 0 : _stockMilli;
    if (opening == null) errors['opening'] = s.productErrOpening();
    final rows = <PackagingDraft>[];
    for (var i = 0; i < packagings.length; i++) {
      final row = packagings[i];
      final unit = unitById(row.unitId.value);
      final factor = DecimalInput.tryScaled(row.factor.text, 3);
      if (unit == null) errors['p$i.unit'] = s.productErrUnit();
      if (factor == null) errors['p$i.factor'] = s.productErrFactor();
      final priceText = row.price.text.trim();
      final override = priceText.isEmpty
          ? null
          : DecimalInput.tryScaled(priceText, currency.exponent);
      if (priceText.isNotEmpty && override == null) {
        errors['p$i.price'] = s.productErrPrice();
      }
      rows.add(
        PackagingDraft(
          id: row.id,
          unitId: row.unitId.value ?? '',
          name: unit?.name ?? '',
          quantityBaseMilli: factor ?? 0,
          sku: row.sku.text.trim(),
          barcode: row.barcode.text.trim(),
          priceMinor: override,
          enabled: row.enabledOn.value,
        ),
      );
    }
    final category = categoryList.firstWhereOrNull(
      (c) => c.id == categoryId.value,
    );
    final draft = ProductDraft(
      name: name.text,
      code: sku.text,
      priceMinor: basePrice ?? 0,
      gstBp: gstBp.value ?? 0,
      baseUnitId: baseUnitId.value ?? '',
      categoryId: categoryId.value,
      category: category?.name ?? '',
      sub: sub.value,
      brandId: brandId.value,
      barcodes: List.of(barcodes),
      packagings: rows,
      openingMilli: opening ?? 0,
    );
    for (final p in validator.validate(draft)) {
      final key = switch (p.issue) {
        ProductIssue.nameRequired => 'name',
        ProductIssue.codeRequired => 'sku',
        ProductIssue.priceNegative => 'price',
        ProductIssue.unitRequired => 'unit',
        ProductIssue.taxRequired => 'tax',
        ProductIssue.factorInvalid => 'p${p.row}.factor',
        ProductIssue.duplicateUnit => 'p${p.row}.unit',
        ProductIssue.duplicateBarcode =>
          p.row == null ? 'barcodes' : 'p${p.row}.barcode',
        ProductIssue.priceOverrideNegative => 'p${p.row}.price',
        ProductIssue.openingNegative => 'opening',
      };
      errors[key] = switch (p.issue) {
        ProductIssue.nameRequired => s.productErrNameRequired(),
        ProductIssue.codeRequired => s.productErrSkuRequired(),
        ProductIssue.priceNegative ||
        ProductIssue.priceOverrideNegative => s.productErrPrice(),
        ProductIssue.unitRequired => s.productErrUnit(),
        ProductIssue.taxRequired => s.productErrTax(),
        ProductIssue.factorInvalid => s.productErrFactor(),
        ProductIssue.duplicateUnit => s.productErrDuplicateUnit(),
        ProductIssue.duplicateBarcode => s.productErrDuplicateBarcode(
          p.value ?? '',
        ),
        ProductIssue.openingNegative => s.productErrOpening(),
      };
    }
    return errors.isEmpty ? draft : null;
  }

  /// Enter and the Save button. Returns true when the product was saved.
  Future<bool> submit() async {
    if (saving.value || loading.value) return false;
    final draft = _draft();
    if (draft == null) return false;
    saving.value = true;
    try {
      final id = await admin.save(draft, uuid: _uuid, active: active.value);
      if (id == null) return false;
      close();
      return true;
    } on DuplicateBarcodeException catch (e) {
      errors['barcodes'] = AppStrings.current.productErrBarcodeTaken(e.barcode);
      return false;
    } on DuplicatePackagingException {
      errors['p0.unit'] = AppStrings.current.productErrDuplicateUnit();
      return false;
    } on InvalidProductException {
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Closes the dialog. The controller stays registered (its text boxes
  /// are still on screen while the dialog fades out); the next open deletes
  /// it.
  void close() => overlay.close();

  @override
  void onClose() {
    for (final c in <TextEditingController>[
      name,
      sku,
      price,
      barcodeInput,
      newCategory,
      newSub,
      newBrand,
      stockBase,
    ]) {
      c.dispose();
    }
    for (final row in packagings) {
      row.dispose();
    }
    super.onClose();
  }
}
