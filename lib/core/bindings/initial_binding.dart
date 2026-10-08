import 'package:get/get.dart';

import '../../modules/customers/controllers/customers_controller.dart';
import '../../modules/customers/repository/customer_repository.dart';
import '../../modules/customers/repository/mock_customer_repository.dart';
import '../../modules/pos/controllers/cart_actions_controller.dart';
import '../../modules/pos/controllers/cart_controller.dart';
import '../../modules/pos/controllers/cart_selection_controller.dart';
import '../../modules/pos/repository/cart_repository.dart';
import '../../modules/pos/repository/held_bill_repository.dart';
import '../../modules/pos/repository/mock_cart_repository.dart';
import '../../modules/pos/repository/mock_held_bill_repository.dart';
import '../../modules/products/controllers/products_controller.dart';
import '../../modules/products/repository/mock_product_repository.dart';
import '../../modules/products/repository/product_repository.dart';
import '../../modules/sales/repository/mock_sale_repository.dart';
import '../../modules/sales/repository/sale_repository.dart';
import '../../shared/controllers/clock_controller.dart';
import '../mock/large_dataset.dart';
import '../services/beep_service.dart';

import '../../modules/shell/controllers/settings_controller.dart';
import '../../modules/shell/repository/mock_settings_repository.dart';
import '../../modules/shell/repository/settings_repository.dart';
import '../../shared/controllers/overlay_controller.dart';
import '../../shared/controllers/page_filter_controller.dart';
import '../../shared/controllers/search_field_controller.dart';
import '../../shared/controllers/shell_chrome_controller.dart';
import '../../shared/controllers/toast_controller.dart';
import '../services/storage/local_store.dart';
import '../shortcuts/shortcut_controller.dart';

/// Permanent, cross-module controllers. Idempotent: calling it twice (from
/// `main` and from `GetMaterialApp.initialBinding`) registers once.
class InitialBinding extends Bindings {
  InitialBinding(this.store);

  final LocalStore store;

  @override
  void dependencies() {
    _put<LocalStore>(store);
    _put<SettingsRepository>(MockSettingsRepository(store));
    _put<SettingsController>(SettingsController(Get.find()));
    _put<ToastController>(ToastController());
    _put<SearchFieldController>(SearchFieldController());
    _put<PageFilterController>(PageFilterController());
    _put<ShellChromeController>(ShellChromeController());
    _put<OverlayController>(OverlayController());
    _put<ShortcutController>(ShortcutController());
    _put<ClockController>(ClockController());

    _put<ProductRepository>(
      LargeDataset.enabled
          ? MockProductRepository(
              store,
              seed: LargeDataset.products(),
              forceSeed: true,
            )
          : MockProductRepository(store),
    );
    _put<CustomerRepository>(MockCustomerRepository(store));
    _put<CartRepository>(MockCartRepository(store));
    _put<HeldBillRepository>(MockHeldBillRepository(store));
    _put<SaleRepository>(MockSaleRepository(store));
    _put<BeepService>(
      NoopBeepService(() => Get.find<SettingsController>().settings.value.beep),
    );
    _put<ProductsController>(ProductsController(Get.find()));
    _put<CustomersController>(CustomersController(Get.find()));
    _put<CartController>(CartController(Get.find(), Get.find()));
    _put<CartSelectionController>(CartSelectionController());
    _put<CartActionsController>(
      CartActionsController(
        cart: Get.find(),
        products: Get.find(),
        selection: Get.find(),
        toasts: Get.find(),
        search: Get.find(),
        beep: Get.find(),
      ),
    );
    Get.find<ShortcutController>().handlers[ShortcutAction.deleteSelected] =
        Get.find<CartActionsController>().removeSelected;
  }

  /// Loads the persisted data of every permanent controller (call once before
  /// `runApp`).
  Future<void> loadData() async {
    await Get.find<SettingsController>().load();
    await Future.wait(<Future<void>>[
      Get.find<ProductsController>().load(),
      Get.find<CustomersController>().load(),
    ]);
    await Get.find<CartController>().load();
  }

  void _put<T extends Object>(T instance) {
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
