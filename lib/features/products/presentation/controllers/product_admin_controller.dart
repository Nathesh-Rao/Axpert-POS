import 'package:get/get.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/identifiers/uuid_generator.dart';
import '../../../../core/session/permissions.dart';
import '../../../../core/session/session_scoped.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/toast_controller.dart';
import '../../../offers/presentation/controllers/offers_controller.dart';
import '../../../session/presentation/controllers/active_session.dart';
import '../../domain/entities/packaging_entities.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../../domain/repositories/packaging_repositories.dart';
import '../../domain/repositories/product_admin_repository.dart';
import 'product_form_controller.dart';
import 'products_controller.dart';
import 'stock_adjust_controller.dart';

/// Product management for the Products page (permanent, DEC-152): the role
/// gate, the stock cells, the inactive list and the commands that change the
/// catalog. Every command re-checks the role before calling the repository,
/// so a hidden button is never the only protection.
class ProductAdminController extends GetxController implements SessionScoped {
  ProductAdminController({
    required this.repository,
    required this.units,
    required this.brands,
    required this.uuid,
    required this.products,
    required this.offers,
    required this.session,
    required this.overlay,
    required this.toasts,
  });

  final ProductAdminRepository repository;
  final UnitRepository units;
  final BrandRepository brands;
  final UuidGenerator uuid;
  final ProductsController products;
  final OffersController offers;
  final ActiveSession session;
  final OverlayController overlay;
  final ToastController toasts;

  /// The "Show inactive" switch of the Products page.
  final RxBool showInactive = false.obs;

  /// Inactive products, by list order (shown when [showInactive]).
  final RxList<Product> inactive = <Product>[].obs;

  /// Stock cells by legacy id (exact balance and packaging levels).
  final RxMap<int, StockView> stock = <int, StockView>{}.obs;

  /// Bumped after every catalog change so open lists refresh once.
  final RxInt revision = 0.obs;

  bool get canManage =>
      CatalogPermissions.canManageCatalog(session.user.value?.role);

  /// Reloads the stock cells and the inactive list (page open, after a save).
  Future<void> reloadLists() async {
    final views = await repository.stockViews();
    final rows = await repository.catalog();
    stock.assignAll(views);
    inactive.assignAll([
      for (final r in rows)
        if (!r.active) r.product,
    ]);
    revision.value++;
  }

  /// Reloads what the sales screen reads (catalog and tile badges).
  Future<void> _reloadCatalog() async {
    await products.load();
    await offers.load(session.store.value?.id);
    await reloadLists();
  }

  bool _allowed() {
    if (canManage) return true;
    toasts.show(
      AppStrings.current.toastProductNoPermission(),
      kind: ToastKind.error,
    );
    return false;
  }

  /// Runs [action] when the role allows it; a failure is shown, not thrown.
  Future<T?> _guard<T>(Future<T> Function() action) async {
    if (!_allowed()) return null;
    return action();
  }

  // ---- commands the form and the table call ----

  /// Saves a new product ([uuid] null) or the edit of [uuid]; with
  /// [active] false the product is deactivated right after. Returns its id,
  /// or null when the role may not. Repository errors (duplicate barcode,
  /// invalid) are rethrown for the form to show next to the field.
  Future<String?> save(
    ProductDraft draft, {
    String? uuid,
    bool active = true,
  }) async {
    if (!_allowed()) return null;
    final id = uuid == null
        ? await repository.create(draft)
        : await _update(uuid, draft);
    if (!active) await repository.deactivate(id);
    await _reloadCatalog();
    toasts.show(AppStrings.current.toastProductSaved(draft.name.trim()));
    return id;
  }

  Future<String> _update(String uuid, ProductDraft draft) async {
    await repository.update(uuid, draft);
    return uuid;
  }

  Future<void> deactivate(Product product) async {
    final detail = await _guard(() => repository.detail(product.id));
    if (detail == null) return;
    await repository.deactivate(detail.uuid);
    await _reloadCatalog();
    toasts.show(AppStrings.current.toastProductDeactivated(product.name));
  }

  /// Returns false when a barcode was taken meanwhile (shown as a toast).
  Future<bool> reactivate(Product product) async {
    final detail = await _guard(() => repository.detail(product.id));
    if (detail == null) return false;
    try {
      await repository.reactivate(detail.uuid);
    } on DuplicateBarcodeException catch (e) {
      toasts.show(
        AppStrings.current.productErrBarcodeTaken(e.barcode),
        kind: ToastKind.error,
      );
      return false;
    }
    await _reloadCatalog();
    toasts.show(AppStrings.current.toastProductReactivated(product.name));
    return true;
  }

  Future<bool> adjustStock({
    required String uuid,
    required int deltaMilli,
    required AdjustmentReason reason,
    required String note,
  }) async {
    if (!_allowed()) return false;
    await repository.adjustStock(
      uuid: uuid,
      deltaMilli: deltaMilli,
      reason: reason,
      note: note,
      userId: session.user.value?.id,
    );
    await _reloadCatalog();
    toasts.show(AppStrings.current.toastStockAdjusted());
    return true;
  }

  // ---- opening the dialogs ----

  /// Builds the form controller (outside of build) and opens the dialog.
  void openAdd() => _openForm(null);

  /// Ctrl/Cmd+I: only while no dialog is open (it would reset the form).
  void openAddFromShortcut() {
    if (!overlay.isOpen) openAdd();
  }

  void openEdit(Product product) => _openForm(product);

  void _openForm(Product? product) {
    if (!_allowed()) return;
    Get.delete<ProductFormController>(force: true);
    Get.delete<StockAdjustController>(force: true);
    Get.put(
      ProductFormController(
        admin: this,
        units: units,
        brands: brands,
        session: session,
        overlay: overlay,
        toasts: toasts,
        uuid: uuid,
        editing: product,
      )..load(),
    );
    overlay.open(formDialog);
  }

  /// "Adjust stock" of an edited product, shown in place of the form.
  void openAdjust(Product product) {
    if (!_allowed()) return;
    Get.delete<StockAdjustController>(force: true);
    Get.put(
      StockAdjustController(admin: this, overlay: overlay, product: product)
        ..load(),
    );
    overlay.open(adjustDialog);
  }

  void confirmDeactivate(Product product) {
    if (!_allowed()) return;
    overlay.openConfirm(
      AppStrings.current.confirmDeactivateProduct(product.name),
      () => deactivate(product),
    );
  }

  static const String formDialog = 'productForm';
  static const String adjustDialog = 'adjustStock';

  @override
  void resetForSignOut() {
    inactive.clear();
    stock.clear();
    showInactive.value = false;
  }
}
