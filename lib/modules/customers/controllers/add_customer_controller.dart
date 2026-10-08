import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings.dart';
import '../../../shared/controllers/clock_controller.dart';
import '../../../shared/controllers/overlay_controller.dart';
import '../../../shared/controllers/toast_controller.dart';
import '../../pos/controllers/cart_meta_controller.dart';
import '../services/customer_rules.dart';
import 'customers_controller.dart';

/// The "Add Customer" dialog (`saveCustomer`): the form is kept between
/// openings until a customer is saved.
class AddCustomerController extends GetxController {
  AddCustomerController({
    required this.customers,
    required this.meta,
    required this.toasts,
    required this.overlay,
    required this.clock,
  });

  final CustomersController customers;
  final CartMetaController meta;
  final ToastController toasts;
  final OverlayController overlay;
  final ClockController clock;

  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();

  @override
  void onClose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    super.onClose();
  }

  /// "Save customer".
  void save() {
    final s = AppStrings.current;
    if (!CustomerRules.isValid(
      name: name.text,
      phone: phone.text,
      email: email.text,
    )) {
      toasts.show(s.toastCustomerInvalid(), kind: ToastKind.warning);
      return;
    }
    final customer = CustomerRules.create(
      name: name.text,
      phone: phone.text,
      email: email.text,
      now: clock.current,
    );
    customers.add(customer);
    meta.setCustomer(customer.id);
    name.clear();
    phone.clear();
    email.clear();
    overlay.close();
    toasts.show(s.toastCustomerAdded());
  }
}
