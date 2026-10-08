import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/dashed_divider.dart';
import '../../../shared/widgets/modal_primary_button.dart';
import '../controllers/receipt_controller.dart';
import '../models/receipt_document.dart';
import 'receipt_table.dart';
import 'receipt_totals.dart';

/// The receipt (`modal === "receipt"`): the sale as the prototype prints it,
/// then Print, Email, WhatsApp and New Sale.
class ReceiptDialog extends StatelessWidget {
  const ReceiptDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReceiptController>();
    final doc = controller.receipt;
    if (doc == null) return const SizedBox.shrink();
    final s = context.strings;
    return AppModal(
      maxWidth: AppSizes.receiptModalWidth,
      scrollable: true,
      children: <Widget>[
        _Header(doc: doc),
        _Meta(doc: doc),
        ReceiptTable(doc: doc),
        ReceiptTotals(doc: doc),
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppCheckoutSizes.receiptThanksMarginY,
          ),
          child: Text(
            s.receiptThanks(),
            textAlign: TextAlign.center,
            style: context.text
                .of(AppFontSize.s14, height: AppLineHeight.base)
                .copyWith(color: context.colors.text),
          ),
        ),
        const SizedBox(height: AppCheckoutSizes.receiptActionsMarginTop),
        Row(
          children: <Widget>[
            Expanded(
              child: _ActionButton(
                icon: AppIcons.printer,
                label: s.receiptPrint(),
                onTap: controller.print,
              ),
            ),
            const SizedBox(width: AppCheckoutSizes.receiptActionsGap),
            Expanded(
              child: _ActionButton(
                icon: AppIcons.mail,
                label: s.receiptEmail(),
                onTap: controller.email,
              ),
            ),
            const SizedBox(width: AppCheckoutSizes.receiptActionsGap),
            Expanded(
              child: _ActionButton(
                icon: AppIcons.smartphone,
                label: s.receiptWhatsApp(),
                onTap: controller.whatsApp,
              ),
            ),
          ],
        ),
        ModalPrimaryButton(
          label: s.receiptNewSale(),
          marginTop: AppCheckoutSizes.primaryFullMarginTop,
          onTap: controller.newSale,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.doc});

  final ReceiptDocument doc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppCheckoutSizes.receiptBrandMarginBottom,
          ),
          child: Text(
            s.receiptBrand(),
            textAlign: TextAlign.center,
            style: context.text
                .of(
                  AppFontSize.s14,
                  weight: AppFontWeight.bold,
                  height: AppLineHeight.base,
                  letterSpacing: AppTracking.receiptBrand,
                )
                .copyWith(color: c.blue),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppCheckoutSizes.receiptStoreMarginBottom,
          ),
          child: Text(
            doc.store,
            textAlign: TextAlign.center,
            style: context.text
                .fluid(
                  AppCheckoutSizes.receiptStoreFont,
                  weight: AppFontWeight.bold,
                  height: AppLineHeight.base,
                )
                .copyWith(color: c.text),
          ),
        ),
        Text(
          s.receiptTagline(),
          textAlign: TextAlign.center,
          style: context.text
              .fluid(
                AppCheckoutSizes.receiptTaglineFont,
                height: AppLineHeight.base,
              )
              .copyWith(color: c.muted),
        ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.doc});

  final ReceiptDocument doc;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = context.strings;
    final style = context.text
        .fluid(
          AppCheckoutSizes.receiptMetaFont,
          height: AppCheckoutSizes.receiptMetaLineHeight,
        )
        .copyWith(color: c.text);
    final lines = <String>[
      s.receiptBill(doc.number),
      DateFormatter.dateTimeComma(doc.date),
      s.receiptCashier(doc.cashier),
      s.receiptCustomer(doc.customer),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppCheckoutSizes.receiptMetaMarginY,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          DashedDivider(color: c.border),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppCheckoutSizes.receiptMetaPadY,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var i = 0; i < lines.length; i++) ...<Widget>[
                  if (i > 0)
                    const SizedBox(height: AppCheckoutSizes.receiptMetaGap),
                  Text(lines[i], style: style),
                ],
              ],
            ),
          ),
          DashedDivider(color: c.border),
        ],
      ),
    );
  }
}

/// `.receipt-actions button`: secondary, equal width, 12 px, padding 10.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      borderRadius: AppRadii.r8,
      semanticLabel: label,
      onTap: onTap,
      builder: (context, hovered) => Container(
        constraints: const BoxConstraints(minHeight: AppSizes.controlMinHeight),
        padding: const EdgeInsets.all(AppCheckoutSizes.receiptActionPad),
        decoration: BoxDecoration(
          color: c.secondary,
          borderRadius: BorderRadius.circular(AppRadii.r8),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: AppCheckoutSizes.receiptActionIcon, color: c.text),
            const SizedBox(width: AppSpacing.s8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text
                    .fluid(
                      AppCheckoutSizes.receiptActionFont,
                      weight: AppFontWeight.medium,
                      height: AppLineHeight.base,
                    )
                    .copyWith(color: c.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
