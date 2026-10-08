import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../shared/widgets/app_dropdown.dart';
import '../../customers/controllers/customers_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/cart_meta_controller.dart';

/// The customer `<select>` (prototype `customerSelect`), used by the cart
/// panel and the empty-cart catalog header.
class CustomerSelect extends StatelessWidget {
  const CustomerSelect({
    required this.style,
    required this.semanticLabel,
    super.key,
  });

  final TextStyle style;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final customers = Get.find<CustomersController>();
    final cart = Get.find<CartController>();
    final meta = Get.find<CartMetaController>();
    return Obx(() {
      final list = customers.customers;
      if (list.isEmpty) return const SizedBox.shrink();
      final selected = meta.customer.id;
      cart.cart.value;
      return AppDropdown<String>(
        value: selected,
        items: <String>[for (final c in list) c.id],
        labelOf: (id) => list.firstWhere((c) => c.id == id).name,
        onChanged: meta.selectCustomer,
        style: style,
        semanticLabel: semanticLabel,
      );
    });
  }
}
