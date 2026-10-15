import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/services/pricing/money.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_dropdown.dart';
import '../controllers/store_config_controller.dart';
import 'config_primitives.dart';

/// A sample bill (1,000.00 at a slab) priced by the real pricing service: the
/// lines the Bill Summary and the receipt will show.
class PreviewSection extends StatelessWidget {
  const PreviewSection({required this.controller, super.key});

  final StoreConfigController controller;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    return ConfigCard(
      title: s.scSectionPreview(),
      child: Obx(() {
        controller.revision.value;
        final preview = controller.preview;
        final slabs = controller.slabs.toList();
        final selected = controller.previewSlab;
        Widget row(String label, Money amount, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                label,
                style: configNoteStyle(context).copyWith(color: c.text),
              ),
              Text(
                MoneyFormatter.format(amount),
                style: context.text
                    .of(
                      AppFontSize.s14,
                      weight: bold ? AppFontWeight.bold : AppFontWeight.medium,
                    )
                    .copyWith(color: c.text),
              ),
            ],
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ConfigLabeled(
              label: s.scPreviewSlab(),
              child: AppDropdown<int>(
                value: selected == null ? null : slabs.indexOf(selected),
                items: <int>[for (var i = 0; i < slabs.length; i++) i],
                labelOf: (i) => slabs[i].name.text.trim(),
                onChanged: controller.setPreview,
                style: configValueStyle(context),
                semanticLabel: s.scPreviewSlab(),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            if (preview != null) ...<Widget>[
              row(s.receiptSubtotal(), preview.subtotal),
              row(s.summaryTaxAmount(controller.previewHeading), preview.tax),
              for (final part in preview.parts) row(part.label, part.amount),
              row(s.receiptTotal(), preview.total, bold: true),
              Text(
                s.scPreviewPrice(MoneyFormatter.format(preview.subtotal)),
                style: configNoteStyle(context),
              ),
            ],
          ],
        );
      }),
    );
  }
}
