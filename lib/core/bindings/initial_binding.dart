import 'package:get/get.dart';

import '../../modules/pos/controllers/discount_form_controller.dart';
import '../../modules/pos/controllers/hold_recall_controller.dart';

import '../../modules/customers/controllers/customers_controller.dart';
import '../../modules/customers/repository/customer_repository.dart';
import '../../modules/customers/repository/mock_customer_repository.dart';
import '../../modules/pos/controllers/cart_actions_controller.dart';
import '../../modules/pos/controllers/cart_controller.dart';
import '../../modules/pos/controllers/cart_meta_controller.dart';
import '../../modules/pos/controllers/cart_selection_controller.dart';
import '../../modules/pos/controllers/forex_controller.dart';
import '../../modules/pos/controllers/held_bills_controller.dart';
import '../../modules/pos/controllers/member_controller.dart';
import '../../modules/pos/controllers/order_menu_controller.dart';
import '../../modules/pos/controllers/payment_controller.dart';
import '../../modules/pos/models/payment_state.dart';
import '../../modules/sales/controllers/sales_controller.dart';
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
    _put<SalesController>(SalesController(Get.find()));
    _put<HeldBillsController>(HeldBillsController(Get.find()));
    _put<ForexController>(ForexController(Get.find()));
    _put<CartMetaController>(
      CartMetaController(
        cart: Get.find(),
        customers: Get.find(),
        search: Get.find(),
      ),
    );
    _put<MemberController>(
      MemberController(
        cart: Get.find(),
        customers: Get.find(),
        meta: Get.find(),
        toasts: Get.find(),
      ),
    );
    _put<PaymentController>(
      PaymentController(
        cart: Get.find(),
        meta: Get.find(),
        products: Get.find(),
        customers: Get.find(),
        sales: Get.find(),
        settings: Get.find(),
        toasts: Get.find(),
        overlay: Get.find(),
        search: Get.find(),
      ),
    );
    _put<OrderMenuController>(
      OrderMenuController(
        cart: Get.find(),
        meta: Get.find(),
        settings: Get.find(),
        clock: Get.find(),
        overlay: Get.find(),
      ),
    );
    _put<HoldRecallController>(
      HoldRecallController(
        cart: Get.find(),
        held: Get.find(),
        products: Get.find(),
        toasts: Get.find(),
        search: Get.find(),
        overlay: Get.find(),
        clock: Get.find(),
      ),
    );
    _put<DiscountFormController>(
      DiscountFormController(cart: Get.find(), overlay: Get.find()),
    );
    final shortcuts = Get.find<ShortcutController>();
    shortcuts.handlers[ShortcutAction.deleteSelected] =
        Get.find<CartActionsController>().removeSelected;
    final payment = Get.find<PaymentController>();
    shortcuts.handlers[ShortcutAction.cash] = () =>
        payment.payment(PaymentMode.cash);
    shortcuts.handlers[ShortcutAction.card] = () =>
        payment.payment(PaymentMode.card);
    shortcuts.handlers[ShortcutAction.hold] =
        Get.find<HoldRecallController>().hold;
    shortcuts.handlers[ShortcutAction.recall] =
        Get.find<HoldRecallController>().openRecall;
    shortcuts.handlers[ShortcutAction.discount] =
        Get.find<DiscountFormController>().open;
  }

  /// Loads the persisted data of every permanent controller (call once before
  /// `runApp`).
  Future<void> loadData() async {
    await Get.find<SettingsController>().load();
    await Future.wait(<Future<void>>[
      Get.find<ProductsController>().load(),
      Get.find<CustomersController>().load(),
      Get.find<SalesController>().load(),
      Get.find<HeldBillsController>().load(),
    ]);
    await Get.find<CartController>().load();
  }

  void _put<T extends Object>(T instance) {
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
