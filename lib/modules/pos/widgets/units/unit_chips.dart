import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_strings_x.dart';
import '../../../../core/responsive/app_metrics_scope.dart';
import '../../../../core/theme/theme_x.dart';
import '../../../../core/theme/tokens/app_icons.dart';
import '../../../../core/theme/tokens/app_pack_sizes.dart';
import '../../../../core/theme/tokens/app_radii.dart';
import '../../../../core/theme/tokens/app_spacing.dart';
import '../../../../core/theme/tokens/app_typography.dart';
import '../../../../features/products/domain/entities/product.dart';
import '../../../../features/products/presentation/controllers/products_controller.dart';
import '../../../../shared/widgets/app_pressable.dart';
import '../../controllers/packaging_catalog_controller.dart';
import '../../controllers/unit_switch_controller.dart';
import '../../models/cart_line.dart';
import '../../models/unit_option.dart';
import 'unit_popover.dart';

/// The unit of a cart row with its switcher (DEC-154). Only products with
/// enabled packagings (or a line already sold in a packaging) show it; every
/// other row is exactly as before.
class LineUnitChip extends StatelessWidget {
  const LineUnitChip({required this.line, this.compact = false, super.key});

  final CartLine line;

  /// The dense table row (48 px high): a text link instead of a pill.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<PackagingCatalogController>();
    return Obx(() {
      catalog.revision.value;
      if (!catalog.hasPackagings(line.product.id) && line.packaging == null) {
        return const SizedBox.shrink();
      }
      final live = Get.find<ProductsController>().byId(line.product.id);
      final options = catalog.optionsFor(live ?? line.product);
      final current = options.firstWhere(
        (o) => o.packagingId == line.packaging?.id,
        orElse: () => UnitOption(
          name: line.packaging?.unitName ?? '',
          factorMilli: line.packaging?.quantityBaseMilli ?? 1000,
          price: line.price,
          packaging: line.packaging,
        ),
      );
      return Padding(
        padding: EdgeInsets.only(top: compact ? 0 : AppSpacing.s4),
        child: UnitPopover(
          options: options,
          currentPackagingId: line.packaging?.id,
          onPick: (o) => Get.find<UnitSwitchController>().switchLine(line, o),
          trigger: (context, toggle) => compact
              ? _Link(
                  label: unitOptionText(context, current),
                  tooltip: context.strings.unitChipTooltip(line.product.name),
                  onTap: toggle,
                )
              : _Chip(
                  label: unitOptionText(context, current),
                  tooltip: context.strings.unitChipTooltip(line.product.name),
                  onTap: toggle,
                ),
        ),
      );
    });
  }
}

/// The small "packs" control of a product tile: a click on the tile still
/// adds the base unit, this opens the unit list (DEC-154).
class TilePackChip extends StatelessWidget {
  const TilePackChip({required this.product, this.compact = false, super.key});

  final Product product;

  /// The narrow Products panel: the chevron alone, so the tile keeps its
  /// price and stepper.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final catalog = Get.find<PackagingCatalogController>();
    return Obx(() {
      catalog.revision.value;
      if (!catalog.hasPackagings(product.id)) return const SizedBox.shrink();
      final options = catalog.optionsFor(product);
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.s4),
        child: UnitPopover(
          options: options,
          currentPackagingId: null,
          onPick: (o) => Get.find<UnitSwitchController>().add(product, o),
          trigger: (context, toggle) => _Chip(
            label: '${options.length}',
            iconOnly: compact,
            tooltip: context.strings.packChipTooltip(
              product.name,
              options.length,
            ),
            onTap: toggle,
          ),
        ),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.tooltip,
    required this.onTap,
    this.iconOnly = false,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final touch = context.metrics.touch;
    return AppPressable(
      tooltip: tooltip,
      semanticLabel: tooltip,
      borderRadius: AppRadii.full,
      onTap: onTap,
      builder: (context, hovered) => Container(
        height: touch ? AppPackSizes.chipHeightTouch : AppPackSizes.chipHeight,
        padding: EdgeInsets.symmetric(
          horizontal: iconOnly
              ? AppPackSizes.chipPadCompact
              : AppPackSizes.chipPadX,
        ),
        decoration: BoxDecoration(
          color: hovered ? c.secondary : c.productStepperBg,
          borderRadius: BorderRadius.circular(AppRadii.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (!iconOnly) ...<Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: context.text
                      .of(AppFontSize.s12, weight: AppFontWeight.semiBold)
                      .copyWith(color: c.blue),
                ),
              ),
              const SizedBox(width: AppPackSizes.chipGap),
            ],
            Icon(
              AppIcons.chevronDown,
              size: AppPackSizes.chevron,
              color: c.blue,
            ),
          ],
        ),
      ),
    );
  }
}

/// The unit of a dense cart row: blue text with a chevron, no pill.
class _Link extends StatelessWidget {
  const _Link({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppPressable(
      tooltip: tooltip,
      semanticLabel: tooltip,
      borderRadius: AppRadii.r4,
      onTap: onTap,
      builder: (context, hovered) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: context.text
                  .of(AppFontSize.s11, weight: AppFontWeight.semiBold)
                  .copyWith(color: c.blue),
            ),
          ),
          Icon(
            AppIcons.chevronDown,
            size: AppPackSizes.chevronSmall,
            color: c.blue,
          ),
        ],
      ),
    );
  }
}
