import 'package:get/get.dart';

import '../../modules/customers/controllers/add_customer_controller.dart';
import '../../modules/pos/controllers/text_dialog_controller.dart';
import '../../modules/sales/controllers/receipt_controller.dart';
import '../../modules/sales/controllers/reprint_controller.dart';
import '../services/print_service.dart';
import '../services/receipt_share_service.dart';
import '../../modules/customers/controllers/customer_picker_controller.dart';
import '../../modules/pos/controllers/discount_form_controller.dart';
import '../../modules/pos/controllers/global_search_controller.dart';
import '../../modules/pos/controllers/price_check_controller.dart';
import '../../modules/pos/controllers/scan_controller.dart';
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
import '../../modules/shift/controllers/shift_controller.dart';
import '../../modules/pos/repository/cart_repository.dart';
import '../../modules/pos/repository/held_bill_repository.dart';
import '../../modules/pos/repository/mock_cart_repository.dart';
import '../../modules/pos/repository/mock_held_bill_repository.dart';
import '../../features/products/presentation/controllers/products_controller.dart';
import '../../features/products/data/repositories/mock_product_repository.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../modules/sales/repository/mock_sale_repository.dart';
import '../../modules/sales/repository/sale_repository.dart';
import '../../shared/controllers/clock_controller.dart';
import '../../features/products/data/datasources/large_dataset.dart';
import '../config/app_config.dart';
import '../database/database_provider.dart';
import '../device/device_context_service.dart';
import '../identifiers/uuid_generator.dart';
import '../lifecycle/app_lifecycle_service.dart';
import '../network/api_client.dart';
import '../security/authentication_service.dart';
import '../session/session_controller.dart';
import 'app_infrastructure.dart';
import 'startup_diagnostics.dart';
import '../../features/payment/data/services/mock_payment_service.dart';
import '../../features/payment/domain/services/payment_service.dart';
import '../services/audio/audio_service.dart';
import '../services/audio/audio_service_platform.dart';
import '../services/beep_service.dart';

import '../../modules/shell/controllers/settings_controller.dart';
import '../../modules/shell/repository/drift_settings_repository.dart';
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
  InitialBinding(
    this.store, {
    required this.infrastructure,
    AudioService? audio,
    PaymentService? payments,
  }) : audio = audio ?? createPlatformAudioService(),
       payments = payments ?? const MockPaymentService();

  final LocalStore store;
  final AppInfrastructure infrastructure;
  final AudioService audio;

  /// The payment boundary; a mock until a provider exists (DEC-123).
  final PaymentService payments;

  SettingsRepository _settingsRepository() =>
      switch (infrastructure.config.settingsBackend) {
        SettingsBackend.drift => DriftSettingsRepository(
          provider: infrastructure.databaseProvider,
          store: store,
          diagnostics: infrastructure.diagnostics,
        ),
        SettingsBackend.localStore => LocalStoreSettingsRepository(store),
        SettingsBackend.mock => MockSettingsRepository(store),
      };

  @override
  void dependencies() {
    _put<LocalStore>(store);
    _putInfrastructure();
    _put<SettingsRepository>(_settingsRepository());
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
    _put<AudioService>(audio);
    _put<BeepService>(
      SettingBeepService(
        () => Get.find<SettingsController>().settings.value.beep,
        Get.find(),
      ),
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
    _put<ShiftController>(
      ShiftController(
        sales: Get.find(),
        clock: Get.find(),
        overlay: Get.find(),
        search: Get.find(),
      ),
    );
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
    _put<PaymentService>(payments);
    _put<PaymentController>(
      PaymentController(
        payments: Get.find(),
        uuid: Get.find<UuidGenerator>(),
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
    _put<ScanController>(
      ScanController(
        products: Get.find(),
        actions: Get.find(),
        toasts: Get.find(),
        search: Get.find(),
        overlay: Get.find(),
      ),
    );
    _put<GlobalSearchController>(
      GlobalSearchController(
        search: Get.find(),
        products: Get.find(),
        actions: Get.find(),
        scan: Get.find(),
      ),
    );
    _put<PriceCheckController>(
      PriceCheckController(
        products: Get.find(),
        toasts: Get.find(),
        overlay: Get.find(),
      ),
    );
    _put<CustomerPickerController>(
      CustomerPickerController(
        customers: Get.find(),
        meta: Get.find(),
        member: Get.find(),
        overlay: Get.find(),
      ),
    );
    _put<AddCustomerController>(
      AddCustomerController(
        customers: Get.find(),
        meta: Get.find(),
        toasts: Get.find(),
        overlay: Get.find(),
        clock: Get.find(),
      ),
    );
    _put<PrintService>(RecordingPrintService());
    _put<ReceiptShareService>(RecordingReceiptShareService());
    _put<ReceiptController>(
      ReceiptController(
        overlay: Get.find(),
        toasts: Get.find(),
        printer: Get.find(),
        sharing: Get.find(),
      ),
    );
    _put<ReprintController>(
      ReprintController(sales: Get.find(), overlay: Get.find()),
    );
    _put<TextDialogController>(
      TextDialogController(
        overlay: Get.find(),
        settings: Get.find(),
        cart: Get.find(),
        meta: Get.find(),
      ),
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

  /// axpert_pos-style infrastructure (DEC-118/119): config, API client, local
  /// database, device context, ids, authentication (unconfigured), session and
  /// lifecycle. Idempotent like every registration here.
  void _putInfrastructure() {
    final i = infrastructure;
    _put<StartupDiagnostics>(i.diagnostics);
    _put<AppConfig>(i.config);
    _put<ApiClient>(i.apiClient);
    _put<DatabaseProvider>(i.databaseProvider);
    _put<DeviceContextService>(i.deviceContextService);
    _put<UuidGenerator>(i.uuid);
    _put<AuthenticationService>(i.authentication);
    _put<SessionController>(
      SessionController(authenticationService: i.authentication),
    );
    _put<AppLifecycleService>(i.lifecycle);
  }

  void _put<T extends Object>(T instance) {
    if (!Get.isRegistered<T>()) Get.put<T>(instance, permanent: true);
  }
}
