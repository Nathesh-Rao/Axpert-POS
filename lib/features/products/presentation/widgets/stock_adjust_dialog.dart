import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_product_form_sizes.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../../../../shared/widgets/app_modal.dart';
import '../../../../shared/widgets/app_spinner.dart';
import '../../../../shared/widgets/modal_actions.dart';
import '../../domain/entities/product_admin_entities.dart';
import '../controllers/stock_adjust_controller.dart';
import 'product_form_parts.dart';

/// "Adjust stock" (`modal === 'adjustStock'`, DEC-152): counted quantity,
/// reason and note. It replaces the form while it is open and returns to it.
class StockAdjustDialog extends StatelessWidget {
  const StockAdjustDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final adjust = Get.find<StockAdjustController>();
    final s = context.strings;
    final c = context.colors;
    final value = context.text
        .of(AppFontSize.s14, height: AppLineHeight.base)
        .copyWith(color: c.text);
    final muted = context.text
        .of(AppFontSize.s13, height: AppLineHeight.base)
        .copyWith(color: c.muted);
    return AppModal(
      title: s.adjustStockTitle(adjust.product.name),
      scrollable: true,
      children: <Widget>[
        Obx(() {
          if (adjust.loading.value) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.s24),
              child: Center(child: AppSpinner(size: AppSpacing.s32)),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              FormBlock(
                label: s.productCurrentStock(),
                child: Text(adjust.currentText, style: value),
              ),
              FormBlock(
                label: s.adjustStockNew(),
                child: Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: <Widget>[
                    for (final level in adjust.levels)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: AppProductFormSizes.countWidth,
                            child: FormInput(
                              controller: level.count,
                              label: level.name,
                              digitsOnly: true,
                              onSubmitted: (_) => adjust.submit(),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s6),
                          Text('${level.name} +', style: value),
                        ],
                      ),
                    SizedBox(
                      width: AppProductFormSizes.countWidth,
                      child: FormInput(
                        controller: adjust.base,
                        label: adjust.baseUnitName,
                        decimal: true,
                        onSubmitted: (_) => adjust.submit(),
                      ),
                    ),
                    Text(adjust.baseUnitName, style: value),
                  ],
                ),
              ),
              Obx(() {
                final change = adjust.changeText();
                return change == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                        child: Text(change, style: muted),
                      );
              }),
              FormBlock(
                label: s.adjustReason(),
                child: Obx(
                  () => AppDropdown<AdjustmentReason>(
                    value: adjust.reason.value,
                    items: AdjustmentReason.values,
                    labelOf: (r) => switch (r) {
                      AdjustmentReason.countCorrection => s.adjustReasonCount(),
                      AdjustmentReason.damage => s.adjustReasonDamage(),
                      AdjustmentReason.received => s.adjustReasonReceived(),
                      AdjustmentReason.other => s.adjustReasonOther(),
                    },
                    onChanged: (r) => adjust.reason.value = r,
                    style: value,
                    semanticLabel: s.adjustReason(),
                  ),
                ),
              ),
              FormBlock(
                label: s.adjustNote(),
                error: adjust.error.value,
                child: FormInput(
                  controller: adjust.note,
                  label: s.adjustNote(),
                  hasError: adjust.error.value.isNotEmpty,
                  onSubmitted: (_) => adjust.submit(),
                ),
              ),
              ModalActions(
                secondaryLabel: s.productCancel(),
                onSecondary: adjust.back,
                primaryLabel: adjust.saving.value
                    ? s.productSaving()
                    : s.adjustConfirm(),
                primaryEnabled: !adjust.saving.value,
                onPrimary: adjust.submit,
              ),
            ],
          );
        }),
      ],
    );
  }
}
