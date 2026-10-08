import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../shared/widgets/app_chip.dart';
import '../controllers/catalog_controller.dart';

/// Subcategory chips. Like `flex:1` buttons they share the row equally, but
/// never get narrower than their text; when the row is too long it scrolls.
class SubcategoryBar extends StatelessWidget {
  const SubcategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final s = context.strings;
    final catalog = Get.find<CatalogController>();
    final padding = EdgeInsets.symmetric(
      horizontal: m.subcategoryPadX,
      vertical: m.subcategoryPadY,
    );
    // Same style the chip text ends up with (inherited default merged in).
    final style = DefaultTextStyle.of(
      context,
    ).style.merge(context.text.fluid(m.catalogFont, height: 1.5));
    return SizedBox(
      height: m.subcategoryChipHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Obx(() {
            final names = <String?>[
              null,
              ...catalog.category.value.subcategories,
            ];
            final selected = catalog.sub.value;
            final widths = _widths(
              labels: <String>[for (final n in names) n ?? s.subcategoryAll()],
              style: style,
              available: constraints.maxWidth,
              padX: padding.horizontal,
              gap: AppSpacing.s5,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (var i = 0; i < names.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: AppSpacing.s5),
                    SizedBox(
                      width: widths[i],
                      child: AppChip(
                        key: ValueKey<String?>(names[i]),
                        label: names[i] ?? s.subcategoryAll(),
                        selected: names[i] == selected,
                        onTap: () => catalog.selectSub(names[i]),
                        padding: padding,
                        expand: true,
                        fontSize: m.catalogFont,
                        selectedForeground: c.blue,
                        selectedBackground: c.selectedTabBg,
                      ),
                    ),
                  ],
                ],
              ),
            );
          });
        },
      ),
    );
  }

  /// Equal widths for all chips, except chips whose text needs more (they keep
  /// their text width and the rest share what is left).
  static List<double> _widths({
    required List<String> labels,
    required TextStyle style,
    required double available,
    required double padX,
    required double gap,
  }) {
    final minimum = <double>[
      for (final label in labels)
        (TextPainter(
              text: TextSpan(text: label, style: style),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout()).width +
            padX,
    ];
    final result = List<double>.of(minimum);
    final fixed = List<bool>.filled(labels.length, false);
    final total = available - gap * (labels.length - 1);
    var changed = true;
    while (changed) {
      changed = false;
      var free = total;
      var count = 0;
      for (var i = 0; i < result.length; i++) {
        if (fixed[i]) {
          free -= result[i];
        } else {
          count++;
        }
      }
      if (count == 0) break;
      final share = free / count;
      for (var i = 0; i < result.length; i++) {
        if (!fixed[i] && minimum[i] > share) {
          fixed[i] = true;
          result[i] = minimum[i];
          changed = true;
        }
      }
      if (!changed) {
        for (var i = 0; i < result.length; i++) {
          if (!fixed[i]) result[i] = share;
        }
      }
    }
    return result;
  }
}
