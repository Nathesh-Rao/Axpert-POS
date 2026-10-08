import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/modal_input.dart';
import '../../../shared/widgets/modal_list_row.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../controllers/customer_picker_controller.dart';

/// "Find a customer" (`modal === "customers"`): search, the list and the
/// Add Customer button.
class CustomerPickerDialog extends StatelessWidget {
  const CustomerPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final picker = Get.find<CustomerPickerController>();
    // `.modal-list{max-height:min(400px,40dvh)}`
    final maxHeight = [
      AppCheckoutSizes.modalListMaxHeight,
      MediaQuery.sizeOf(context).height *
          AppCheckoutSizes.modalListMaxHeightFraction,
    ].reduce((a, b) => a < b ? a : b);
    return AppModal(
      title: s.customerPickerTitle(),
      children: <Widget>[
        ModalInput(
          controller: picker.search,
          focusNode: picker.searchFocus,
          autofocus: true,
          hint: s.customerPickerHint(),
          semanticLabel: s.customerPickerTitle(),
          onSubmitted: (_) => picker.selectHighlighted(),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppCheckoutSizes.modalListMarginY,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Obx(() {
                final list = picker.filtered;
                final index = picker.arrowed.value
                    ? picker.highlight.value
                    : -1;
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final customer = list[i];
                    return ModalListRow(
                      key: ValueKey<String>(customer.id),
                      icon: AppIcons.userRound,
                      iconSize: AppCheckoutSizes.pickerUserIcon,
                      title: customer.name,
                      subtitle: s.customerRowDetail(
                        customer.phone,
                        customer.member,
                        customer.points,
                      ),
                      highlighted: i == index,
                      onTap: () => picker.select(customer),
                      trailing: Icon(
                        AppIcons.chevronRight,
                        size: AppCheckoutSizes.pickerChevron,
                        color: c.text,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ),
        ModalPrimaryButton(
          label: s.customerAddButton(),
          icon: AppIcons.plus,
          onTap: picker.openAdd,
        ),
      ],
    );
  }
}
