import 'package:get/get.dart';

import '../../../../modules/pos/controllers/cart_controller.dart';
import '../../../../shared/controllers/overlay_controller.dart';
import '../../../../shared/controllers/toast_controller.dart';
import '../../../session/presentation/controllers/active_session.dart';
import '../../../session/domain/entities/session_entities.dart';
import '../../data/in_memory_store_config_repository.dart';
import '../../domain/services/legacy_slabs.dart';
import '../../domain/entities/store_config.dart';
import '../../domain/repositories/store_config_repository.dart';
import '../controllers/store_config_controller.dart';

class StoreConfigBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StoreConfigController>(
      () => StoreConfigController(
        repository: Get.isRegistered<StoreConfigRepository>()
            ? Get.find<StoreConfigRepository>()
            : _fromSession(Get.find<ActiveSession>()),
        session: Get.find<ActiveSession>(),
        overlay: Get.find<OverlayController>(),
        toasts: Get.find<ToastController>(),
        cart: Get.find<CartController>(),
      ),
    );
  }

  /// Without a database (in-memory sessions) the page edits a copy of what
  /// the session holds.
  static StoreConfigRepository _fromSession(ActiveSession session) {
    final store = session.store.value;
    final regime = session.regime.value;
    if (store == null) return InMemoryStoreConfigRepository({});
    return InMemoryStoreConfigRepository({
      store.id: StoreConfig(
        storeId: store.id,
        name: store.name,
        countryCode: store.region,
        stateCode: store.stateCode,
        currencyCode: store.currencyCode,
        inclusive: regime?.inclusive ?? false,
        forex: <ForexRow>[
          for (final f in session.forex)
            ForexRow(code: f.code, rateMicro: f.rateMicro),
        ],
        slabs: regime == null
            ? const <TaxSlabInfo>[]
            : regime.hasComponentSlabs
            ? regime.slabs
            : LegacySlabs.from(regime),
      ),
    });
  }
}
