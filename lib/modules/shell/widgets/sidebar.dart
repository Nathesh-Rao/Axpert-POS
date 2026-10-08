import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_strings_x.dart';
import '../../../core/responsive/app_metrics_scope.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/theme_x.dart';
import '../../../core/theme/tokens/app_radii.dart';
import '../../../core/theme/tokens/app_spacing.dart';
import '../../../shared/controllers/page_filter_controller.dart';
import '../../../shared/controllers/search_field_controller.dart';
import '../../../shared/widgets/app_pressable.dart';
import '../../../shared/widgets/css_gradient.dart';
import '../models/nav_destination.dart';

/// Left navigation: seven items, "More" pinned to the bottom.
class Sidebar extends StatelessWidget {
  const Sidebar({required this.current, super.key});

  final AppPage current;

  void _go(AppPage page) {
    // Prototype: navigate, clear the shared filter, refocus the search field.
    Get.find<PageFilterController>().clear();
    if (page != current) Get.offAllNamed<void>(page.path);
    Get.find<SearchFieldController>().refocus();
  }

  @override
  Widget build(BuildContext context) {
    final m = context.metrics;
    final items = NavDestination.all;
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (i == items.length - 1) children.add(const Spacer());
      children.add(
        SidebarButton(
          destination: item,
          active: item.page == current,
          onTap: () => _go(item.page),
        ),
      );
      if (i < items.length - 2) children.add(SizedBox(height: m.sidebarGap));
    }
    return SizedBox(
      width: m.sidebarWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s5,
          vertical: AppSpacing.s4,
        ),
        child: Column(children: children),
      ),
    );
  }
}

class SidebarButton extends StatelessWidget {
  const SidebarButton({
    required this.destination,
    required this.active,
    required this.onTap,
    super.key,
  });

  final NavDestination destination;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final m = context.metrics;
    final label = destination.label(context.strings);
    final color = active ? c.blue : c.text;
    final radius = BorderRadius.circular(AppRadii.r8);
    return AppPressable(
      tooltip: label,
      semanticLabel: label,
      borderRadius: AppRadii.r8,
      onTap: onTap,
      builder: (context, hovered) {
        final content = SizedBox(
          width: double.infinity,
          height: m.sidebarButtonHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(destination.icon, size: m.sidebarIconSize, color: color),
              const SizedBox(height: AppSpacing.s6),
              Text(
                label,
                maxLines: 1,
                style: context.text
                    .fluid(m.sidebarLabelFont)
                    .copyWith(color: color),
              ),
            ],
          ),
        );
        if (active) {
          return Stack(
            children: <Widget>[
              CssGradientBox(
                angleDeg: 120,
                colors: <Color>[c.sidebarActiveTop, c.sidebarActiveBottom],
                borderRadius: radius,
                child: content,
              ),
              Positioned(
                left: 0,
                top: AppSpacing.s4,
                bottom: AppSpacing.s4,
                width: AppSpacing.s2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.blue,
                    borderRadius: BorderRadius.circular(AppRadii.r4 / 2),
                  ),
                ),
              ),
            ],
          );
        }
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? c.sidebarHover : null,
            borderRadius: radius,
          ),
          child: content,
        );
      },
    );
  }
}
