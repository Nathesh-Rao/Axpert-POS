import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/services/pricing/pricing_models.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../shared/widgets/app_drawer.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../../../../shared/widgets/modal_field.dart';
import '../../../../shared/widgets/text_segmented.dart';
import '../../controllers/discount_form_controller.dart';

/// F6 / Discount: the bill discount drawer (`modal === "discount"`).
class DiscountDrawer extends StatelessWidget {
  const DiscountDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final form = Get.find<DiscountFormController>();
    return AppDrawer(
      children: <Widget>[
        const ModalSymbol(icon: AppIcons.percent),
        ModalTitle(s.discountDrawerTitle()),
        ModalParagraph(s.discountDrawerSubtitle()),
        Obx(
          () => TextSegmented(
            segments: <TextSegment>[
              TextSegment(
                label: s.discountTabPercent(),
                selected: form.type.value == BillDiscountType.percent,
                onTap: () => form.setType(BillDiscountType.percent),
              ),
              TextSegment(
                label: s.discountTabFlat(),
                selected: form.type.value == BillDiscountType.flat,
                onTap: () => form.setType(BillDiscountType.flat),
              ),
            ],
          ),
        ),
        ModalField(
          label: s.discountValueLabel(),
          controller: form.value,
          focusNode: form.valueFocus,
          decimal: true,
          onChanged: form.onValueChanged,
        ),
        ModalField(
          label: s.discountReasonLabel(),
          controller: form.reason,
          hint: s.discountReasonHint(),
        ),
        ModalActions(
          secondaryLabel: s.discountRemove(),
          onSecondary: form.remove,
          primaryLabel: s.discountApply(),
          onPrimary: form.apply,
        ),
      ],
    );
  }
}
