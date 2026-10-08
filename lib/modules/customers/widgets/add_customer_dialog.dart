import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/modal_field.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../controllers/add_customer_controller.dart';

/// "Add Customer" (`modal === "addCustomer"`).
class AddCustomerDialog extends StatelessWidget {
  const AddCustomerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final add = Get.find<AddCustomerController>();
    return AppModal(
      title: s.addCustomerTitle(),
      children: <Widget>[
        ModalParagraph(s.addCustomerBody()),
        ModalField(label: s.addCustomerName(), controller: add.name),
        ModalField(label: s.addCustomerPhone(), controller: add.phone),
        ModalField(label: s.addCustomerEmail(), controller: add.email),
        ModalPrimaryButton(
          label: s.addCustomerSave(),
          marginTop: AppCheckoutSizes.primaryFullMarginTop,
          onTap: add.save,
        ),
      ],
    );
  }
}
