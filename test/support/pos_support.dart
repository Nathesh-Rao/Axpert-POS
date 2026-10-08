import 'package:get/get.dart';
import 'package:pos_application/core/bindings/initial_binding.dart';
import 'package:pos_application/core/services/beep_service.dart';
import 'package:pos_application/core/services/storage/in_memory_local_store.dart';
import 'package:pos_application/core/services/storage/local_store.dart';
import 'package:pos_application/modules/pos/controllers/cart_actions_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_controller.dart';
import 'package:pos_application/modules/pos/controllers/cart_selection_controller.dart';
import 'package:pos_application/modules/products/controllers/products_controller.dart';
import 'package:pos_application/shared/controllers/toast_controller.dart';

import 'test_app.dart';

/// Booted permanent controllers on an in-memory store (VM and Chrome).
class PosHarness {
  PosHarness._(this.store, this.binding);

  final LocalStore store;
  final InitialBinding binding;

  CartController get cart => Get.find();
  CartActionsController get actions => Get.find();
  CartSelectionController get selection => Get.find();
  ProductsController get products => Get.find();
  ToastController get toasts => Get.find();
  NoopBeepService get beep => Get.find<BeepService>() as NoopBeepService;

  static Future<PosHarness> boot({LocalStore? store}) async {
    final s = store ?? InMemoryLocalStore();
    final binding = await bootTestApp(store: s);
    return PosHarness._(s, binding);
  }
}
