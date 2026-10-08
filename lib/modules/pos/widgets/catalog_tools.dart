import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/tokens/app_icons.dart';
import '../../../core/theme/tokens/app_sizes.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../shared/widgets/search_text_field.dart';
import '../../../shared/widgets/segmented_toggle.dart';
import '../controllers/catalog_controller.dart';

/// Search field plus the grid/list toggle (`.catalog-tools`).
class CatalogTools extends StatelessWidget {
  const CatalogTools({super.key});

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final s = context.strings;
    final catalog = Get.find<CatalogController>();
    return Row(
      children: <Widget>[
        Expanded(
          child: SearchTextField(
            controller: catalog.filterText,
            hint: s.searchProductHint(),
            clearTooltip: s.clearSearchTooltip(),
            onChanged: catalog.onFilterChanged,
            onClear: catalog.clearFilter,
          ),
        ),
        const SizedBox(width: AppSpacing.s7),
        Obx(
          () => SegmentedToggle(
            buttonWidth: m.viewToggleWidth,
            buttonHeight: m.viewToggleHeight,
            items: <SegmentedItem>[
              SegmentedItem(
                icon: AppIcons.layoutGrid,
                iconSize: AppSizes.viewGridIcon,
                tooltip: s.gridViewTooltip(),
                selected: !catalog.list.value,
                onTap: () => catalog.setList(false),
              ),
              SegmentedItem(
                icon: AppIcons.list,
                iconSize: AppSizes.viewListIcon,
                tooltip: s.listViewTooltip(),
                selected: catalog.list.value,
                onTap: () => catalog.setList(true),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
