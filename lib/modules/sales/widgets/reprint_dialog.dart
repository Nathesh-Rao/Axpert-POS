import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_checkout_sizes.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_typography.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../shared/widgets/app_modal.dart';
import '../../../shared/widgets/modal_list_row.dart';
import '../../../shared/widgets/modal_list_view.dart';
import '../controllers/reprint_controller.dart';
import '../controllers/sales_controller.dart';

/// Reprint ("Recent sales"): the sales newest first; a row opens its receipt.
class ReprintDialog extends StatelessWidget {
  const ReprintDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final c = context.colors;
    final controller = Get.find<ReprintController>();
    final sales = Get.find<SalesController>();
    final totalStyle = context.text.of(
      AppFontSize.s14,
      weight: AppFontWeight.bold,
      height: AppLineHeight.base,
    );
    return AppModal(
      title: s.reprintTitle(),
      children: <Widget>[
        ModalParagraph(s.reprintSubtitle()),
        Obx(() {
          sales.sales.length;
          return ModalListView(
            rows: <Widget>[
              for (final sale in controller.recent)
                ModalListRow(
                  key: ObjectKey(sale),
                  icon: AppIcons.fileText,
                  iconSize: AppCheckoutSizes.pickerUserIcon,
                  title: s.reprintRowTitle(sale.number, sale.customer),
                  subtitle: DateFormatter.dateTime(
                    DateTime.parse(sale.date).toLocal(),
                  ),
                  onTap: () => controller.open(sale),
                  trailing: Text(
                    MoneyFormatter.format(sale.totals.total),
                    maxLines: 1,
                    softWrap: false,
                    style: totalStyle.copyWith(color: c.text),
                  ),
                ),
            ],
            emptyText: s.reprintEmpty(),
          );
        }),
      ],
    );
  }
}
